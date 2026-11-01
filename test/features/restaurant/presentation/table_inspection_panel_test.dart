import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/restaurant/presentation/widgets/table_inspection_panel.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_out.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  testWidgets('une table montre ses demandes et confirmations ensemble', (
    tester,
  ) async {
    final table = TableEntityOut(
      id: 2,
      restaurantId: 3,
      tableNumber: 2,
      numberOfSeats: 4,
      createdAt: DateTime(2024),
    );
    ReservationOut booking(int id, ReservationStatus status) => ReservationOut(
      id: id,
      createdAt: DateTime(2036, 7, 1),
      userId: 1,
      tableId: 2,
      restaurantId: 3,
      reservationDate: DateTime(2036, 7, 21, 19),
      numberOfPeople: 2,
      status: status,
      guestName: 'Client $id',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TableInspectionPanel(
            table: table,
            selectedDate: DateTime(2036, 7, 21),
            pending: [booking(1, ReservationStatus.enAttente)],
            confirmed: [booking(2, ReservationStatus.validee)],
            onClose: () {},
            onStatusUpdate: (_, __) async {},
          ),
        ),
      ),
    );

    expect(find.text('Table 2'), findsOneWidget);
    expect(find.text('Client 1'), findsOneWidget);
    expect(find.text('Client 2'), findsOneWidget);
    expect(find.text('Historique'), findsNothing);
  });
}
