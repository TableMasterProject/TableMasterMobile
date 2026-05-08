import 'package:dio/dio.dart';
import '../../../../core/api_client.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/table_entity_in.dart';
import '../models/table_entity_out.dart';

class TableDataSource {
  final ApiClient apiClient;

  TableDataSource(this.apiClient);

  // GET: api/Table/Restaurant/{restaurantId}
  Future<List<TableEntityOut>> getTablesByRestaurant(int restaurantId) async {
    try {
      final response = await apiClient.dio.get('/Table/Restaurant/$restaurantId');
      final List<dynamic> data = response.data;
      return data.map((json) => TableEntityOut.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // POST: api/Table/Restaurant/{restaurantId}
  Future<TableEntityOut> createTable(int restaurantId, TableEntityIn table) async {
    try {
      final response = await apiClient.dio.post(
        '/Table/Restaurant/$restaurantId',
        data: table.toJson(),
      );
      return TableEntityOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // PUT: api/Table/{id}
  Future<TableEntityOut> updateTable(int id, TableEntityIn table) async {
    try {
      final response = await apiClient.dio.put(
        '/Table/$id',
        data: table.toJson(),
      );
      return TableEntityOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // DELETE: api/Table/{id}
  Future<bool> deleteTable(int id) async {
    try {
      final response = await apiClient.dio.delete('/Table/$id');
      return response.data as bool;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<List<TableEntityOut>> replaceTables(int restaurantId, List<TableEntityIn> tables) async {
    try {
      final response = await apiClient.dio.post(
        '/Table/Restaurant/$restaurantId/Bulk',
        data: tables.map((e) => e.toJson()).toList(),
      );
      final List<dynamic> data = response.data;
      return data.map((json) => TableEntityOut.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }

  }

  void _handleError(DioException e) {
    throw AppException.fromDio(e);
  }
}
