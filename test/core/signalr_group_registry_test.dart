import 'package:flutter_test/flutter_test.dart';
import 'package:table_master_mobile/core/signalr_group_registry.dart';

void main() {
  late SignalRGroupRegistry registry;

  setUp(() {
    registry = SignalRGroupRegistry();
  });

  group('SignalRGroupRegistry', () {
    test('la première adhésion demande un Join côté serveur', () {
      expect(registry.acquire('restaurant_12'), isTrue);
      expect(registry.refCountOf('restaurant_12'), 1);
    });

    test('une adhésion supplémentaire ne redemande pas de Join', () {
      registry.acquire('restaurant_12');

      expect(registry.acquire('restaurant_12'), isFalse);
      expect(registry.refCountOf('restaurant_12'), 2);
    });

    test(
      'la libération partielle ne quitte pas le groupe tant qu\'un écran en dépend',
      () {
        registry.acquire('restaurant_12');
        registry.acquire('restaurant_12');

        expect(registry.release('restaurant_12'), isFalse);
        expect(registry.contains('restaurant_12'), isTrue);
        expect(registry.refCountOf('restaurant_12'), 1);
      },
    );

    test('la dernière libération demande un Leave et oublie le groupe', () {
      registry.acquire('restaurant_12');
      registry.acquire('restaurant_12');
      registry.release('restaurant_12');

      expect(registry.release('restaurant_12'), isTrue);
      expect(registry.contains('restaurant_12'), isFalse);
      expect(registry.refCountOf('restaurant_12'), 0);
    });

    test('libérer un groupe inconnu ne demande aucun Leave', () {
      expect(registry.release('restaurant_99'), isFalse);
    });

    test('activeGroups restitue tous les groupes à re-rejoindre', () {
      registry.acquire('restaurant_12');
      registry.acquire('restaurant_12');
      registry.acquire('user_7');

      expect(registry.activeGroups, containsAll(['restaurant_12', 'user_7']));
      expect(registry.activeGroups, hasLength(2));
    });

    test('un groupe totalement libéré n\'est plus re-rejoint', () {
      registry.acquire('restaurant_12');
      registry.acquire('user_7');
      registry.release('user_7');

      expect(registry.activeGroups, ['restaurant_12']);
    });

    test('clear oublie toutes les adhésions (déconnexion)', () {
      registry.acquire('restaurant_12');
      registry.acquire('user_7');

      registry.clear();

      expect(registry.activeGroups, isEmpty);
    });

    test('activeGroups est une vue non modifiable', () {
      registry.acquire('restaurant_12');

      expect(
        () => registry.activeGroups.add('restaurant_99'),
        throwsUnsupportedError,
      );
    });
  });
}
