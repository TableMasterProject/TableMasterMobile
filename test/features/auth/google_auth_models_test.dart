import 'package:flutter_test/flutter_test.dart';
import 'package:table_master_mobile/features/auth/data/models/google_auth_check_out.dart';
import 'package:table_master_mobile/features/auth/data/models/google_register_in.dart';
import 'package:table_master_mobile/features/user/data/models/user_in.dart';

void main() {
  group('GoogleAuthCheckOut.fromJson', () {
    test('parse une réponse de compte Google existant avec tokens', () {
      final out = GoogleAuthCheckOut.fromJson({
        'needsOnboarding': false,
        'accessToken': 'access',
        'refreshToken': 'refresh',
        'user': {
          'id': 42,
          'email': 'google@example.com',
          'firstName': 'Go',
          'lastName': 'Ogle',
          'accountType': 0,
          'authProvider': 'Google',
        },
      });

      expect(out.needsOnboarding, isFalse);
      expect(out.login, isNotNull);
      expect(out.login!.accessToken, 'access');
      expect(out.login!.user.authProvider, 'Google');
    });

    test('parse une réponse onboarding Google', () {
      final out = GoogleAuthCheckOut.fromJson({
        'needsOnboarding': true,
        'googleRegistrationToken': 'temporary-token',
        'email': 'new@example.com',
        'firstName': 'New',
        'lastName': 'User',
      });

      final onboarding = out.toOnboardingData();

      expect(out.login, isNull);
      expect(onboarding.googleRegistrationToken, 'temporary-token');
      expect(onboarding.email, 'new@example.com');
      expect(onboarding.firstName, 'New');
    });
  });

  group('GoogleRegisterIn.toJson', () {
    test('envoie uniquement les champs attendus par l API', () {
      final model = GoogleRegisterIn(
        googleRegistrationToken: 'temporary-token',
        user: UserIn(
          email: 'new@example.com',
          password: '',
          firstName: 'New',
          lastName: 'User',
          accountType: 1,
        ),
      );

      expect(model.toJson(), {
        'GoogleRegistrationToken': 'temporary-token',
        'Email': 'new@example.com',
        'FirstName': 'New',
        'LastName': 'User',
        'AccountType': 1,
      });
    });
  });
}
