import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/restaurant/presentation/widgets/service_reservation_card.dart';

ReservationOut reservation(ReservationStatus status) => ReservationOut(
  id: 7,
  createdAt: DateTime(2036, 7, 1),
  userId: 1,
  tableId: 2,
  restaurantId: 3,
  reservationDate: DateTime(2036, 7, 21, 19, 30),
  numberOfPeople: 4,
  status: status,
  guestName: 'Léa',
);

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));
  testWidgets('valider traite une demande en un appui', (tester) async {
    ReservationStatus? sent;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ServiceReservationCard(
            reservation: reservation(ReservationStatus.enAttente),
            onStatusUpdate: (status) async => sent = status,
          ),
        ),
      ),
    );

    expect(find.text('Léa'), findsOneWidget);
    await tester.tap(find.text('Valider'));
    await tester.pump();
    expect(sent, ReservationStatus.validee);
  });

  testWidgets('refuser demande une confirmation', (tester) async {
    ReservationStatus? sent;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ServiceReservationCard(
            reservation: reservation(ReservationStatus.enAttente),
            onStatusUpdate: (status) async => sent = status,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Refuser'));
    await tester.pumpAndSettle();
    expect(sent, isNull);
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(sent, ReservationStatus.annuleeResto);
  });
}
