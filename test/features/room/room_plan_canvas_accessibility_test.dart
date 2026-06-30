import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:table_master_mobile/features/room/data/models/room_point.dart';
import 'package:table_master_mobile/features/room/presentation/widgets/room_plan_canvas.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_out.dart';

void main() {
  testWidgets(
    'expose chaque table et son état aux technologies d’assistance',
    (tester) async {
      final table = TableEntityOut(
        id: 12,
        restaurantId: 1,
        roomId: 2,
        tableNumber: 4,
        numberOfSeats: 6,
        createdAt: DateTime(2026, 6, 30),
      );
      TableEntityOut? selectedTable;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomPlanCanvas(
              boundaryPoints: [
                RoomPoint(x: 0.05, y: 0.05),
                RoomPoint(x: 0.95, y: 0.05),
                RoomPoint(x: 0.95, y: 0.95),
                RoomPoint(x: 0.05, y: 0.95),
              ],
              tables: [table],
              tableStatuses: const {12: 'Occupée'},
              pendingBadgeCounts: const {12: 2},
              validatedBadgeCounts: const {12: 1},
              disableUnavailableTables: false,
              onTableSelected: (value) {
                selectedTable = value as TableEntityOut;
              },
            ),
          ),
        ),
      );

      final semantics = find.bySemanticsLabel(
        'Table 4, 6 places, Occupée, 2 réservations en attente, '
        '1 réservation validée',
      );
      expect(semantics, findsOneWidget);

      await tester.tap(semantics);
      expect(selectedTable, same(table));
    },
  );

  testWidgets('annonce une table indisponible sans action', (tester) async {
    final table = TableEntityOut(
      id: 13,
      restaurantId: 1,
      tableNumber: 5,
      numberOfSeats: 1,
      createdAt: DateTime(2026, 6, 30),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoomPlanCanvas(
            boundaryPoints: [
              RoomPoint(x: 0, y: 0),
              RoomPoint(x: 1, y: 0),
              RoomPoint(x: 1, y: 1),
            ],
            tables: [table],
            tableStatuses: const {13: 'Indisponible'},
            onTableSelected: (_) {},
          ),
        ),
      ),
    );

    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(
        find.bySemanticsLabel('Table 5, 1 place, Indisponible'),
      ),
      matchesSemantics(
        label: 'Table 5, 1 place, Indisponible',
        isEnabled: false,
        isSelected: false,
      ),
    );
    handle.dispose();
  });
}
