import '../../domain/repositories/reservation_repository.dart';
import '../datasources/reservation_datasource.dart';
import '../models/reservation_in.dart';
import '../models/reservation_out.dart';
import '../models/search_reservations.dart';

class ReservationRepositoryImpl implements IReservationRepository {
  final ReservationDataSource remoteDataSource;

  ReservationRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<ReservationOut>> getReservations(
    SearchReservations search,
  ) async {
    return await remoteDataSource.getReservations(search);
  }

  @override
  Future<ReservationOut> createReservation(Map<String, dynamic> data) async {
    return await remoteDataSource.createReservation(data);
  }

  @override
  Future<ReservationOut> createQuickReservation(
    int restaurantId,
    QuickReservationIn reservation,
  ) async {
    return await remoteDataSource.createQuickReservation(
      restaurantId,
      reservation,
    );
  }

  @override
  Future<ReservationOut> updateReservationStatus(
    int id,
    ReservationStatus reservationStatus,
  ) async {
    return await remoteDataSource.updateReservationStatus(
      id,
      reservationStatus,
    );
  }

  @override
  Future<bool> deleteReservation(int id) async {
    return await remoteDataSource.deleteReservation(id);
  }

  @override
  Future<List<ReservationOut>> getMyReservations(
    SearchReservations search,
  ) async {
    return await remoteDataSource.getMyReservations(search);
  }
}
