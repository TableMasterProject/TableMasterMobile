import 'package:dio/dio.dart';
import '../../../../core/api_client.dart';
import '../../../auth/data/models/login_user_out.dart';
import '../models/user_in.dart';
import '../models/user_out.dart';

class UserDataSource {
  final ApiClient apiClient;

  UserDataSource(this.apiClient);

  // GET /api/User/{id}
  Future<UserOut> getUserById(int id) async {
    try {
      final response = await apiClient.dio.get('/User/$id');
      return UserOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // POST /api/User (Inscription)
  Future<LoginUserOut> addUser(UserIn user) async {
    try {
      final response = await apiClient.dio.post('/User', data: user.toJson());
      return LoginUserOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // PUT /api/User (Mise à jour profil)
  Future<UserOut> updateUser(UserIn user) async {
    try {
      final response = await apiClient.dio.put('/User', data: user.toJson());
      return UserOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // PUT /api/User/Password
  Future<bool> updatePassword(String oldPassword, String newPassword) async {
    try {
      final response = await apiClient.dio.put(
        '/User/Password',
        data: {'OldPassword': oldPassword, 'NewPassword': newPassword},
      );
      return response.data as bool;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // DELETE /api/User
  Future<bool> deleteUser() async {
    try {
      final response = await apiClient.dio.delete('/User');
      return response.data as bool;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  void _handleError(DioException e) {
    if (e.response != null) {
      final dynamic errorData = e.response?.data;
      // Gestion spécifique pour le code 403 (Email existe déjà dans ton API)
      if (e.response?.statusCode == 403) {
        throw Exception(errorData.toString());
      }
      throw Exception(errorData.toString());
    } else {
      throw Exception("Erreur de connexion au serveur");
    }
  }
}
