import '../../data/models/daily_activity_in.dart';
import '../../data/models/daily_activity_out.dart';

abstract class IDailyActivityRepository {
  Future<List<DailyActivityOut>> getByRestaurant(int restaurantId);
  Future<DailyActivityOut> create(DailyActivityIn activity);
  Future<DailyActivityOut> update(int id, DailyActivityIn activity);
  Future<bool> delete(int id);
}
