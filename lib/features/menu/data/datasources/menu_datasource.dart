import 'package:dio/dio.dart';
import '../../../../core/api_client.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/menu_in.dart';
import '../models/menu_out.dart';

class MenuDataSource {
  final ApiClient apiClient;

  MenuDataSource(this.apiClient);

  // GET /api/Menu/restaurant/{restaurantId}
  Future<List<MenuOut>> getByRestaurant(int restaurantId) async {
    try {
      final response = await apiClient.dio.get(
        '/Menu/restaurant/$restaurantId',
      );
      final List<dynamic> data = response.data;
      return data.map((json) => MenuOut.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // POST /api/Menu
  Future<MenuOut> create(MenuIn menu) async {
    try {
      final response = await apiClient.dio.post('/Menu', data: menu.toJson());
      return MenuOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // DELETE /api/Menu/{id}
  Future<bool> delete(int id) async {
    try {
      await apiClient.dio.delete('/Menu/$id');
      return true;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  void _handleError(DioException e) {
    throw AppException.fromDio(e);
  }
}
