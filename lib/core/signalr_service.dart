import 'dart:async';
import 'dart:convert';
import 'package:signalr_netcore/iretry_policy.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'app_config.dart';
import 'logging/app_logger.dart';
import 'session/session_service.dart';
import 'signalr_group_registry.dart';
import '../features/reservation/data/models/reservation_out.dart';

enum SignalRStatus { disconnected, connecting, reconnecting, connected }

/// Réessaie les coupures réseau tant que la session est active.
class InfiniteRetryPolicy implements IRetryPolicy {
  const InfiniteRetryPolicy({this.shouldRetry});
  final bool Function()? shouldRetry;
  static const List<int> delaysInMilliseconds = [0, 2000, 5000, 10000, 30000];
  @override
  int? nextRetryDelayInMilliseconds(RetryContext retryContext) {
    if (shouldRetry?.call() == false) return null;
    final attempt = retryContext.previousRetryCount;
    return delaysInMilliseconds[attempt < delaysInMilliseconds.length
        ? attempt
        : delaysInMilliseconds.length - 1];
  }
}

typedef SignalRConnectionFactory =
    HubConnection Function(
      HttpConnectionOptions options,
      IRetryPolicy retryPolicy,
    );

class SignalRService {
  SignalRService({
    SessionService? session,
    SignalRConnectionFactory? connectionFactory,
  }) : _session = session ?? SessionService(),
       _connectionFactory = connectionFactory {
    _session.addTeardown(reset);
  }

  static const String restaurantGroupPrefix = 'restaurant_';
  static const String userGroupPrefix = 'user_';
  static const String availabilityGroupPrefix = 'availability_';
  static const List<int> _closeRetryDelaysInSeconds = [2, 5, 10, 30];
  final SessionService _session;
  final SignalRConnectionFactory? _connectionFactory;
  final _groups = SignalRGroupRegistry();
  HubConnection? _hubConnection;
  Future<void>? _initFuture;
  Future<void>? _rejoinFuture;
  Timer? _reconnectTimer;
  bool _intentionalStop = false;
  int _closeRetryCount = 0;

  final _onReservationCreated = StreamController<ReservationOut>.broadcast();
  final _onReservationUpdateStatus =
      StreamController<ReservationOut>.broadcast();
  final _onReservationDeleted = StreamController<int>.broadcast();
  final _onAvailabilityChanged = StreamController<int>.broadcast();
  final _onResynchronized = StreamController<void>.broadcast();
  final _onStatusChanged = StreamController<SignalRStatus>.broadcast();
  Stream<ReservationOut> get onReservationCreated =>
      _onReservationCreated.stream;
  Stream<ReservationOut> get onReservationUpdateStatus =>
      _onReservationUpdateStatus.stream;
  Stream<int> get onReservationDeleted => _onReservationDeleted.stream;
  Stream<int> get onAvailabilityChanged => _onAvailabilityChanged.stream;
  Stream<void> get onResynchronized => _onResynchronized.stream;
  Stream<SignalRStatus> get onStatusChanged => _onStatusChanged.stream;

  SignalRStatus get status => switch (_hubConnection?.state) {
    HubConnectionState.Connected => SignalRStatus.connected,
    HubConnectionState.Connecting => SignalRStatus.connecting,
    HubConnectionState.Reconnecting => SignalRStatus.reconnecting,
    _ => SignalRStatus.disconnected,
  };
  List<String> get activeGroups => _groups.activeGroups;

  Future<void> init() {
    if (_session.isClosed) return Future.value();
    final pending = _initFuture;
    if (pending != null) return pending;
    if (_hubConnection?.state == HubConnectionState.Connected) {
      return Future.value();
    }
    final future = _connect();
    _initFuture = future;
    return future.whenComplete(() {
      if (identical(_initFuture, future)) _initFuture = null;
    });
  }

  Future<void> ensureConnected() async {
    if (_session.isClosed || _intentionalStop) return;
    final connection = _hubConnection;
    if (connection == null && _groups.activeGroups.isEmpty) return;
    switch (connection?.state) {
      case HubConnectionState.Connected:
        await _rejoinAllGroups();
      case HubConnectionState.Connecting:
      case HubConnectionState.Reconnecting:
        break;
      default:
        await init();
    }
  }

  Future<void> joinRestaurantGroup(int id) =>
      _joinGroup('$restaurantGroupPrefix$id');
  Future<void> leaveRestaurantGroup(int id) =>
      _leaveGroup('$restaurantGroupPrefix$id');
  Future<void> joinUserGroup(int id) => _joinGroup('$userGroupPrefix$id');
  Future<void> leaveUserGroup(int id) => _leaveGroup('$userGroupPrefix$id');
  Future<void> joinAvailabilityGroup(int id) =>
      _joinGroup('$availabilityGroupPrefix$id');
  Future<void> leaveAvailabilityGroup(int id) =>
      _leaveGroup('$availabilityGroupPrefix$id');

  Future<void> reset() async {
    _intentionalStop = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _closeRetryCount = 0;
    _groups.clear();
    _initFuture = null;
    _rejoinFuture = null;
    final connection = _hubConnection;
    _hubConnection = null;
    try {
      await connection?.stop();
    } catch (error) {
      AppLogger.error('SignalR: échec de l’arrêt', error);
    }
    _emitStatus(SignalRStatus.disconnected);
  }

  Future<void> dispose() async {
    _session.removeTeardown(reset);
    await reset();
    await _onReservationCreated.close();
    await _onReservationUpdateStatus.close();
    await _onReservationDeleted.close();
    await _onAvailabilityChanged.close();
    await _onResynchronized.close();
    await _onStatusChanged.close();
  }

  Future<void> _connect() async {
    final epoch = _session.generation;
    // Pas de connexion anonyme ni de retries après disparition des jetons.
    if (await _session.accessToken == null ||
        epoch != _session.generation ||
        _session.isClosed) {
      return;
    }
    final connection = _hubConnection ??= _buildConnection();
    if (connection.state != HubConnectionState.Disconnected) return;
    _intentionalStop = false;
    _emitStatus(SignalRStatus.connecting);
    try {
      await connection.start();
      if (!_isCurrent(connection) || epoch != _session.generation) {
        await connection.stop();
        return;
      }
      _closeRetryCount = 0;
      _emitStatus(SignalRStatus.connected);
      await _rejoinAllGroups();
    } catch (error) {
      if (!_isCurrent(connection)) return;
      AppLogger.error('SignalR: échec de connexion', error);
      _emitStatus(SignalRStatus.disconnected);
      _scheduleReconnect();
    }
  }

  bool _isCurrent(HubConnection connection) =>
      identical(connection, _hubConnection) &&
      !_session.isClosed &&
      !_intentionalStop;

  HubConnection _buildConnection() {
    final options = HttpConnectionOptions(
      accessTokenFactory: () async {
        final token = await _session.getValidAccessToken();
        if (token == null || _session.isClosed) {
          throw const SessionChangedException();
        }
        return token;
      },
      skipNegotiation: true,
      transport: HttpTransportType.WebSockets,
    );
    final retry = InfiniteRetryPolicy(
      shouldRetry: () => !_intentionalStop && !_session.isClosed,
    );
    final connection =
        _connectionFactory?.call(options, retry) ??
        HubConnectionBuilder()
            .withUrl('${AppConfig.apiUrl}/reservationHub', options: options)
            .withAutomaticReconnect(reconnectPolicy: retry)
            .build();
    _registerMessageHandlers(connection);
    _registerLifecycleCallbacks(connection);
    return connection;
  }

  void _registerMessageHandlers(HubConnection connection) {
    connection.on('ReceiveReservationCreated', (arguments) {
      if (!_isCurrent(connection)) return;
      final reservation = _parseReservation(arguments);
      if (reservation != null) _emit(_onReservationCreated, reservation);
    });
    connection.on('ReceiveReservationUpdateStatus', (arguments) {
      if (!_isCurrent(connection)) return;
      final reservation = _parseReservation(arguments);
      if (reservation != null) _emit(_onReservationUpdateStatus, reservation);
    });
    connection.on('ReceiveReservationDeleted', (arguments) {
      if (!_isCurrent(connection) || arguments == null || arguments.isEmpty) {
        return;
      }
      final id = int.tryParse('${arguments.first}');
      if (id != null) _emit(_onReservationDeleted, id);
    });
    connection.on('ReceiveAvailabilityChanged', (arguments) {
      if (!_isCurrent(connection) || arguments == null || arguments.isEmpty) {
        return;
      }
      try {
        final raw = arguments.first;
        final data = raw is String ? jsonDecode(raw) : raw;
        if (data is! Map) return;
        final id = int.tryParse('${data['restaurantId']}');
        if (id != null) _emit(_onAvailabilityChanged, id);
      } catch (error) {
        AppLogger.debug('SignalR: disponibilité illisible', error);
      }
    });
  }

  void _registerLifecycleCallbacks(HubConnection connection) {
    connection.onreconnecting(({Exception? error}) {
      if (!_isCurrent(connection)) return;
      _emitStatus(SignalRStatus.reconnecting);
    });
    connection.onreconnected(({String? connectionId}) {
      if (!_isCurrent(connection)) return;
      _closeRetryCount = 0;
      _emitStatus(SignalRStatus.connected);
      unawaited(_rejoinAllGroups());
    });
    connection.onclose(({Exception? error}) {
      if (!_isCurrent(connection)) return;
      _emitStatus(SignalRStatus.disconnected);
      _scheduleReconnect();
    });
  }

  void _scheduleReconnect() {
    if (_intentionalStop || _session.isClosed || _reconnectTimer != null) {
      return;
    }
    final attempt = _closeRetryCount++;
    final index =
        attempt < _closeRetryDelaysInSeconds.length
            ? attempt
            : _closeRetryDelaysInSeconds.length - 1;
    _reconnectTimer = Timer(
      Duration(seconds: _closeRetryDelaysInSeconds[index]),
      () {
        _reconnectTimer = null;
        if (!_intentionalStop && !_session.isClosed) {
          unawaited(ensureConnected());
        }
      },
    );
  }

  Future<void> _joinGroup(String group) async {
    if (_session.isClosed) return;
    final first = _groups.acquire(group);
    final connected = _hubConnection?.state == HubConnectionState.Connected;
    await init();
    // Une première connexion rejoint déjà toutes les adhésions enregistrées.
    if (first && connected && _groups.contains(group)) {
      if (!await _invokeGroupMethod(_joinMethodFor(group), group)) {
        _scheduleReconnect();
      }
    }
  }

  Future<void> _leaveGroup(String group) async {
    if (!_groups.release(group)) return;
    await _invokeGroupMethod(_leaveMethodFor(group), group);
  }

  Future<void> _rejoinAllGroups() {
    final pending = _rejoinFuture;
    if (pending != null) return pending;
    final future = _resynchronize();
    _rejoinFuture = future;
    return future.whenComplete(() {
      if (identical(_rejoinFuture, future)) _rejoinFuture = null;
    });
  }

  Future<void> _resynchronize() async {
    final connection = _hubConnection;
    if (connection == null ||
        !_isCurrent(connection) ||
        connection.state != HubConnectionState.Connected) {
      return;
    }
    var success = true;
    for (final group in _groups.activeGroups) {
      if (!_groups.contains(group)) continue;
      if (!await _invokeGroupMethod(_joinMethodFor(group), group)) {
        success = false;
      }
      // L'écran peut avoir disparu pendant l'appel asynchrone de Join.
      if (!_groups.contains(group)) {
        await _invokeGroupMethod(_leaveMethodFor(group), group);
      }
    }
    if (!_isCurrent(connection) ||
        connection.state != HubConnectionState.Connected) {
      return;
    }
    if (success) {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _emit<void>(_onResynchronized, null);
    } else {
      _scheduleReconnect();
    }
  }

  Future<bool> _invokeGroupMethod(String method, String group) async {
    final connection = _hubConnection;
    if (connection == null ||
        !_isCurrent(connection) ||
        connection.state != HubConnectionState.Connected) {
      return false;
    }
    try {
      await connection.invoke(
        method,
        args: [group.substring(group.indexOf('_') + 1)],
      );
      return _isCurrent(connection);
    } catch (error) {
      AppLogger.error('SignalR: échec d’adhésion au groupe', error);
      return false;
    }
  }

  String _joinMethodFor(String group) =>
      group.startsWith(availabilityGroupPrefix)
          ? 'JoinAvailabilityGroup'
          : group.startsWith(restaurantGroupPrefix)
          ? 'JoinRestaurantGroup'
          : 'JoinUserGroup';
  String _leaveMethodFor(String group) =>
      group.startsWith(availabilityGroupPrefix)
          ? 'LeaveAvailabilityGroup'
          : group.startsWith(restaurantGroupPrefix)
          ? 'LeaveRestaurantGroup'
          : 'LeaveUserGroup';

  ReservationOut? _parseReservation(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return null;
    try {
      final raw = arguments.first;
      final data = raw is String ? jsonDecode(raw) : raw;
      return ReservationOut.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (error) {
      AppLogger.error('SignalR: réservation illisible', error);
      return null;
    }
  }

  void _emit<T>(StreamController<T> controller, T value) {
    if (!controller.isClosed) controller.add(value);
  }

  void _emitStatus(SignalRStatus status) => _emit(_onStatusChanged, status);
}
