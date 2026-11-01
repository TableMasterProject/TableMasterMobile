import 'package:table_master_mobile/features/table/data/models/table_entity_out.dart';

TableEntityOut? suggestTable(
  List<TableEntityOut> tables,
  int guests,
  bool Function(TableEntityOut) isAvailable,
) {
  final candidates =
      tables
          .where((table) => table.numberOfSeats >= guests && isAvailable(table))
          .toList()
        ..sort((a, b) {
          final seats = a.numberOfSeats.compareTo(b.numberOfSeats);
          return seats != 0 ? seats : a.tableNumber.compareTo(b.tableNumber);
        });
  return candidates.firstOrNull;
}
