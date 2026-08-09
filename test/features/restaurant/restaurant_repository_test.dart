import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:table_master_mobile/features/restaurant/data/datasources/restaurant_datasource.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_in.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_out.dart';
import 'package:table_master_mobile/features/restaurant/data/models/search_restaurant.dart';
import 'package:table_master_mobile/features/restaurant/data/repositories/restaurant_repository_impl.dart';

class _MockRestaurantDataSource extends Mock implements RestaurantDataSource {}

class _FakeSearch extends Fake implements SearchRestaurant {}

class _FakeRestaurantIn extends Fake implements RestaurantIn {}

void main() {
  late _MockRestaurantDataSource dataSource;
  late RestaurantRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(_FakeSearch());
    registerFallbackValue(_FakeRestaurantIn());
  });

  setUp(() {
    dataSource = _MockRestaurantDataSource();
    repository = RestaurantRepositoryImpl(dataSource);
  });

  RestaurantOut buildRestaurant({int id = 1, String name = 'Le Comptoir'}) =>
      RestaurantOut(
        userId: 1,
        restaurantName: name,
        streetNumber: '12',
        streetName: 'rue Lafayette',
        postalCode: '69001',
        city: 'Lyon',
        phone: '04 78 00 00 00',
        cuisineType: 'Bistrot',
        paymentMethods: 'CB · Espèces',
        description: 'Bistrot lyonnais traditionnel',
        isAutoValidateReservation: false,
        id: id,
        createdAt: DateTime(2026, 1, 1),
        distanceForSearch: 0,
        distanceWithUser: 0,
        averageRating: 4.5,
        numberOfReviews: 27,
      );

  group('RestaurantRepositoryImpl', () {
    test('getAllRestaurants délègue au datasource', () async {
      when(
        () => dataSource.getRestaurants(any()),
      ).thenAnswer((_) async => [buildRestaurant(), buildRestaurant(id: 2)]);

      final result = await repository.getAllRestaurants(SearchRestaurant());

      expect(result, hasLength(2));
      verify(() => dataSource.getRestaurants(any())).called(1);
    });

    test('getRestaurantDetails passe bien l\'id', () async {
      when(
        () => dataSource.getRestaurantById(42),
      ).thenAnswer((_) async => buildRestaurant(id: 42));

      final r = await repository.getRestaurantDetails(42);

      expect(r.id, 42);
      verify(() => dataSource.getRestaurantById(42)).called(1);
    });

    test('createRestaurant délègue au datasource', () async {
      when(
        () => dataSource.postRestaurant(any()),
      ).thenAnswer((_) async => buildRestaurant(id: 99));

      final r = await repository.createRestaurant(_FakeRestaurantIn());

      expect(r.id, 99);
    });

    test('deleteRestaurant retourne le booléen du datasource', () async {
      when(() => dataSource.deleteRestaurant(7)).thenAnswer((_) async => true);

      final ok = await repository.deleteRestaurant(7);

      expect(ok, isTrue);
    });
  });

  group('RestaurantOut.addressString', () {
    test("formate l'adresse complète", () {
      final r = buildRestaurant();
      expect(r.addressString(), '12 rue Lafayette, 69001 Lyon');
    });
  });
}
