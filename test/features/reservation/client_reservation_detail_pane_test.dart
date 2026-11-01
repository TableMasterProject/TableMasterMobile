import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/reservation/presentation/widgets/client_reservation_detail_pane.dart';

ReservationOut booking(ReservationStatus status) => ReservationOut(
  id: 1,
  createdAt: DateTime(2026),
  userId: 2,
  tableId: 3,
  restaurantId: 4,
  reservationDate: DateTime(2026, 11, 10, 19),
  numberOfPeople: 2,
  status: status,
);

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  testWidgets('une demande se retire depuis le panneau après confirmation', (
    tester,
  ) async {
    var deleted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClientReservationDetailPane(
            reservation: booking(ReservationStatus.enAttente),
            onDelete: () async => deleted = true,
            onCancel: () async {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('Retirer la demande'));
    await tester.pumpAndSettle();
    expect(deleted, false);
    await tester.tap(find.text('Confirmer le retrait'));
    await tester.pumpAndSettle();
    expect(deleted, true);
  });

  testWidgets('une réservation confirmée propose une annulation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClientReservationDetailPane(
            reservation: booking(ReservationStatus.validee),
            onDelete: () async {},
            onCancel: () async {},
          ),
        ),
      ),
    );
    expect(find.text('Annuler la réservation'), findsOneWidget);
    expect(find.text('Retirer la demande'), findsNothing);
  });
}
