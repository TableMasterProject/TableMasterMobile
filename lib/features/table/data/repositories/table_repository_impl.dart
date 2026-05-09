import '../../domain/repositories/table_repository.dart';
import '../datasources/table_datasource.dart';
import '../models/table_entity_in.dart';
import '../models/table_entity_out.dart';

class TableRepositoryImpl implements ITableRepository {
  final TableDataSource remoteDataSource;

  TableRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<TableEntityOut>> getRestaurantTables(int restaurantId) async {
    return await remoteDataSource.getTablesByRestaurant(restaurantId);
  }

  @override
  Future<TableEntityOut> addTable(int restaurantId, TableEntityIn table) async {
    return await remoteDataSource.createTable(restaurantId, table);
  }

  @override
  Future<List<TableEntityOut>> replaceTables(
    int restaurantId,
    List<TableEntityIn> tables,
  ) async {
    return await remoteDataSource.replaceTables(restaurantId, tables);
  }

  @override
  Future<TableEntityOut> editTable(int id, TableEntityIn table) async {
    return await remoteDataSource.updateTable(id, table);
  }

  @override
  Future<bool> removeTable(int id) async {
    return await remoteDataSource.deleteTable(id);
  }
}
