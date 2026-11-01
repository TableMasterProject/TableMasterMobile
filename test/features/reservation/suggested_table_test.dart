import 'package:flutter_test/flutter_test.dart';
import 'package:table_master_mobile/features/reservation/presentation/controllers/suggested_table.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_out.dart';

void main() {
  TableEntityOut table(int id, int seats) => TableEntityOut(
    id: id,
    restaurantId: 1,
    tableNumber: id,
    numberOfSeats: seats,
    createdAt: DateTime(2026),
  );

  test('choisit la plus petite table libre adaptée au groupe', () {
    final tables = [table(1, 6), table(2, 2), table(3, 4), table(4, 4)];
    expect(suggestTable(tables, 3, (candidate) => candidate.id != 3)?.id, 4);
    expect(suggestTable(tables, 7, (_) => true), isNull);
  });
}
