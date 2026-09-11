import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signalr_netcore/iretry_policy.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'app_config.dart';
import 'logging/app_logger.dart';
import 'signalr_group_registry.dart';
import '../features/reservation/data/models/reservation_out.dart';

/// État de la connexion temps réel, exposé à l'UI.
enum SignalRStatus { disconnected, connecting, reconnecting, connected }

/// Politique de reconnexion qui n'abandonne jamais.
///
/// La politique par défaut du paquet (`DefaultRetryPolicy`) renvoie `null` après
/// ~42 secondes, ce qui ferme définitivement la connexion pour le reste de la
/// session. Sur mobile (mise en veille, tunnel, bascule Wi-Fi/4G) le cas est
/// courant : il faut continuer à réessayer indéfiniment.
class InfiniteRetryPolicy implements IRetryPolicy {
  const InfiniteRetryPolicy();

  static const List<int> delaysInMilliseconds = [0, 2000, 5000, 10000, 30000];

  @override
  int? nextRetryDelayInMilliseconds(RetryContext retryContext) {
    final attempt = retryContext.previousRetryCount;
    final index =
        attempt < delaysInMilliseconds.length
            ? attempt
            : delaysInMilliseconds.length - 1;
    return delaysInMilliseconds[index];
  }
}

class SignalRService {
  static const String restaurantGroupPrefix = 'restaurant_';
  static const String userGroupPrefix = 'user_';

  /// Paliers du filet de sécurité déclenché par [onclose], quand la reconnexion
  /// automatique du paquet a elle-même rendu la main.
  static const List<int> _closeRetryDelaysInSeconds = [2, 5, 10, 30];

  final _storage = const FlutterSecureStorage();
  final _groups = SignalRGroupRegistry();

  HubConnection? _hubConnection;
  Future<void>? _initFuture;
  Timer? _reconnectTimer;
  bool _intentionalStop = false;
  int _closeRetryCount = 0;

  final _onReservationCreated = StreamController<ReservationOut>.broadcast();
  final _onReservationUpdateStatus =
      StreamController<ReservationOut>.broadcast();
  final _onReservationDeleted = StreamController<int>.broadcast();
  final _onStatusChanged = StreamController<SignalRStatus>.broadcast();

  Stream<ReservationOut> get onReservationCreated =>
      _onReservationCreated.stream;
  Stream<ReservationOut> get onReservationUpdateStatus =>
      _onReservationUpdateStatus.stream;
  Stream<int> get onReservationDeleted => _onReservationDeleted.stream;

  /// Permet à l'UI d'afficher l'état du temps réel (bandeau « Reconnexion… »).
  Stream<SignalRStatus> get onStatusChanged => _onStatusChanged.stream;

  SignalRStatus get status {
    final connection = _hubConnection;
    if (connection == null) return SignalRStatus.disconnected;

    switch (connection.state) {
      case HubConnectionState.Connected:
        return SignalRStatus.connected;
      case HubConnectionState.Connecting:
        return SignalRStatus.connecting;
      case HubConnectionState.Reconnecting:
        return SignalRStatus.reconnecting;
      default:
        return SignalRStatus.disconnected;
    }
  }

  /// Groupes actuellement suivis, exposé pour le diagnostic.
  List<String> get activeGroups => _groups.activeGroups;

  /// Établit la connexion si nécessaire.
  ///
  /// Idempotente et sérialisée : plusieurs écrans peuvent l'appeler en parallèle
  /// sans créer plusieurs `HubConnection` concurrentes. N'échoue jamais : en cas
  /// d'erreur la reconnexion est replanifiée.
  Future<void> init() {
    final pending = _initFuture;
    if (pending != null) return pending;

    final connection = _hubConnection;
    if (connection != null &&
        connection.state == HubConnectionState.Connected) {
      return Future.value();
    }

    final future = _connect();
    _initFuture = future;
    return future.whenComplete(() {
      if (identical(_initFuture, future)) _initFuture = null;
    });
  }

  /// Point d'entrée unique pour rétablir le temps réel : retour d'arrière-plan,
  /// reprise après veille, ou simple contrôle de cohérence.
  ///
  /// Même lorsque la connexion se dit vivante, les groupes sont resynchronisés :
  /// elle a pu être rétablie pendant que l'application dormait, auquel cas le
  /// `ConnectionId` a changé et les adhésions serveur ont été perdues.
  Future<void> ensureConnected() async {
    final connection = _hubConnection;
    if (connection == null) {
      // Rien à rétablir : aucun écran n'a encore demandé le temps réel
      // (utilisateur non connecté, écran de login...).
      if (_groups.activeGroups.isEmpty) return;
      await init();
      return;
    }

    switch (connection.state) {
      case HubConnectionState.Connected:
        await _rejoinAllGroups();
      case HubConnectionState.Connecting:
      case HubConnectionState.Reconnecting:
        break;
      default:
        await init();
    }
  }

  Future<void> joinRestaurantGroup(int restaurantId) =>
      _joinGroup('$restaurantGroupPrefix$restaurantId');

  Future<void> leaveRestaurantGroup(int restaurantId) =>
      _leaveGroup('$restaurantGroupPrefix$restaurantId');

  Future<void> joinUserGroup(int userId) =>
      _joinGroup('$userGroupPrefix$userId');

  Future<void> leaveUserGroup(int userId) =>
      _leaveGroup('$userGroupPrefix$userId');

  /// Coupe le temps réel et oublie les adhésions (déconnexion utilisateur).
  Future<void> reset() async {
    _intentionalStop = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _closeRetryCount = 0;
    _groups.clear();
    _initFuture = null;

    final connection = _hubConnection;
    _hubConnection = null;
    if (connection != null) {
      try {
        await connection.stop();
      } catch (e) {
        AppLogger.error('SignalR: échec de l\'arrêt de la connexion', e);
      }
    }
    _emitStatus(SignalRStatus.disconnected);
  }

  Future<void> dispose() async {
    await reset();
    await _onReservationCreated.close();
    await _onReservationUpdateStatus.close();
    await _onReservationDeleted.close();
    await _onStatusChanged.close();
  }

  // region Connexion

  Future<void> _connect() async {
    final connection = _hubConnection ??= _buildConnection();

    // Une tentative est déjà en cours côté paquet : ne pas la doubler.
    if (connection.state != HubConnectionState.Disconnected) return;

    _intentionalStop = false;
    _emitStatus(SignalRStatus.connecting);

    try {
      await connection.start();
      _closeRetryCount = 0;
      AppLogger.debug('SignalR: connecté à ${AppConfig.apiUrl}');
      _emitStatus(SignalRStatus.connected);
      await _rejoinAllGroups();
    } catch (e) {
      AppLogger.error('SignalR: échec de connexion', e);
      _emitStatus(SignalRStatus.disconnected);
      _scheduleReconnect();
    }
  }

  HubConnection _buildConnection() {
    final hubUrl = '${AppConfig.apiUrl}/reservationHub';

    final httpOptions = HttpConnectionOptions(
      accessTokenFactory: () async {
        final token = await _storage.read(key: 'access_token');
        return token ?? '';
      },
      skipNegotiation: true,
      transport: HttpTransportType.WebSockets,
    );

    final connection =
        HubConnectionBuilder()
            .withUrl(hubUrl, options: httpOptions)
            .withAutomaticReconnect(
              reconnectPolicy: const InfiniteRetryPolicy(),
            )
            .build();

    _registerMessageHandlers(connection);
    _registerLifecycleCallbacks(connection);
    return connection;
  }

  /// Enregistré une seule fois par `HubConnection` : le paquet conserve ses
  /// handlers au travers des reconnexions, il ne faut donc pas les réenregistrer
  /// sous peine de recevoir chaque message en double.
  void _registerMessageHandlers(HubConnection connection) {
    connection.on('ReceiveReservationCreated', (arguments) {
      final reservation = _parseReservation(arguments);
      if (reservation != null) _emit(_onReservationCreated, reservation);
    });

    connection.on('ReceiveReservationUpdateStatus', (arguments) {
      final reservation = _parseReservation(arguments);
      if (reservation != null) _emit(_onReservationUpdateStatus, reservation);
    });

    connection.on('ReceiveReservationDeleted', (arguments) {
      final id = _parseReservationId(arguments);
      if (id != null) _emit(_onReservationDeleted, id);
    });
  }

  void _registerLifecycleCallbacks(HubConnection connection) {
    connection.onreconnecting(({Exception? error}) {
      AppLogger.error('SignalR: connexion perdue, reconnexion en cours', error);
      _emitStatus(SignalRStatus.reconnecting);
    });

    connection.onreconnected(({String? connectionId}) {
      AppLogger.debug('SignalR: reconnecté (ConnectionId: $connectionId)');
      _closeRetryCount = 0;
      _emitStatus(SignalRStatus.connected);
      // Côté serveur les groupes sont indexés par ConnectionId : celui-ci vient
      // de changer, toutes les adhésions précédentes ont été perdues.
      unawaited(_rejoinAllGroups());
    });

    connection.onclose(({Exception? error}) {
      AppLogger.error('SignalR: connexion fermée', error);
      _emitStatus(SignalRStatus.disconnected);
      if (!_intentionalStop) _scheduleReconnect();
    });
  }

  /// Filet de sécurité : si la connexion se ferme malgré la reconnexion
  /// automatique, on relance depuis zéro avec un palier croissant.
  void _scheduleReconnect() {
    if (_intentionalStop || _reconnectTimer != null) return;

    final attempt = _closeRetryCount;
    final index =
        attempt < _closeRetryDelaysInSeconds.length
            ? attempt
            : _closeRetryDelaysInSeconds.length - 1;
    final delay = Duration(seconds: _closeRetryDelaysInSeconds[index]);
    _closeRetryCount++;

    AppLogger.debug(
      'SignalR: nouvelle tentative de connexion dans ${delay.inSeconds}s',
    );
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (_intentionalStop) return;
      unawaited(init());
    });
  }

  // endregion

  // region Groupes

  Future<void> _joinGroup(String group) async {
    // L'adhésion est enregistrée quoi qu'il arrive : si la connexion n'est pas
    // encore prête, _rejoinAllGroups() la rattrapera à la (re)connexion.
    _groups.acquire(group);
    await init();
    await _invokeGroupMethod(_joinMethodFor(group), group);
  }

  Future<void> _leaveGroup(String group) async {
    // Ne quitte le groupe que si plus aucun écran n'en dépend.
    if (!_groups.release(group)) return;
    await _invokeGroupMethod(_leaveMethodFor(group), group);
  }

  Future<void> _rejoinAllGroups() async {
    final groups = _groups.activeGroups;
    if (groups.isEmpty) return;

    AppLogger.debug('SignalR: ré-adhésion à ${groups.length} groupe(s)');
    for (final group in groups) {
      await _invokeGroupMethod(_joinMethodFor(group), group);
    }
  }

  Future<void> _invokeGroupMethod(String method, String group) async {
    final connection = _hubConnection;
    if (connection == null ||
        connection.state != HubConnectionState.Connected) {
      // Rattrapé par _rejoinAllGroups() lors de la prochaine connexion.
      return;
    }

    final id = _idOf(group);
    try {
      await connection.invoke(method, args: [id]);
    } catch (e) {
      AppLogger.error('SignalR: échec de $method($id)', e);
    }
  }

  String _joinMethodFor(String group) =>
      group.startsWith(restaurantGroupPrefix)
          ? 'JoinRestaurantGroup'
          : 'JoinUserGroup';

  String _leaveMethodFor(String group) =>
      group.startsWith(restaurantGroupPrefix)
          ? 'LeaveRestaurantGroup'
          : 'LeaveUserGroup';

  String _idOf(String group) => group.substring(group.indexOf('_') + 1);

  // endregion

  // region Décodage des messages

  ReservationOut? _parseReservation(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return null;
    try {
      // Le serveur envoie une chaîne JSON, pas un objet.
      final data = jsonDecode(arguments[0] as String);
      return ReservationOut.fromJson(data);
    } catch (e) {
      AppLogger.error('SignalR: réservation illisible', e);
      return null;
    }
  }

  int? _parseReservationId(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return null;
    final raw = arguments[0];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    final parsed = int.tryParse('$raw');
    if (parsed == null) {
      AppLogger.error('SignalR: identifiant de réservation illisible: $raw');
    }
    return parsed;
  }

  void _emit<T>(StreamController<T> controller, T value) {
    if (controller.isClosed) return;
    controller.add(value);
  }

  void _emitStatus(SignalRStatus status) => _emit(_onStatusChanged, status);

  // endregion
}
