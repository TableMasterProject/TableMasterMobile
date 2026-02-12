import '../../domain/repositories/closed_day_exception_repository.dart';
import '../datasources/closed_day_exception_datasource.dart';
import '../models/closed_day_exception_in.dart';
import '../models/closed_day_exception_out.dart';

class ClosedDayExceptionRepositoryImpl
    implements IClosedDayExceptionRepository {
  final ClosedDayExceptionDataSource dataSource;

  ClosedDayExceptionRepositoryImpl(this.dataSource);

  @override
  Future<List<ClosedDayExceptionOut>> getByRestaurant(int restaurantId) =>
      dataSource.getByRestaurant(restaurantId);

  @override
  Future<ClosedDayExceptionOut> create(ClosedDayExceptionIn exception) =>
      dataSource.create(exception);

  @override
  Future<ClosedDayExceptionOut> update(
    int id,
    ClosedDayExceptionIn exception,
  ) => dataSource.update(id, exception);

  @override
  Future<bool> delete(int id) => dataSource.delete(id);
}
