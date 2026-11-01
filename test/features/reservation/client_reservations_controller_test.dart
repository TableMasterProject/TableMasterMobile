import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/reservation/data/models/search_reservations.dart';
import 'package:table_master_mobile/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:table_master_mobile/features/reservation/presentation/controllers/client_reservations_controller.dart';

class _Repo extends Mock implements IReservationRepository {}

ReservationOut booking(int id, DateTime date, ReservationStatus status) =>
    ReservationOut(
      id: id,
      createdAt: date,
      userId: 1,
      tableId: 2,
      restaurantId: 3,
      reservationDate: date,
      numberOfPeople: 2,
      status: status,
    );

void main() {
  setUpAll(() => registerFallbackValue(SearchReservations()));

  test('à venir réunit les demandes et confirmations futures', () async {
    final repo = _Repo();
    final searches = <SearchReservations>[];
    when(() => repo.getMyReservations(any())).thenAnswer((call) async {
      searches.add(call.positionalArguments.first as SearchReservations);
      return [booking(1, DateTime(2036, 7, 22), ReservationStatus.enAttente)];
    });
    final controller = ClientReservationsController(
      repository: repo,
      today: DateTime(2036, 7, 21),
    );

    await controller.loadUpcoming();

    expect(searches.single.statuses, [
      ReservationStatus.enAttente,
      ReservationStatus.validee,
    ]);
    expect(searches.single.minDate, DateTime(2036, 7, 21));
    expect(controller.upcoming.single.id, 1);
    controller.dispose();
  });

  test(
    'historique réunit passé et annulations récentes dans le bon ordre',
    () async {
      final repo = _Repo();
      final searches = <SearchReservations>[];
      when(() => repo.getMyReservations(any())).thenAnswer((call) async {
        final search = call.positionalArguments.first as SearchReservations;
        searches.add(search);
        return search.maxDate != null
            ? [booking(1, DateTime(2036, 7, 19), ReservationStatus.validee)]
            : [
              booking(
                2,
                DateTime(2036, 7, 21),
                ReservationStatus.annuleeClient,
              ),
            ];
      });
      final controller = ClientReservationsController(
        repository: repo,
        today: DateTime(2036, 7, 21),
      );

      await controller.loadHistory();

      expect(searches, hasLength(2));
      expect(searches.every((search) => search.sortDescending), true);
      expect(searches.first.maxDate, DateTime(2036, 7, 20));
      expect(controller.history.map((reservation) => reservation.id), [2, 1]);
      controller.dispose();
    },
  );
}
