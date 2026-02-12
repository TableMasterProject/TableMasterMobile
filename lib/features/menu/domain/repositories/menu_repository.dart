import '../../data/models/menu_in.dart';
import '../../data/models/menu_out.dart';

abstract class IMenuRepository {
  Future<List<MenuOut>> getByRestaurant(int restaurantId);
  Future<MenuOut> create(MenuIn menu);
  Future<bool> delete(int id);
}
