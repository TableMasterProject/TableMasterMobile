import '../../domain/repositories/reservation_repository.dart';
import '../datasources/reservation_datasource.dart';
import '../models/reservation_out.dart';

class ReservationRepositoryImpl implements IReservationRepository {
  final ReservationDataSource remoteDataSource;

  ReservationRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<ReservationOut>> getReservationsByRestaurant(
      int id,
      String reservationDate,
      int? tableId
  ) async {
    return await remoteDataSource.getReservationsByRestaurant(
        id,
        reservationDate,
        tableId
    );
  }

  @override
  Future<List<ReservationOut>> GetPendingReservationsByRestaurant(
      int id,
      int? tableId
  ) async {
    return await remoteDataSource.getPendingReservationsByRestaurant(
      id,
      tableId
    );
  }

  @override
  Future<ReservationOut> createReservation(Map<String, dynamic> data) async {
    return await remoteDataSource.createReservation(data);
  }

  @override
  Future<ReservationOut> validateReservation(int id, bool isValidate) async {
    return await remoteDataSource.validateReservation(id, isValidate);
  }

  @override
  Future<bool> deleteReservation(int id) async {
    return await remoteDataSource.deleteReservation(id);
  }


}
