import 'package:table_master_mobile/features/table/data/models/table_entity_in.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_out.dart';

class TableChanges {
  final List<TableEntityIn> toAdd;
  final List<TableEntityOut> toUpdate;
  final List<TableEntityOut> toDelete;

  TableChanges({required this.toAdd, required this.toUpdate, required this.toDelete});
}