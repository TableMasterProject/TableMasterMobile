import '../../data/models/closed_day_exception_in.dart';
import '../../data/models/closed_day_exception_out.dart';

abstract class IClosedDayExceptionRepository {
  Future<List<ClosedDayExceptionOut>> getByRestaurant(int restaurantId);
  Future<ClosedDayExceptionOut> create(ClosedDayExceptionIn exception);
  Future<ClosedDayExceptionOut> update(int id, ClosedDayExceptionIn exception);
  Future<bool> delete(int id);
}
