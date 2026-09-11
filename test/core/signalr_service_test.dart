import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:signalr_netcore/iretry_policy.dart';
import 'package:table_master_mobile/core/session/session_service.dart';
import 'package:table_master_mobile/core/signalr_service.dart';
import 'api_client_session_test.dart' show TestAdapter, body, sessionData;
import 'package:dio/dio.dart';

class FakeHub extends Fake implements HubConnection {
  HubConnectionState currentState = HubConnectionState.Disconnected;
  final calls = <String>[];
  final handlers = <String, void Function(List<Object?>?)>{};
  Future<void> Function()? starting;
  Future<void> Function()? joining;
  void Function({String? connectionId})? reconnected;
  void Function({Exception? error})? closed;
  @override
  HubConnectionState get state => currentState;
  @override
  Future<void> start() async {
    await starting?.call();
    currentState = HubConnectionState.Connected;
  }

  @override
  Future<void> stop() async {
    currentState = HubConnectionState.Disconnected;
    calls.add('stop');
  }

  @override
  Future<Object?> invoke(String methodName, {List<Object>? args}) async {
    await joining?.call();
    calls.add('$methodName:${args!.single}');
    return null;
  }

  @override
  void on(String methodName, void Function(List<Object?>?) method) {
    handlers[methodName] = method;
  }

  @override
  void onreconnected(void Function({String? connectionId}) callback) {
    reconnected = callback;
  }

  @override
  void onreconnecting(void Function({Exception? error}) callback) {}
  @override
  void onclose(void Function({Exception? error}) callback) {
    closed = callback;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SessionService session;
  late SignalRService service;
  late FakeHub hub;
  late HttpConnectionOptions options;
  late IRetryPolicy retry;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'token',
      'refresh_token': 'refresh',
    });
    session = SessionService();
    hub = FakeHub();
    service = SignalRService(
      session: session,
      connectionFactory: (o, r) {
        options = o;
        retry = r;
        return hub;
      },
    );
  });
  tearDown(() async {
    await service.dispose();
    await session.dispose();
  });
  test(
    'availability conserve références et réadhère avant resynchronisation',
    () async {
      final events = <List<String>>[];
      service.onResynchronized.listen((_) => events.add(List.of(hub.calls)));
      await service.joinAvailabilityGroup(12);
      await Future<void>.delayed(Duration.zero);
      expect(hub.calls, ['JoinAvailabilityGroup:12']);
      expect(events.single, ['JoinAvailabilityGroup:12']);
      await service.joinAvailabilityGroup(12);
      expect(hub.calls.length, 1);
      await service.leaveAvailabilityGroup(12);
      expect(service.activeGroups, ['availability_12']);
      await service.ensureConnected();
      await Future<void>.delayed(Duration.zero);
      expect(events.length, 2);
      await service.leaveAvailabilityGroup(12);
      expect(hub.calls.last, 'LeaveAvailabilityGroup:12');
    },
  );
  test('reconnexion rejoint les groupes avant événement', () async {
    await service.joinUserGroup(7);
    await service.joinRestaurantGroup(3);
    final next = service.onResynchronized.first;
    hub.reconnected!(connectionId: 'new');
    await next;
    expect(hub.calls.sublist(hub.calls.length - 2), [
      'JoinUserGroup:7',
      'JoinRestaurantGroup:3',
    ]);
  });
  test(
    'ReceiveAvailabilityChanged décode restaurantId sans exposer réservations',
    () async {
      await service.init();
      final next = service.onAvailabilityChanged.first;
      hub.handlers['ReceiveAvailabilityChanged']!([
        {'restaurantId': 12},
      ]);
      expect(await next, 12);
    },
  );
  test('invalidsession coupe hub, groupes et retries', () async {
    await service.joinUserGroup(7);
    await session.clear(invalidated: true);
    expect(hub.calls.last, 'stop');
    expect(service.activeGroups, isEmpty);
    expect(
      retry.nextRetryDelayInMilliseconds(RetryContext(1, 1, Exception())),
      isNull,
    );
    await service.ensureConnected();
    expect(service.status, SignalRStatus.disconnected);
  });
  test('transport reste WebSockets sans négociation', () async {
    await service.init();
    expect(options.skipNegotiation, isTrue);
    expect(options.transport, HttpTransportType.WebSockets);
  });
  test('accessTokenFactory renouvelle avant expiration', () async {
    final expired =
        'e30.${base64Url.encode(utf8.encode(jsonEncode({'exp': 1})))}.signature';
    final transport = Dio(BaseOptions(baseUrl: 'https://test.invalid/api'));
    transport.httpClientAdapter = TestAdapter(
      (_) => body(200, sessionData('renewed')),
    );
    await service.dispose();
    await session.dispose();
    session = SessionService(refreshDio: transport);
    await session.storeSessionData(sessionData(expired));
    service = SignalRService(
      session: session,
      connectionFactory: (o, r) {
        options = o;
        return hub;
      },
    );
    await service.init();
    expect(await options.accessTokenFactory!(), 'renewed');
  });
}
