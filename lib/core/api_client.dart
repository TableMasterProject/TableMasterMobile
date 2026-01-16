import 'package:dio/dio.dart';

import 'app_config.dart';

class ApiClient {
  late Dio _dio;

  // Configuration de base
  static const String baseUrl = AppConfig.apiUrl + "/api";

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        responseType: ResponseType.json,
      ),
    );

    // Ajout d'intercepteurs (Log, Auth, etc.)
    _dio.interceptors.add(LogInterceptor(responseBody: true));
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Exemple : Ajouter un token dynamiquement
          // options.headers["Authorization"] = "Bearer $token";
          return handler.next(options);
        },
      ),
    );
  }

  // Getter pour accéder à l'instance Dio dans les DataSources
  Dio get dio => _dio;
}