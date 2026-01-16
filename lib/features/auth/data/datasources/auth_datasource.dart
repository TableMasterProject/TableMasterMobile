import 'package:dio/dio.dart';
import '../../../../core/api_client.dart';
import '../models/login_token_in.dart';
import '../models/login_user_in.dart';
import '../models/login_user_out.dart';

class AuthDataSource {
  final ApiClient apiClient;

  AuthDataSource(this.apiClient);

  Future<LoginUserOut> login(LoginUserIn credentials) async {
    try {
      final response = await apiClient.dio.post(
        '/Auth',
        data: credentials.toJson(),
      );

      // On transforme le Map reçu en objet LoginUserOut
      return LoginUserOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<LoginUserOut> refresh(LoginTokenIn tokenModel) async {
    try {
      final response = await apiClient.dio.post(
        '/Auth/refresh',
        data: tokenModel.toJson(),
      );

      return LoginUserOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Gestion des erreurs
  void _handleError(DioException e) {
    if (e.response != null) {
      // Si ton API renvoie une chaîne brute (ex: "Email non existant")
      final dynamic errorData = e.response?.data;
      throw Exception(errorData.toString());
    } else {
      throw Exception("Impossible de contacter le serveur");
    }
  }
}