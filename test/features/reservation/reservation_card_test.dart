import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/reservation/presentation/widgets/reservation_card.dart';
import 'package:table_master_mobile/features/user/data/models/user_out.dart';

UserOut _buildUser({String firstName = 'Léa'}) => UserOut(
      id: 1,
      email: 'lea@example.com',
      password: '',
      firstName: firstName,
      lastName: 'Martin',
      accountType: 0,
      createdAt: DateTime(2026, 1, 1),
    );

ReservationOut _buildReservation({
  ReservationStatus status = ReservationStatus.enAttente,
  String? specialRequest,
}) =>
    ReservationOut(
      id: 1,
      createdAt: DateTime(2026, 5, 19),
      userId: 1,
      tableId: 2,
      restaurantId: 3,
      reservationDate: DateTime(2026, 5, 20, 20, 0),
      numberOfPeople: 4,
      status: status,
      specialRequest: specialRequest,
      user: _buildUser(),
    );

Future<void> _pumpCard(
  WidgetTester tester, {
  required ReservationOut reservation,
  void Function(ReservationStatus)? onStatusUpdate,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ReservationCard(
          reservation: reservation,
          onStatusUpdate: onStatusUpdate,
        ),
      ),
    ),
  );
}

void main() {
  group('ReservationCard', () {
    testWidgets('affiche le prénom du client, le nombre de convives et le statut',
        (tester) async {
      await _pumpCard(tester, reservation: _buildReservation());

      expect(find.text('Léa'), findsOneWidget);
      expect(find.text('4 convives'), findsOneWidget);
      expect(find.text('EN ATTENTE'), findsOneWidget);
    });

    testWidgets('affiche la demande spéciale quand renseignée', (tester) async {
      await _pumpCard(
        tester,
        reservation: _buildReservation(specialRequest: 'Allergie aux fruits de mer'),
      );

      expect(
        find.text('Demande : Allergie aux fruits de mer'),
        findsOneWidget,
      );
    });

    testWidgets('change le libellé de statut sur réservation validée',
        (tester) async {
      await _pumpCard(
        tester,
        reservation: _buildReservation(status: ReservationStatus.validee),
      );

      expect(find.text('CONFIRMÉE'), findsOneWidget);
    });

    testWidgets("n'affiche aucun bouton d'action quand onStatusUpdate est null",
        (tester) async {
      await _pumpCard(tester, reservation: _buildReservation());

      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('appelle onStatusUpdate(validee) quand on tape sur valider',
        (tester) async {
      ReservationStatus? captured;
      await _pumpCard(
        tester,
        reservation: _buildReservation(),
        onStatusUpdate: (s) => captured = s,
      );

      await tester.tap(find.byTooltip('Valider'));
      await tester.pump();

      expect(captured, ReservationStatus.validee);
    });
  });
}
