import 'package:flutter_test/flutter_test.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_out.dart';

void main() {
  group('RestaurantOut.fromJson', () {
    test('parse un restaurant complet sans listes liées', () {
      final json = {
        'id': 42,
        'userId': 1,
        'restaurantName': 'Le Comptoir',
        'streetNumber': '12',
        'streetName': 'rue Lafayette',
        'postalCode': '69001',
        'city': 'Lyon',
        'latitude': 45.7640,
        'longitude': 4.8357,
        'phone': '04 78 00 00 00',
        'cuisineType': 'Bistrot',
        'paymentMethods': 'CB · Espèces',
        'description': 'Bistrot lyonnais',
        'isAutoValidateReservation': false,
        'createdAt': '2026-01-15T08:00:00.000Z',
        'distanceForSearch': 1.4,
        'distanceWithUser': 1.4,
        'averageRating': 4.5,
        'numberOfReviews': 27,
      };

      final r = RestaurantOut.fromJson(json);

      expect(r.id, 42);
      expect(r.restaurantName, 'Le Comptoir');
      expect(r.latitude, closeTo(45.7640, 1e-6));
      expect(r.averageRating, 4.5);
      expect(r.numberOfReviews, 27);
      expect(r.rooms, isNull);
    });

    test('tolère un JSON minimal en repliant sur des valeurs neutres', () {
      final r = RestaurantOut.fromJson({});

      expect(r.id, 0);
      expect(r.restaurantName, '');
      expect(r.averageRating, 0.0);
      expect(r.numberOfReviews, 0);
      expect(r.latitude, isNull);
    });

    test('addressString compose l\'adresse', () {
      final r = RestaurantOut.fromJson({
        'streetNumber': '5 bis',
        'streetName': 'avenue de Saxe',
        'postalCode': '69006',
        'city': 'Lyon',
      });

      expect(r.addressString(), '5 bis avenue de Saxe, 69006 Lyon');
    });
  });
}
