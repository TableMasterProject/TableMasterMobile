import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:table_master_mobile/core/notification_deduplicator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'eventId déjà affiché reste dédupliqué après nouvelle instance',
    () async {
      var shown = 0;
      await NotificationDeduplicator().showOnce('event-1', () async {
        shown++;
      });
      await NotificationDeduplicator().showOnce('event-1', () async {
        shown++;
      });
      expect(shown, 1);
    },
  );
  test('deux livraisons simultanées affichent une seule fois', () async {
    var shown = 0;
    await Future.wait(
      List.generate(
        2,
        (_) => NotificationDeduplicator().showOnce('event-2', () async {
          shown++;
        }),
      ),
    );
    expect(shown, 1);
  });
  test('échec affichage autorise la prochaine livraison', () async {
    final dedup = NotificationDeduplicator();
    var shown = 0;
    await expectLater(
      dedup.showOnce('event-3', () async {
        throw StateError('display failed');
      }),
      throwsStateError,
    );
    await dedup.showOnce('event-3', () async {
      shown++;
    });
    expect(shown, 1);
  });
  test('sans eventId les messages restent affichables', () async {
    final dedup = NotificationDeduplicator();
    var shown = 0;
    await dedup.showOnce(null, () async {
      shown++;
    });
    await dedup.showOnce(null, () async {
      shown++;
    });
    expect(shown, 2);
  });
  test('identifiant OS stable entre livraisons et instances', () {
    expect(
      NotificationDeduplicator.notificationId('event-1'),
      NotificationDeduplicator.notificationId('event-1'),
    );
    expect(
      NotificationDeduplicator.notificationId('event-1'),
      isNot(NotificationDeduplicator.notificationId('event-2')),
    );
  });
}
