import '../../data/models/table_entity_in.dart';
import '../../data/models/table_entity_out.dart';

abstract class ITableRepository {
  Future<List<TableEntityOut>> getRestaurantTables(int restaurantId);
  Future<TableEntityOut> addTable(int restaurantId, TableEntityIn table);
  Future<List<TableEntityOut>> replaceTables(
    int restaurantId,
    List<TableEntityIn> tables,
  );
  Future<TableEntityOut> editTable(int id, TableEntityIn table);
  Future<bool> removeTable(int id);
}
