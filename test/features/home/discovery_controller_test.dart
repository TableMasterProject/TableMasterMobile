import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:table_master_mobile/features/home/presentation/discovery_controller.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_out.dart';
import 'package:table_master_mobile/features/restaurant/data/models/search_restaurant.dart';

void main() {
  test('visible map bounds are serialized without a user position', () async {
    SearchRestaurant? submitted;
    final controller = DiscoveryController(
      search: (query) async {
        submitted = query;
        return [];
      },
    );

    await controller.searchArea(
      center: const LatLng(46.6, 2.2),
      bounds: LatLngBounds(
        southwest: const LatLng(41, -5),
        northeast: const LatLng(51, 9),
      ),
    );

    expect(submitted!.toJson()['SouthLatitude'], 41);
    expect(submitted!.toJson()['EastLongitude'], 9);
    expect(submitted!.toJson().containsKey('CurrentUserLatitude'), isFalse);
    expect(controller.restaurants, isEmpty);
    controller.dispose();
  });

  test(
    'late response from an old map area cannot replace newer results',
    () async {
      final oldResponse = Completer<List<RestaurantOut>>();
      final newer = RestaurantOut.fromJson({
        'id': 2,
        'restaurantName': 'Nouveau',
      });
      var call = 0;
      final controller = DiscoveryController(
        search: (_) {
          call++;
          return call == 1 ? oldResponse.future : Future.value([newer]);
        },
      );

      final first = controller.searchArea(center: const LatLng(46, 2));
      await controller.searchArea(center: const LatLng(48, 2));
      oldResponse.complete([
        RestaurantOut.fromJson({'id': 1, 'restaurantName': 'Ancien'}),
      ]);
      await first;

      expect(controller.restaurants.single.id, 2);
      controller.dispose();
    },
  );

  test('distances are displayed only with an actual user position', () {
    final controller = DiscoveryController(search: (_) async => []);
    expect(controller.hasUserPosition, isFalse);
    controller.setUserPosition(const LatLng(48.85, 2.35));
    expect(controller.hasUserPosition, isTrue);
    controller.setUserPosition(null);
    expect(controller.hasUserPosition, isFalse);
    controller.dispose();
  });

  test('rapid filter changes keep only the newest response', () async {
    final first = Completer<List<RestaurantOut>>();
    final queries = <SearchRestaurant>[];
    final controller = DiscoveryController(
      search: (query) {
        queries.add(query);
        if (query.cuisineType == 'Italien') return first.future;
        return Future.value([
          RestaurantOut.fromJson({'id': 3, 'restaurantName': 'Bistro'}),
        ]);
      },
    );

    final slowFilter = controller.setFilters(cuisine: 'Italien');
    await controller.setFilters(cuisine: 'Français');
    first.complete([
      RestaurantOut.fromJson({'id': 2, 'restaurantName': 'Pizzeria'}),
    ]);
    await slowFilter;

    expect(queries.map((q) => q.cuisineType), ['Italien', 'Français']);
    expect(controller.restaurants.single.id, 3);
    expect(controller.loading, isFalse);
    controller.dispose();
  });
}
