import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/user/data/models/user_out.dart';

class TutorialService {
  static const int clientTutorialVersion = 1;
  static const int restaurantTutorialVersion = 1;

  final FlutterSecureStorage _storage;

  const TutorialService([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  Future<bool> shouldShowHomeTutorial(UserOut user) async {
    final seen = await _storage.read(key: _storageKey(user));
    return seen != 'true';
  }

  Future<void> markHomeTutorialSeen(UserOut user) {
    return _storage.write(key: _storageKey(user), value: 'true');
  }

  String _storageKey(UserOut user) {
    final role = user.accountType == 1 ? 'restaurant' : 'client';
    final version =
        user.accountType == 1
            ? restaurantTutorialVersion
            : clientTutorialVersion;

    return 'tutorial_seen_user_${user.id}_${role}_v$version';
  }
}
