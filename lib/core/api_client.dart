import 'dart:async';
import 'package:dio/dio.dart';

import 'app_config.dart';
import 'session/session_service.dart';

class ApiClient {
  static const String baseUrl = '${AppConfig.apiUrl}/api';
  static const String apiVersion = '1.0';
  static const String skipSession = 'skipSession';
  static const String _replayed = 'sessionReplayed';
  static const String _generation = 'sessionGeneration';

  ApiClient({SessionService? session, Dio? dio})
    : session = session ?? SessionService(),
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              sendTimeout: const Duration(seconds: 10),
              responseType: ResponseType.json,
              headers: {'x-api-version': apiVersion},
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            options.headers['x-api-version'] = apiVersion;
            if (options.extra[skipSession] == true) {
              return handler.next(options);
            }
            if (_public(options)) {
              options.headers.remove('Authorization');
              return handler.next(options);
            }
            final epoch =
                options.extra[_generation] as int? ?? this.session.generation;
            final token = await this.session.accessToken;
            if (epoch != this.session.generation) {
              throw const SessionChangedException();
            }
            options.extra[_generation] = epoch;
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            } else {
              options.headers.remove('Authorization');
            }
            handler.next(options);
          } catch (error) {
            handler.reject(DioException(requestOptions: options, error: error));
          }
        },
        onError: (error, handler) async {
          final options = error.requestOptions;
          if (error.response?.statusCode != 401 ||
              _public(options) ||
              options.extra[skipSession] == true ||
              options.extra[_replayed] == true ||
              _path(options) == '/auth/logout') {
            return handler.next(error);
          }
          final epoch = options.extra[_generation] as int?;
          if (epoch == null ||
              epoch != this.session.generation ||
              this.session.isClosed) {
            return handler.next(error);
          }
          try {
            final authorization = options.headers['Authorization'] as String?;
            final failedToken = authorization?.replaceFirst('Bearer ', '');
            final token = await this.session.recoverAccessToken(
              failedToken,
              epoch,
            );
            if (token == null || epoch != this.session.generation) {
              return handler.next(error);
            }
            options.extra[_replayed] = true;
            options.headers['Authorization'] = 'Bearer $token';
            // fetch conserve délais, callbacks, annulation, encodages et extras.
            // Un FormData finalisé doit être cloné pour une seconde émission.
            if (options.data is FormData) {
              options.data = (options.data as FormData).clone();
            }
            if (options.data is Stream) return handler.next(error);
            final response = await _dio.fetch<dynamic>(options);
            handler.resolve(response);
          } on DioException catch (replayError) {
            handler.next(replayError);
          } catch (_) {
            handler.next(error);
          }
        },
      ),
    );
  }

  final SessionService session;
  final Dio _dio;
  Dio get dio => _dio;

  static String _path(RequestOptions options) {
    final path = options.uri.path.toLowerCase().replaceFirst(
      RegExp(r'^/api(?=/|$)'),
      '',
    );
    return path.replaceFirst(RegExp(r'/$'), '');
  }

  static bool _public(RequestOptions options) {
    final path = _path(options);
    return (path == '/auth' ||
            path == '/auth/refresh' ||
            path == '/auth/forgot-password' ||
            path == '/auth/reset-password') ||
        (path == '/user' && options.method.toUpperCase() == 'POST');
  }
}
