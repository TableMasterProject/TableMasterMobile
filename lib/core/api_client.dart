import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_config.dart';
import 'logging/app_logger.dart';
import 'session/session_manager.dart';

class ApiClient {
  late Dio _dio;

  // Configuration de base
  static const String baseUrl = AppConfig.apiUrl + "/api";
  static const String apiVersion = "1.0";

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        responseType: ResponseType.json,

        headers: {
          'x-api-version': apiVersion,
        },
      ),
    );

    // Ajout d'intercepteurs (Log, Auth, etc.)
    _dio.interceptors.add(LogInterceptor(responseBody: true));
    _dio.interceptors.add(
      InterceptorsWrapper(
          onRequest: (options, handler) async {
            const storage = FlutterSecureStorage();
            // On récupère le token sauvegardé par AuthRepositoryImpl
            String? token = await storage.read(key: 'access_token');

            if (token != null) {
              options.headers["Authorization"] = "Bearer $token";
            }
            return handler.next(options);
          },
          onError: (e, handler) async {
            if (e.response?.statusCode == 401) {
              const storage = FlutterSecureStorage();
              String? refreshToken = await storage.read(key: 'refresh_token');
              String? accessToken = await storage.read(key: 'access_token');

              if (refreshToken != null && accessToken != null) {
                try {
                  // 1. On tente le refresh via une instance Dio propre (pour éviter les boucles)
                  final refreshDio = Dio(BaseOptions(
                    baseUrl: baseUrl,
                    headers: {'x-api-version': apiVersion},
                  ));
                  final response = await refreshDio.post(
                    '/Auth/refresh',
                    data: {
                      'accessToken': accessToken,
                      'refreshToken': refreshToken,
                    },
                  );

                  // 2. On sauvegarde les nouveaux tokens
                  final newAccessToken = response.data['accessToken'];
                  final newRefreshToken = response.data['refreshToken'];

                  await storage.write(key: 'access_token', value: newAccessToken);
                  await storage.write(key: 'refresh_token', value: newRefreshToken);

                  // 3. On rejoue la requête initiale avec le nouveau token
                  e.requestOptions.headers["Authorization"] = "Bearer $newAccessToken";

                  // On crée une nouvelle requête avec les mêmes options
                  final opts = Options(
                    method: e.requestOptions.method,
                    headers: e.requestOptions.headers,
                  );

                  final clonedRequest = await _dio.request(
                    e.requestOptions.path,
                    options: opts,
                    data: e.requestOptions.data,
                    queryParameters: e.requestOptions.queryParameters,
                  );

                  return handler.resolve(clonedRequest);
                } catch (refreshError) {
                  // Si le refresh échoue (ex: refresh token expiré), on déconnecte
                  //await storage.deleteAll();
                  AppLogger.debug("Échec du refresh token", refreshError);
                  SessionManager.redirectToLogin();
                }
              } else {
                // Pas de tokens dispo, redirection directe
                //await storage.deleteAll();
                SessionManager.redirectToLogin();
              }
            }
            return handler.next(e);
          }
      ),
    );
  }

  // Getter pour accéder à l'instance Dio dans les DataSources
  Dio get dio => _dio;

}
