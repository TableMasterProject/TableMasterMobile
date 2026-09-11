import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:table_master_mobile/core/api_client.dart';
import 'package:table_master_mobile/core/session/session_service.dart';

class TestAdapter implements HttpClientAdapter {
  TestAdapter(this.respond);
  final FutureOr<ResponseBody> Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody body(int code, [Object data = const {}]) =>
    ResponseBody.fromString(
      jsonEncode(data),
      code,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
Map<String, dynamic> sessionData([
  String access = 'new',
  String refresh = 'refresh-new',
]) => {
  'accessToken': access,
  'refreshToken': refresh,
  'user': {
    'id': 7,
    'email': 'test@example.invalid',
    'firstName': 'Test',
    'lastName': 'Test',
    'accountType': 0,
    'createdAt': '2026-01-01T00:00:00Z',
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SessionService session;
  late Dio transport;
  late Dio apiDio;
  late ApiClient api;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'old',
      'refresh_token': 'refresh-old',
      'user_id': '7',
    });
    transport = Dio(BaseOptions(baseUrl: 'https://test.invalid/api'));
    session = SessionService(
      refreshDio: transport,
      refreshTimeout: const Duration(milliseconds: 40),
    );
    apiDio = Dio(BaseOptions(baseUrl: 'https://test.invalid/api'));
    api = ApiClient(session: session, dio: apiDio);
  });
  tearDown(() async {
    await session.dispose();
  });

  test(
    'deux 401 simultanés partagent un renouvellement et rejouent une fois',
    () async {
      var refreshes = 0;
      final gate = Completer<void>();
      transport.httpClientAdapter = TestAdapter((options) async {
        refreshes++;
        await gate.future;
        return body(200, sessionData());
      });
      final requests = <RequestOptions>[];
      apiDio.httpClientAdapter = TestAdapter((options) {
        requests.add(options);
        return body(
          options.headers['Authorization'] == 'Bearer new' ? 200 : 401,
        );
      });
      final first = api.dio.get('/private');
      final second = api.dio.get('/private2');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      gate.complete();
      await Future.wait([first, second]);
      expect(refreshes, 1);
      expect(requests.length, 4);
    },
  );
  test(
    'un ancien 401 utilise le jeton déjà renouvelé sans second refresh',
    () async {
      var refreshes = 0;
      transport.httpClientAdapter = TestAdapter((options) {
        refreshes++;
        return body(200, sessionData());
      });
      final delayed = Completer<void>();
      apiDio.httpClientAdapter = TestAdapter((options) async {
        if (options.headers['Authorization'] == 'Bearer new') return body(200);
        if (options.path == '/late') await delayed.future;
        return body(401);
      });
      final late = api.dio.get('/late');
      await api.dio.get('/first');
      delayed.complete();
      await late;
      expect(refreshes, 1);
    },
  );
  test(
    'le rejeu conserve les options Dio et ne se renouvelle pas une deuxième fois',
    () async {
      var refreshes = 0;
      var requests = 0;
      transport.httpClientAdapter = TestAdapter((options) {
        refreshes++;
        return body(200, sessionData());
      });
      final cancellation = CancelToken();
      apiDio.httpClientAdapter = TestAdapter((options) {
        requests++;
        expect(options.cancelToken, same(cancellation));
        expect(options.receiveTimeout, const Duration(seconds: 7));
        expect(options.extra['custom'], 'kept');
        expect(options.queryParameters, {'page': 3});
        expect(options.data, {'value': 'same'});
        return body(401);
      });
      await expectLater(
        api.dio.post(
          '/private',
          data: {'value': 'same'},
          queryParameters: {'page': 3},
          cancelToken: cancellation,
          options: Options(
            receiveTimeout: const Duration(seconds: 7),
            extra: {'custom': 'kept'},
          ),
        ),
        throwsA(isA<DioException>()),
      );
      expect(refreshes, 1);
      expect(requests, 2);
    },
  );
  test(
    'Auth et inscription ne portent pas de token et ne rafraîchissent pas',
    () async {
      var refreshes = 0;
      transport.httpClientAdapter = TestAdapter((options) {
        refreshes++;
        return body(200, sessionData());
      });
      apiDio.httpClientAdapter = TestAdapter((options) {
        expect(options.headers['Authorization'], isNull);
        return body(401);
      });
      for (final path in [
        '/Auth',
        '/Auth/refresh',
        '/Auth/forgot-password',
        '/Auth/reset-password',
        '/User',
      ]) {
        await expectLater(api.dio.post(path), throwsA(isA<DioException>()));
      }
      expect(refreshes, 0);
      expect(await session.accessToken, 'old');
    },
  );
  for (final status in [403, 503]) {
    test('$status métier ne renouvelle ni efface la session', () async {
      apiDio.httpClientAdapter = TestAdapter((options) => body(status));
      await expectLater(api.dio.get('/private'), throwsA(isA<DioException>()));
      expect(await session.accessToken, 'old');
    });
  }
  for (final status in [429, 503]) {
    test('$status refresh préserve la session', () async {
      apiDio.httpClientAdapter = TestAdapter((options) => body(401));
      transport.httpClientAdapter = TestAdapter((options) => body(status));
      await expectLater(api.dio.get('/private'), throwsA(isA<DioException>()));
      expect(await session.accessToken, 'old');
    });
  }
  test('timeout refresh préserve la session', () async {
    apiDio.httpClientAdapter = TestAdapter((options) => body(401));
    final delayed = Completer<ResponseBody>();
    transport.httpClientAdapter = TestAdapter((options) => delayed.future);
    await expectLater(api.dio.get('/private'), throwsA(isA<DioException>()));
    expect(await session.accessToken, 'old');
    delayed.complete(body(200, sessionData()));
  });
  test('401 refresh nettoie une seule fois et attend le teardown', () async {
    var invalidations = 0;
    var stopped = false;
    session.onInvalidated.listen((_) {
      expect(stopped, isTrue);
      invalidations++;
    });
    session.addTeardown(() async {
      stopped = true;
    });
    apiDio.httpClientAdapter = TestAdapter((options) => body(401));
    transport.httpClientAdapter = TestAdapter((options) => body(401));
    await Future.wait(
      List.generate(
        2,
        (_) => api.dio
            .get('/private')
            .catchError(
              (Object e) => Response(requestOptions: RequestOptions()),
            ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(await session.accessToken, isNull);
    expect(invalidations, 1);
  });
  for (final loginAgain in [false, true]) {
    test(
      'refresh tardif ignoré après logout${loginAgain ? '/login' : ''}',
      () async {
        final delayed = Completer<ResponseBody>();
        final started = Completer<void>();
        transport.httpClientAdapter = TestAdapter((options) {
          started.complete();
          return delayed.future;
        });
        final refresh = session.refresh();
        final failed = expectLater(
          refresh,
          throwsA(isA<SessionChangedException>()),
        );
        await started.future;
        await session.clear();
        if (loginAgain) {
          await session.storeSessionData(sessionData('other', 'other-refresh'));
        }
        delayed.complete(body(200, sessionData()));
        await failed;
        expect(await session.accessToken, loginAgain ? 'other' : isNull);
      },
    );
  }
}
