import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:table_master_mobile/features/reservation/data/datasources/reservation_datasource.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/reservation/data/models/search_reservations.dart';
import 'package:table_master_mobile/features/reservation/data/repositories/reservation_repository_impl.dart';

class _MockReservationDataSource extends Mock implements ReservationDataSource {}

class _FakeSearch extends Fake implements SearchReservations {}

void main() {
  late _MockReservationDataSource dataSource;
  late ReservationRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(_FakeSearch());
  });

  setUp(() {
    dataSource = _MockReservationDataSource();
    repository = ReservationRepositoryImpl(dataSource);
  });

  ReservationOut _buildReservation({
    int id = 1,
    ReservationStatus status = ReservationStatus.enAttente,
  }) =>
      ReservationOut(
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
    test('getReservations délègue au datasource et retourne la liste', () async {
      final expected = [_buildReservation(), _buildReservation(id: 2)];
      when(() => dataSource.getReservations(any())).thenAnswer((_) async => expected);

      final result = await repository.getReservations(SearchReservations());

      expect(result, hasLength(2));
      expect(result.first.id, 1);
      verify(() => dataSource.getReservations(any())).called(1);
    });

    test('getMyReservations délègue au datasource', () async {
      when(() => dataSource.getMyReservations(any()))
          .thenAnswer((_) async => [_buildReservation()]);

      final result = await repository.getMyReservations(SearchReservations());

      expect(result.first.userId, 1);
      verify(() => dataSource.getMyReservations(any())).called(1);
    });

    test('createReservation envoie la map et renvoie la réservation créée', () async {
      final created = _buildReservation(id: 99);
      when(() => dataSource.createReservation(any())).thenAnswer((_) async => created);

      final result = await repository.createReservation({
        'TableId': 2,
        'RestaurantId': 3,
        'NumberOfPeople': 4,
      });

      expect(result.id, 99);
      verify(() => dataSource.createReservation({
            'TableId': 2,
            'RestaurantId': 3,
            'NumberOfPeople': 4,
          })).called(1);
    });

    test('updateReservationStatus transmet l\'id et le statut', () async {
      final updated = _buildReservation(id: 7, status: ReservationStatus.validee);
      when(() => dataSource.updateReservationStatus(7, ReservationStatus.validee))
          .thenAnswer((_) async => updated);

      final result =
          await repository.updateReservationStatus(7, ReservationStatus.validee);

      expect(result.status, ReservationStatus.validee);
    });

    test('deleteReservation retourne le booléen du datasource', () async {
      when(() => dataSource.deleteReservation(42)).thenAnswer((_) async => true);

      final ok = await repository.deleteReservation(42);

      expect(ok, isTrue);
    });

    test('propage les exceptions du datasource sans les avaler', () async {
      when(() => dataSource.deleteReservation(any())).thenThrow(Exception('boom'));

      expect(() => repository.deleteReservation(1), throwsException);
    });
  });
}
