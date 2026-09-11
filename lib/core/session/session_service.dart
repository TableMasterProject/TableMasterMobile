import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/models/login_user_out.dart';
import '../app_config.dart';

class SessionChangedException implements Exception {
  const SessionChangedException();
  @override
  String toString() => 'La session a changé. Veuillez réessayer.';
}

class SessionSnapshot {
  const SessionSnapshot({
    this.accessToken,
    this.refreshToken,
    this.deviceToken,
  });
  final String? accessToken;
  final String? refreshToken;
  final String? deviceToken;
}

/// Propriétaire unique des jetons. Le client de renouvellement n'a aucun
/// intercepteur d'authentification et ne dépend ni des repositories ni de SignalR.
class SessionService {
  SessionService({
    FlutterSecureStorage? storage,
    Dio? refreshDio,
    DateTime Function()? clock,
    this.refreshTimeout = const Duration(seconds: 10),
  }) : storage = storage ?? const FlutterSecureStorage(),
       _refreshDio =
           refreshDio ??
           Dio(
             BaseOptions(
               baseUrl: '${AppConfig.apiUrl}/api',
               headers: {'x-api-version': '1.0'},
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 10),
               sendTimeout: const Duration(seconds: 10),
             ),
           ),
       _clock = clock ?? DateTime.now;

  final FlutterSecureStorage storage;
  final Dio _refreshDio;
  final DateTime Function() _clock;
  final Duration refreshTimeout;
  final _invalidated = StreamController<void>.broadcast();
  final List<Future<void> Function()> _teardowns = [];
  Future<void> _storageQueue = Future.value();
  Future<LoginUserOut>? _refreshFuture;
  int _refreshGeneration = -1;
  int _generation = 0;
  bool _closed = false;
  bool _invalidationSent = false;

  int get generation => _generation;
  bool get isClosed => _closed;
  Stream<void> get onInvalidated => _invalidated.stream;

  // Serialise également les lectures : personne ne voit une paire partiellement
  // remplacée ou ne réécrit des jetons entre deux suppressions.
  Future<T> _locked<T>(Future<T> Function() operation) {
    final result = _storageQueue.then((_) => operation());
    _storageQueue = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  Future<String?> get accessToken =>
      _locked(() async => _closed ? null : storage.read(key: 'access_token'));

  void addTeardown(Future<void> Function() teardown) =>
      _teardowns.add(teardown);
  void removeTeardown(Future<void> Function() teardown) =>
      _teardowns.remove(teardown);

  Future<void> storeSession(LoginUserOut session) {
    final epoch = ++_generation;
    _closed = false;
    _invalidationSent = false;
    return _locked(() async {
      if (epoch != _generation) return;
      await _write(session);
    });
  }

  Future<void> storeSessionData(Map<String, dynamic> data) =>
      storeSession(LoginUserOut.fromJson(data));

  Future<void> storeDeviceToken(
    String token, {
    required int expectedGeneration,
  }) => _locked(() async {
    if (expectedGeneration != _generation || _closed) return;
    await storage.write(key: 'fcm_token', value: token);
  });

  Future<void> _write(LoginUserOut session) async {
    if (session.accessToken.isEmpty || session.refreshToken.isEmpty) {
      throw const FormatException('Réponse de session invalide');
    }
    await storage.write(key: 'access_token', value: session.accessToken);
    await storage.write(key: 'refresh_token', value: session.refreshToken);
    await storage.write(key: 'user_id', value: session.user.id.toString());
  }

  /// Invalide immédiatement les opérations en vol, puis termine le nettoyage.
  /// L'instantané sert seulement à révoquer les anciens jetons sans refresh.
  Future<SessionSnapshot> clear({bool invalidated = false}) {
    final epoch = ++_generation;
    _closed = true;
    final notify = invalidated && !_invalidationSent;
    if (notify) _invalidationSent = true;
    final cleanup = _locked(() async {
      final snapshot = SessionSnapshot(
        accessToken: await storage.read(key: 'access_token'),
        refreshToken: await storage.read(key: 'refresh_token'),
        deviceToken: await storage.read(key: 'fcm_token'),
      );
      for (final key in [
        'access_token',
        'refresh_token',
        'user_id',
        'fcm_token',
      ]) {
        await storage.delete(key: key);
      }
      return snapshot;
    });
    // Le stop commence immédiatement, sans attendre les accès au stockage.
    final stopped = Future.wait(_teardowns.map((stop) => stop()));
    return () async {
      final snapshot = await cleanup;
      await stopped;
      if (notify && epoch == _generation && !_invalidated.isClosed) {
        _invalidated.add(null);
      }
      return snapshot;
    }();
  }

  Future<String?> getValidAccessToken() async {
    final epoch = _generation;
    final token = await accessToken;
    if (epoch != _generation) throw const SessionChangedException();
    if (token == null) return null;
    if (!_expiresSoon(token)) return token;
    return (await refresh(expectedGeneration: epoch)).accessToken;
  }

  bool _expiresSoon(String token) {
    try {
      final segments = token.split('.');
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(segments[1]))),
      );
      final expiry = payload['exp'];
      if (expiry is! num) return true;
      return expiry <=
          _clock()
                  .toUtc()
                  .add(const Duration(seconds: 30))
                  .millisecondsSinceEpoch /
              1000;
    } catch (_) {
      return true;
    }
  }

  Future<String?> recoverAccessToken(String? failedToken, int epoch) async {
    if (epoch != _generation || _closed) throw const SessionChangedException();
    final current = await accessToken;
    if (epoch != _generation || _closed) throw const SessionChangedException();
    if (current != null && current != failedToken) return current;
    return (await refresh(expectedGeneration: epoch)).accessToken;
  }

  Future<LoginUserOut> refresh({int? expectedGeneration}) {
    final epoch = expectedGeneration ?? _generation;
    if (epoch != _generation || _closed) {
      return Future.error(const SessionChangedException());
    }
    final pending = _refreshFuture;
    if (pending != null && _refreshGeneration == epoch) return pending;
    final future = _refresh(epoch);
    _refreshGeneration = epoch;
    _refreshFuture = future;
    // Stocker le Future avec son gestionnaire évite une erreur non écoutée.
    final tracked = future.whenComplete(() {
      if (_refreshGeneration == epoch) _refreshFuture = null;
    });
    _refreshFuture = tracked;
    return tracked;
  }

  Future<LoginUserOut> _refresh(int epoch) async {
    final tokens = await _locked(
      () async => (
        await storage.read(key: 'access_token'),
        await storage.read(key: 'refresh_token'),
      ),
    );
    if (epoch != _generation || _closed) throw const SessionChangedException();
    if (tokens.$1 == null || tokens.$2 == null) {
      await clear(invalidated: true);
      throw const SessionChangedException();
    }
    final cancellation = CancelToken();
    try {
      final response = await _refreshDio
          .post<Map<String, dynamic>>(
            '/Auth/refresh',
            data: {'accessToken': tokens.$1, 'refreshToken': tokens.$2},
            cancelToken: cancellation,
          )
          .timeout(
            refreshTimeout,
            onTimeout: () {
              cancellation.cancel('Délai de renouvellement dépassé');
              throw TimeoutException('Délai de renouvellement dépassé');
            },
          );
      if (epoch != _generation || _closed) {
        throw const SessionChangedException();
      }
      final session = LoginUserOut.fromJson(response.data!);
      await _locked(() async {
        if (epoch != _generation || _closed) {
          throw const SessionChangedException();
        }
        await _write(session);
      });
      if (epoch != _generation || _closed) {
        throw const SessionChangedException();
      }
      return session;
    } on DioException catch (error) {
      if (epoch != _generation || _closed) {
        throw const SessionChangedException();
      }
      if (error.response?.statusCode == 401) await clear(invalidated: true);
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _invalidated.close();
    _refreshDio.close();
  }
}
