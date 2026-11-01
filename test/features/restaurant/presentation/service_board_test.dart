import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/restaurant/presentation/widgets/service_board.dart';

ReservationOut booking(int id, ReservationStatus status) => ReservationOut(
  id: id,
  createdAt: DateTime(2036, 7, 1),
  userId: 1,
  tableId: 2,
  restaurantId: 3,
  reservationDate: DateTime(2036, 7, 21, 19, 30),
  numberOfPeople: 4,
  status: status,
  guestName: 'Client $id',
);

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  for (final width in [390.0, 1280.0, 1600.0]) {
    testWidgets('Service montre attente et confirmées à ${width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServiceBoard(
              pending: [booking(1, ReservationStatus.enAttente)],
              confirmed: [booking(2, ReservationStatus.validee)],
              history: [booking(3, ReservationStatus.finie)],
              selectedDate: DateTime(2036, 7, 21),
              onDateChanged: (_) async {},
              onStatusUpdate: (_, __) async {},
            ),
          ),
        ),
      );

      expect(find.text('À traiter'), findsWidgets);
      expect(find.text('Confirmées'), findsOneWidget);
      expect(find.text('Client 1'), findsOneWidget);
      expect(find.text('Client 2'), findsOneWidget);
      expect(find.text('Historique du jour'), findsOneWidget);
      expect(find.text('Client 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
