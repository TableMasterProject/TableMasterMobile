import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
          onRequest: (options, handler) async {
            const storage = FlutterSecureStorage();
            // On récupère le token sauvegardé par AuthRepositoryImpl
            String? token = await storage.read(key: 'access_token');

            if (token != null) {
              options.headers["Authorization"] = "Bearer $token";
            }
            return handler.next(options);
          },
          onError: (e, handler) {
            if (e.response?.statusCode == 401) {
              // Optionnel : Gérer ici une redirection vers le login
              // ou un refresh token automatique
            }
            return handler.next(e);
          }
      ),
    );
  }

  // Getter pour accéder à l'instance Dio dans les DataSources
  Dio get dio => _dio;
}