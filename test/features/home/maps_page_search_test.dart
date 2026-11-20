import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:table_master_mobile/features/home/data/city_search_service.dart';
import 'package:table_master_mobile/features/home/presentation/pages/maps_page.dart';
import 'package:table_master_mobile/features/restaurant/data/models/search_restaurant.dart';

void main() {
  testWidgets('ouvrir la carte après une ville déclenche la recherche carte', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final searches = <SearchRestaurant>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 600,
          height: 800,
          child: MapsPage(
            visibleRegion:
                () async => LatLngBounds(
                  southwest: const LatLng(45.6, 4.7),
                  northeast: const LatLng(45.9, 5.0),
                ),
            restaurantSearch: (query) async {
              searches.add(query);
              return [];
            },
            citySearch:
                (_) async => const [
                  CitySuggestion(
                    name: 'Lyon',
                    code: '69123',
                    department: '69',
                    center: LatLng(45.758, 4.8351),
                  ),
                ],
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Lyon');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    await tester.tap(find.text('Lyon (69)'));
    await tester.pump();
    expect(searches, hasLength(1));

    await tester.tap(find.text('Carte'));
    await tester.pump();
    expect(searches.length, greaterThan(1));
    expect(searches.last.toJson()['SouthLatitude'], 45.6);
    expect(searches.last.toJson().containsKey('RadiusKm'), isFalse);
  });

  testWidgets('choisir une ville lance la liste sans ouvrir la carte', (
    tester,
  ) async {
    final searches = <SearchRestaurant>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 800,
            child: MapsPage(
              restaurantSearch: (query) async {
                searches.add(query);
                return [];
              },
              citySearch:
                  (_) async => const [
                    CitySuggestion(
                      name: 'Lyon',
                      code: '69123',
                      department: '69',
                      center: LatLng(45.758, 4.8351),
                    ),
                  ],
            ),
          ),
        ),
      ),
    );

    expect(searches, isEmpty);
    await tester.enterText(find.byType(TextField), 'Lyon');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    await tester.tap(find.text('Lyon (69)'));
    await tester.pump();

    expect(searches, hasLength(1));
    expect(searches.single.toJson()['RadiusKm'], 15);
    expect(searches.single.toJson().containsKey('SouthLatitude'), isFalse);
    await tester.tap(find.text('15 km'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 km').last);
    await tester.pump();
    expect(searches, hasLength(2));
    expect(searches.last.toJson()['RadiusKm'], 5);
  });
}
