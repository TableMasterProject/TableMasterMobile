import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/reservation/presentation/widgets/client_reservations_feed.dart';

ReservationOut booking(int id, ReservationStatus status) => ReservationOut(
  id: id,
  createdAt: DateTime(2036, 7, 1),
  userId: 1,
  tableId: 2,
  restaurantId: 3,
  reservationDate: DateTime(2036, 7, 21, 19),
  numberOfPeople: 2,
  status: status,
);

void main() {
  testWidgets('à venir montre attente et confirmation sans filtre', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClientReservationsFeed(
            upcoming: [
              booking(1, ReservationStatus.enAttente),
              booking(2, ReservationStatus.validee),
            ],
            history: const [],
            showHistory: false,
            onShowHistory: () {},
            onShowUpcoming: () {},
            onDiscover: () {},
            onOpenReservation: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('En attente'), findsOneWidget);
    expect(find.text('Confirmée'), findsOneWidget);
    expect(find.text('Voir l’historique'), findsOneWidget);
  });

  testWidgets('sans réservation propose de découvrir', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClientReservationsFeed(
            upcoming: const [],
            history: const [],
            showHistory: false,
            onShowHistory: () {},
            onShowUpcoming: () {},
            onDiscover: () => tapped = true,
            onOpenReservation: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Trouver un restaurant'));
    expect(tapped, true);
  });
}
