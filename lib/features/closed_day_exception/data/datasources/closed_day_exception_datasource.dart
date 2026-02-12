import 'package:dio/dio.dart';
import '../../../../core/api_client.dart';
import '../models/closed_day_exception_in.dart';
import '../models/closed_day_exception_out.dart';

class ClosedDayExceptionDataSource {
  final ApiClient apiClient;

  ClosedDayExceptionDataSource(this.apiClient);

  // GET /api/ClosedDayException/restaurant/{restaurantId}
  Future<List<ClosedDayExceptionOut>> getByRestaurant(int restaurantId) async {
    try {
      final response = await apiClient.dio.get(
        '/ClosedDayException/restaurant/$restaurantId',
      );
      final List<dynamic> data = response.data;
      return data.map((json) => ClosedDayExceptionOut.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // POST /api/ClosedDayException
  Future<ClosedDayExceptionOut> create(ClosedDayExceptionIn exception) async {
    try {
      final response = await apiClient.dio.post(
        '/ClosedDayException',
        data: exception.toJson(),
      );
      return ClosedDayExceptionOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // PUT /api/ClosedDayException/{id}
  Future<ClosedDayExceptionOut> update(
    int id,
    ClosedDayExceptionIn exception,
  ) async {
    try {
      final response = await apiClient.dio.put(
        '/ClosedDayException/$id',
        data: exception.toJson(),
      );
      return ClosedDayExceptionOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // DELETE /api/ClosedDayException/{id}
  Future<bool> delete(int id) async {
    try {
      await apiClient.dio.delete('/ClosedDayException/$id');
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
