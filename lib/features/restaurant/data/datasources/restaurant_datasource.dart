import 'package:dio/dio.dart';
import '../../../../core/api_client.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/restaurant_in.dart';
import '../models/restaurant_out.dart';
import '../models/search_restaurant.dart';

class RestaurantDataSource {
  final ApiClient apiClient;

  RestaurantDataSource(this.apiClient);

  // GET /api/Restaurant (avec filtres optionnels)
  Future<List<RestaurantOut>> getRestaurants(SearchRestaurant search) async {
    try {
      final response = await apiClient.dio.get(
        '/Restaurant',
        // On convertit l'objet en Map pour les query params (?Latitude=...&PageSize=...)
        queryParameters: search.toJson(),
      );

      final List<dynamic> data = response.data;
      return data.map((json) => RestaurantOut.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // GET /api/Restaurant/{id}
  Future<RestaurantOut> getRestaurantById(int id) async {
    try {
      final response = await apiClient.dio.get('/Restaurant/$id');
      return RestaurantOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // POST /api/Restaurant
  Future<RestaurantOut> postRestaurant(RestaurantIn restaurant) async {
    try {
      final response = await apiClient.dio.post(
        '/Restaurant',
        data: restaurant.toJson(),
      );
      return RestaurantOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // PUT /api/Restaurant/{id}
  Future<RestaurantOut> updateRestaurant(
    int id,
    RestaurantIn restaurant,
  ) async {
    try {
      final response = await apiClient.dio.put(
        '/Restaurant/$id',
        data: restaurant.toJson(),
      );
      return RestaurantOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // DELETE /api/Restaurant/{id}
  Future<bool> deleteRestaurant(int id) async {
    try {
      final response = await apiClient.dio.delete('/Restaurant/$id');
      return response.data as bool;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  void _handleError(DioException e) {
    throw AppException.fromDio(e);
  }
}
