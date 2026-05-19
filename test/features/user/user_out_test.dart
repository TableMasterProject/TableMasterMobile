import 'package:flutter_test/flutter_test.dart';
import 'package:table_master_mobile/features/user/data/models/user_in.dart';
import 'package:table_master_mobile/features/user/data/models/user_out.dart';

void main() {
  group('UserOut.fromJson', () {
    test('parse un utilisateur complet', () {
      final u = UserOut.fromJson({
        'id': 7,
        'email': 'lea@example.com',
        'firstName': 'Léa',
        'lastName': 'Martin',
        'accountType': 0,
        'createdAt': '2026-03-01T12:00:00.000Z',
        'restaurantId': 3,
      });

      expect(u.id, 7);
      expect(u.email, 'lea@example.com');
      expect(u.firstName, 'Léa');
      expect(u.restaurantId, 3);
      expect(u, isA<UserIn>());
    });

    test("ne désérialise jamais le mot de passe depuis l'API", () {
      final u = UserOut.fromJson({
        'id': 1,
        'email': 'a@b.c',
        'firstName': 'A',
        'lastName': 'B',
        'accountType': 1,
      });

      // Côté API on ne renvoie jamais le hash — la valeur reste vide.
      expect(u.password, '');
    });

    test('replie sur valeurs neutres en cas de champs manquants', () {
      final u = UserOut.fromJson({});

      expect(u.id, 0);
      expect(u.email, '');
      expect(u.accountType, 0);
      expect(u.restaurantId, isNull);
    });
  });
}
