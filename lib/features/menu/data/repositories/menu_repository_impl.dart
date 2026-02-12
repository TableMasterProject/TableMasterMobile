import '../../domain/repositories/menu_repository.dart';
import '../datasources/menu_datasource.dart';
import '../models/menu_in.dart';
import '../models/menu_out.dart';

class MenuRepositoryImpl implements IMenuRepository {
  final MenuDataSource dataSource;

  MenuRepositoryImpl(this.dataSource);

  @override
  Future<List<MenuOut>> getByRestaurant(int restaurantId) =>
      dataSource.getByRestaurant(restaurantId);

  @override
  Future<MenuOut> create(MenuIn menu) => dataSource.create(menu);

  @override
  Future<bool> delete(int id) => dataSource.delete(id);
}
