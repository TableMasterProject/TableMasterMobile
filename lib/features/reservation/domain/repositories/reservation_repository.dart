import '../../data/models/reservation_in.dart';
import '../../data/models/reservation_out.dart';
import '../../data/models/search_reservations.dart';

abstract class IReservationRepository {
  Future<List<ReservationOut>> getReservations(SearchReservations search);
  Future<List<ReservationOut>> getMyReservations(SearchReservations search);

  Future<ReservationOut> createReservation(Map<String, dynamic> data);
  Future<ReservationOut> createQuickReservation(
    int restaurantId,
    QuickReservationIn reservation,
  );
  Future<ReservationOut> updateReservationStatus(
    int id,
    ReservationStatus reservationStatus,
  );
  Future<bool> deleteReservation(int id);
}
