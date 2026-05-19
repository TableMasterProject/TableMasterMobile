import 'package:flutter_test/flutter_test.dart';
import 'package:table_master_mobile/features/auth/data/models/login_user_out.dart';

void main() {
  group('LoginUserOut.fromJson', () {
    test('parse une réponse API complète', () {
      final json = {
        'accessToken': 'eyJhbGciOiJIUzI1NiJ9.access',
        'refreshToken': 'eyJhbGciOiJIUzI1NiJ9.refresh',
        'user': {
          'id': 42,
          'email': 'lea@example.com',
          'firstName': 'Léa',
          'lastName': 'Martin',
          'accountType': 0,
          'createdAt': '2026-05-19T10:00:00.000Z',
        },
      };

      final out = LoginUserOut.fromJson(json);

      expect(out.accessToken, 'eyJhbGciOiJIUzI1NiJ9.access');
      expect(out.refreshToken, 'eyJhbGciOiJIUzI1NiJ9.refresh');
      expect(out.user.id, 42);
      expect(out.user.email, 'lea@example.com');
      expect(out.user.firstName, 'Léa');
      expect(out.user.accountType, 0);
    });

    test('tolère des tokens absents en repliant sur chaîne vide', () {
      final json = {
        'user': {
          'id': 1,
          'email': 'x@y.z',
          'firstName': 'X',
          'lastName': 'Y',
          'accountType': 1,
        },
      };

      final out = LoginUserOut.fromJson(json);

      expect(out.accessToken, '');
      expect(out.refreshToken, '');
      expect(out.user.accountType, 1);
    });

    test('le mot de passe utilisateur n\'est jamais reçu', () {
      final out = LoginUserOut.fromJson({
        'accessToken': 'a',
        'refreshToken': 'r',
        'user': {
          'id': 1,
          'email': 'x@y.z',
          'firstName': 'X',
          'lastName': 'Y',
          'accountType': 0,
          // pas de mot de passe côté JSON
        },
      });

      // Sécurité : le password n'est jamais désérialisé depuis l'API.
      expect(out.user.password, '');
    });
  });
}
