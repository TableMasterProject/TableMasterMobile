import 'package:dio/dio.dart';

import '../../../../core/api_client.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/restaurant_room_in.dart';
import '../models/restaurant_room_layout.dart';
import '../models/restaurant_room_out.dart';

class RoomDataSource {
  final ApiClient apiClient;

  RoomDataSource(this.apiClient);

  Future<List<RestaurantRoomOut>> getRoomsByRestaurant(int restaurantId) async {
    try {
      final response = await apiClient.dio.get('/Room/Restaurant/$restaurantId');
      final List<dynamic> data = response.data;
      return data.map((json) => RestaurantRoomOut.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<RestaurantRoomOut> createRoom(int restaurantId, RestaurantRoomIn room) async {
    try {
      final response = await apiClient.dio.post(
        '/Room/Restaurant/$restaurantId',
        data: room.toJson(),
      );
      return RestaurantRoomOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<RestaurantRoomOut> updateRoom(int roomId, RestaurantRoomIn room) async {
    try {
      final response = await apiClient.dio.put('/Room/$roomId', data: room.toJson());
      return RestaurantRoomOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<bool> deleteRoom(int roomId) async {
    try {
      final response = await apiClient.dio.delete('/Room/$roomId');
      return response.data as bool;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<RestaurantRoomLayoutOut> saveLayout(
    int roomId,
    RestaurantRoomLayoutIn layout,
  ) async {
    try {
      final response = await apiClient.dio.put(
        '/Room/$roomId/Layout',
        data: layout.toJson(),
      );
      return RestaurantRoomLayoutOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  void _handleError(DioException e) {
    throw AppException.fromDio(e);
  }
}
