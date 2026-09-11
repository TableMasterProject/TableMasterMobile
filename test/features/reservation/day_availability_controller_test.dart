import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:table_master_mobile/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:table_master_mobile/features/reservation/data/models/search_reservations.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_availability_out.dart';
import 'package:table_master_mobile/features/reservation/presentation/controllers/day_availability_controller.dart';

class _Repository extends Mock implements IReservationRepository {}

void main() {
  setUpAll(() => registerFallbackValue(SearchReservations()));
  test('une ancienne réponse ne remplace pas la nouvelle journée', () async {
    final repository = _Repository();
    final first = Completer<List<ReservationAvailabilityOut>>();
    final second = Completer<List<ReservationAvailabilityOut>>();
    var calls = 0;
    when(
      () => repository.getAvailability(any()),
    ).thenAnswer((_) => ++calls == 1 ? first.future : second.future);
    final controller = DayAvailabilityController(repository, 10);
    final oldRequest = controller.load(DateTime(2026, 7, 1));
    final newRequest = controller.load(DateTime(2026, 7, 2));
    second.complete([]);
    await newRequest;
    first.complete([
      ReservationAvailabilityOut(
        tableId: 42,
        reservationDate: DateTime(2026, 7, 1, 20),
      ),
    ]);
    await oldRequest;
    expect(controller.day, DateTime(2026, 7, 2));
    expect(controller.reservations, isEmpty);
    expect(controller.isReady, isTrue);
    controller.dispose();
  });
  test(
    'une panne retire la disponibilité connue et permet de réessayer',
    () async {
      final repository = _Repository();
      when(
        () => repository.getAvailability(any()),
      ).thenThrow(Exception('Hors ligne'));
      final controller = DayAvailabilityController(repository, 10);
      await controller.load(DateTime(2026, 7, 1));
      expect(controller.isReady, isFalse);
      expect(controller.error, contains('Hors ligne'));
      when(() => repository.getAvailability(any())).thenAnswer(
        (_) async => List.generate(
          250,
          (i) => ReservationAvailabilityOut(
            tableId: i,
            reservationDate: DateTime(2026, 7, 1, 20),
          ),
        ),
      );
      await controller.reload();
      expect(controller.isReady, isTrue);
      expect(controller.reservations.length, 250);
      controller.dispose();
    },
  );
}
