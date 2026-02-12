import 'package:dio/dio.dart';
import '../../../../core/api_client.dart';
import '../models/reservation_out.dart';

class ReservationDataSource {
  final ApiClient apiClient;

  ReservationDataSource(this.apiClient);

  // GET /api/Reservation/Restaurant/{Id}?reservationDate=YYYY-MM-DD
  Future<List<ReservationOut>> getReservationsByRestaurant(
    int id,
    String reservationDate,
    int? tableId
  ) async {
    try {
      final response = await apiClient.dio.get(
        '/Reservation/Restaurant/$id',
        queryParameters: {'reservationDate': reservationDate, 'tableId': tableId},
      );
      final List<dynamic> data = response.data;
      return data.map((json) => ReservationOut.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  Future<List<ReservationOut>> getPendingReservationsByRestaurant(
      int id,
      int? tableId
      ) async {
    try {
      final response = await apiClient.dio.get(
        '/Reservation/Restaurant/$id/Pending',
        queryParameters: {'tableId': tableId},
      );
      final List<dynamic> data = response.data;
      return data.map((json) => ReservationOut.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // POST /api/Reservation
  Future<ReservationOut> createReservation(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.dio.post('/Reservation', data: data);
      return ReservationOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // GET /api/Reservation/{id}/Validate?IsValidate=true
  Future<ReservationOut> validateReservation(int id, bool isValidate) async {
    try {
      final response = await apiClient.dio.get(
        '/Reservation/$id/Validate',
        queryParameters: {'IsValidate': isValidate},
      );
      return ReservationOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // DELETE /api/Reservation/{id}
  Future<bool> deleteReservation(int id) async {
    try {
      final response = await apiClient.dio.delete('/Reservation/$id');
      return response.data as bool;
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
