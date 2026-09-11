import '../../../../core/errors/app_exception.dart';
import 'package:dio/dio.dart';
import '../../../../core/api_client.dart';
import '../models/review_in.dart';
import '../models/review_out.dart';
import '../models/search_reviews.dart';

class ReviewDataSource {
  final ApiClient apiClient;

  ReviewDataSource(this.apiClient);

  // GET /api/Review/Restaurant/{Id} - récupère les avis d'un restaurant
  Future<List<ReviewOut>> getByRestaurant(
    int restaurantId,
    SearchReviews search,
  ) async {
    try {
      final response = await apiClient.dio.get(
        '/Review/Restaurant/$restaurantId',
        queryParameters: search.toJson(),
      );
      final List<dynamic> data = response.data;
      return data.map((json) => ReviewOut.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // GET /api/Review/My - récupère les avis de l'utilisateur courant
  Future<List<ReviewOut>> getMy(SearchReviews search) async {
    try {
      final response = await apiClient.dio.get(
        '/Review/My',
        queryParameters: search.toJson(),
      );
      final List<dynamic> data = response.data;
      return data.map((json) => ReviewOut.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // POST /api/Review - ajouter un avis
  Future<ReviewOut> create(ReviewIn review) async {
    try {
      final response = await apiClient.dio.post(
        '/Review',
        data: review.toJson(),
      );
      return ReviewOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // PUT /api/Review/{id} - modifier un avis
  Future<ReviewOut> update(int id, ReviewIn review) async {
    try {
      final response = await apiClient.dio.put(
        '/Review/$id',
        data: review.toJson(),
      );
      return ReviewOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // DELETE /api/Review/{id} - supprimer un avis
  Future<bool> delete(int id) async {
    try {
      await apiClient.dio.delete('/Review/$id');
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
