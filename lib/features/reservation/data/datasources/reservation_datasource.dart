import 'package:dio/dio.dart';
import '../../../../core/api_client.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/reservation_in.dart';
import '../models/reservation_out.dart';
import '../models/search_reservations.dart';

class ReservationDataSource {
  final ApiClient apiClient;

  ReservationDataSource(this.apiClient);

  Future<List<ReservationOut>> getReservations(
    SearchReservations search,
  ) async {
    try {
      final response = await apiClient.dio.get(
        '/Reservation',
        queryParameters: search.toJson(),
      );
      final List<dynamic> data = response.data;
      return data.map((json) => ReservationOut.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<ReservationOut> getReservationById(int id) async {
    try {
      final response = await apiClient.dio.get('/Reservation/$id');
      return ReservationOut.fromJson(response.data);
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

  Future<ReservationOut> createQuickReservation(
    int restaurantId,
    QuickReservationIn reservation,
  ) async {
    try {
      final response = await apiClient.dio.post(
        '/Reservation/Restaurant/$restaurantId/Quick',
        data: reservation.toJson(),
      );
      return ReservationOut.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // GET /api/Reservation/{id}/Validate?IsValidate=true
  Future<ReservationOut> updateReservationStatus(
    int id,
    ReservationStatus status,
  ) async {
    try {
      final response = await apiClient.dio.put(
        '/Reservation/$id/Status',
        queryParameters: {'reservationStatus': status.index},
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

  // GET /api/Reservation/My?Offset=0&PageSize=20
  Future<List<ReservationOut>> getMyReservations(
    SearchReservations search,
  ) async {
    try {
      final response = await apiClient.dio.get(
        '/Reservation/My',
        queryParameters: search.toJson(),
      );
      final List<dynamic> data = response.data;
      return data.map((json) => ReservationOut.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  void _handleError(DioException e) {
    throw AppException.fromDio(e);
  }
}
