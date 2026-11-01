import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:table_master_mobile/features/home/data/city_search_service.dart';
import 'package:table_master_mobile/features/home/presentation/city_suggestions_controller.dart';

void main() {
  const paris = CitySuggestion(
    name: 'Paris',
    code: '75056',
    department: '75',
    center: LatLng(48.85, 2.35),
  );
  const lyon = CitySuggestion(
    name: 'Lyon',
    code: '69123',
    department: '69',
    center: LatLng(45.75, 4.83),
  );

  test('short input never requests suggestions', () async {
    var calls = 0;
    final controller = CitySuggestionsController(
      search: (_) async {
        calls++;
        return [paris];
      },
      debounce: Duration.zero,
    );
    controller.updateQuery('P');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(calls, 0);
    expect(controller.cities, isEmpty);
    controller.dispose();
  });

  test('late suggestion response cannot replace newer city results', () async {
    final first = Completer<List<CitySuggestion>>();
    final controller = CitySuggestionsController(
      search: (query) => query == 'Paris' ? first.future : Future.value([lyon]),
      debounce: Duration.zero,
    );
    controller.updateQuery('Paris');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    controller.updateQuery('Lyon');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    first.complete([paris]);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(controller.cities.single.name, 'Lyon');
    controller.dispose();
  });

  test('failed suggestion request shows recoverable error', () async {
    final controller = CitySuggestionsController(
      search: (_) async => throw StateError('offline'),
      debounce: Duration.zero,
    );
    controller.updateQuery('Paris');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(controller.hasError, isTrue);
    controller.clear();
    expect(controller.hasError, isFalse);
    controller.dispose();
  });
}
