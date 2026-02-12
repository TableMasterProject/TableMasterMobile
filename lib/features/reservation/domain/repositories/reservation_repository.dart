import '../../data/models/reservation_out.dart';

abstract class IReservationRepository {
  Future<List<ReservationOut>> getReservationsByRestaurant(
      int id,
      String reservationDate,
      int? tableId
  );
  Future<List<ReservationOut>> GetPendingReservationsByRestaurant(
      int id,
      int? tableId
      );
  Future<ReservationOut> createReservation(Map<String, dynamic> data);
  Future<ReservationOut> validateReservation(int id, bool isValidate);
  Future<bool> deleteReservation(int id);
}
