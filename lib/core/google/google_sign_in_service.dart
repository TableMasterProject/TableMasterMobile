import 'package:google_sign_in/google_sign_in.dart';

import '../app_config.dart';

class GoogleSignInService {
  static Future<void>? _initialization;

  Future<String?> signInAndGetIdToken() async {
    await _ensureInitialized();

    final account = await GoogleSignIn.instance.authenticate();
    return account.authentication.idToken;
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.signOut();
  }

  Future<void> _ensureInitialized() {
    return _initialization ??= GoogleSignIn.instance.initialize(
      serverClientId:
          AppConfig.googleWebClientId.isEmpty
              ? null
              : AppConfig.googleWebClientId,
    );
  }
}
