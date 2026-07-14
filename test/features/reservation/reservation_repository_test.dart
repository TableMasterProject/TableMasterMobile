import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:table_master_mobile/features/reservation/data/datasources/reservation_datasource.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_availability_out.dart';
import 'package:table_master_mobile/features/reservation/data/models/search_reservations.dart';
import 'package:table_master_mobile/features/reservation/data/repositories/reservation_repository_impl.dart';

class _MockReservationDataSource extends Mock
    implements ReservationDataSource {}

class _FakeSearch extends Fake implements SearchReservations {}

class _FakeQuickReservation extends Fake implements QuickReservationIn {}

void main() {
  late _MockReservationDataSource dataSource;
  late ReservationRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(_FakeSearch());
    registerFallbackValue(_FakeQuickReservation());
  });

  setUp(() {
    dataSource = _MockReservationDataSource();
    repository = ReservationRepositoryImpl(dataSource);
  });

  ReservationOut buildReservation({
    int id = 1,
    ReservationStatus status = ReservationStatus.enAttente,
  }) => ReservationOut(
    id: id,
    createdAt: DateTime(2026, 5, 19),
    userId: 1,
    tableId: 2,
    restaurantId: 3,
    reservationDate: DateTime(2026, 5, 20, 20, 0),
    numberOfPeople: 4,
    status: status,
  );

  group('ReservationRepositoryImpl', () {
    test('getAvailability retourne uniquement les créneaux occupés', () async {
      final expected = [
        ReservationAvailabilityOut(
          tableId: 2,
          reservationDate: DateTime(2026, 5, 20, 20),
        ),
      ];
      when(
        () => dataSource.getAvailability(any()),
      ).thenAnswer((_) async => expected);

      final result = await repository.getAvailability(SearchReservations());

      expect(result.single.tableId, 2);
      verify(() => dataSource.getAvailability(any())).called(1);
    });

    test(
      'getReservations délègue au datasource et retourne la liste',
      () async {
        final expected = [buildReservation(), buildReservation(id: 2)];
        when(
          () => dataSource.getReservations(any()),
        ).thenAnswer((_) async => expected);

        final result = await repository.getReservations(SearchReservations());

        expect(result, hasLength(2));
        expect(result.first.id, 1);
        verify(() => dataSource.getReservations(any())).called(1);
      },
    );

    test('getMyReservations délègue au datasource', () async {
      when(
        () => dataSource.getMyReservations(any()),
      ).thenAnswer((_) async => [buildReservation()]);

      final result = await repository.getMyReservations(SearchReservations());

      expect(result.first.userId, 1);
      verify(() => dataSource.getMyReservations(any())).called(1);
    });

    test('getReservationById délègue au datasource', () async {
      final expected = buildReservation(id: 12);
      when(
        () => dataSource.getReservationById(12),
      ).thenAnswer((_) async => expected);

      final result = await repository.getReservationById(12);

      expect(result.id, 12);
      verify(() => dataSource.getReservationById(12)).called(1);
    });

    test(
      'createReservation envoie la map et renvoie la réservation créée',
      () async {
        final created = buildReservation(id: 99);
        when(
          () => dataSource.createReservation(any()),
        ).thenAnswer((_) async => created);

        final result = await repository.createReservation({
          'TableId': 2,
          'RestaurantId': 3,
          'NumberOfPeople': 4,
        });

        expect(result.id, 99);
        verify(
          () => dataSource.createReservation({
            'TableId': 2,
            'RestaurantId': 3,
            'NumberOfPeople': 4,
          }),
        ).called(1);
      },
    );

    test(
      'createQuickReservation transmet le restaurant et le payload',
      () async {
        final created = buildReservation(
          id: 100,
          status: ReservationStatus.validee,
        );
        final input = QuickReservationIn(
          tableId: 2,
          reservationDate: DateTime(2026, 5, 20, 20, 0),
          numberOfPeople: 4,
          guestName: 'Martin',
          guestPhone: '0601020304',
        );
        when(
          () => dataSource.createQuickReservation(3, input),
        ).thenAnswer((_) async => created);

        final result = await repository.createQuickReservation(3, input);

        expect(result.id, 100);
        expect(result.status, ReservationStatus.validee);
        verify(() => dataSource.createQuickReservation(3, input)).called(1);
      },
    );

    test('updateReservationStatus transmet l\'id et le statut', () async {
      final updated = buildReservation(
        id: 7,
        status: ReservationStatus.validee,
      );
      when(
        () => dataSource.updateReservationStatus(7, ReservationStatus.validee),
      ).thenAnswer((_) async => updated);

      final result = await repository.updateReservationStatus(
        7,
        ReservationStatus.validee,
      );

      expect(result.status, ReservationStatus.validee);
    });

    test('deleteReservation retourne le booléen du datasource', () async {
      when(
        () => dataSource.deleteReservation(42),
      ).thenAnswer((_) async => true);

      final ok = await repository.deleteReservation(42);

      expect(ok, isTrue);
    });

    test('propage les exceptions du datasource sans les avaler', () async {
      when(
        () => dataSource.deleteReservation(any()),
      ).thenThrow(Exception('boom'));

      expect(() => repository.deleteReservation(1), throwsException);
    });
  });
}
