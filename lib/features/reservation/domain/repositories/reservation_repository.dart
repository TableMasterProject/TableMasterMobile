import '../../data/models/reservation_out.dart';
import '../../data/models/search_reservations.dart';

abstract class IReservationRepository {
  Future<List<ReservationOut>> getReservationsByRestaurant(
    int id,
    String reservationDate,
    int? tableId,
  );
  Future<List<ReservationOut>> GetPendingReservationsByRestaurant(
    int id,
    int? tableId,
  );

  /// Retourne les réservations de l'utilisateur courant.
  ///
  /// Le paramètre [search] permet de spécifier un offset/pageSize comme
  /// sur les autres endpoints paginés du projet.
  Future<List<ReservationOut>> getMyReservations(SearchReservations search);

  Future<ReservationOut> createReservation(Map<String, dynamic> data);
  Future<ReservationOut> validateReservation(int id, bool isValidate);
  Future<bool> deleteReservation(int id);
}
