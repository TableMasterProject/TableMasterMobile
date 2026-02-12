import '../../domain/repositories/daily_activity_repository.dart';
import '../datasources/daily_activity_datasource.dart';
import '../models/daily_activity_in.dart';
import '../models/daily_activity_out.dart';

class DailyActivityRepositoryImpl implements IDailyActivityRepository {
  final DailyActivityDataSource dataSource;

  DailyActivityRepositoryImpl(this.dataSource);

  @override
  Future<List<DailyActivityOut>> getByRestaurant(int restaurantId) =>
      dataSource.getByRestaurant(restaurantId);

  @override
  Future<DailyActivityOut> create(DailyActivityIn activity) =>
      dataSource.create(activity);

  @override
  Future<DailyActivityOut> update(int id, DailyActivityIn activity) =>
      dataSource.update(id, activity);

  @override
  Future<bool> delete(int id) => dataSource.delete(id);
}
