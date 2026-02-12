import 'package:dio/dio.dart';
import '../../../../core/api_client.dart';
import '../models/daily_activity_in.dart';
import '../models/daily_activity_out.dart';

class DailyActivityDataSource {
  final ApiClient apiClient;

  DailyActivityDataSource(this.apiClient);

  // GET /api/DailyActivity/restaurant/{restaurantId}
  Future<List<DailyActivityOut>> getByRestaurant(int restaurantId) async {
    try {
      final response = await apiClient.dio.get(
        '/DailyActivity/restaurant/$restaurantId',
      );
      final List<dynamic> data = response.data;
      return data.map((json) => DailyActivityOut.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // POST /api/DailyActivity
  Future<DailyActivityOut> create(DailyActivityIn activity) async {
    try {
      final response = await apiClient.dio.post(
        '/DailyActivity',
        data: activity.toJson(),
      );
      return DailyActivityOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // PUT /api/DailyActivity/{id}
  Future<DailyActivityOut> update(int id, DailyActivityIn activity) async {
    try {
      final response = await apiClient.dio.put(
        '/DailyActivity/$id',
        data: activity.toJson(),
      );
      return DailyActivityOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // DELETE /api/DailyActivity/{id}
  Future<bool> delete(int id) async {
    try {
      await apiClient.dio.delete('/DailyActivity/$id');
      return true;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  void _handleError(DioException e) {
    if (e.response != null) {
      throw Exception(e.response?.data.toString() ?? "Erreur serveur");
    } else {
      throw Exception("Connexion au serveur impossible");
    }
  }
}
