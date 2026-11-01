import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'package:table_master_mobile/features/home/presentation/pages/account_page.dart';
import 'package:table_master_mobile/features/user/data/models/user_out.dart';
import 'package:table_master_mobile/features/user/domain/repositories/user_repository.dart';

class _UserRepo extends Mock implements IUserRepository {}

void main() {
  setUp(() {
    getIt.registerSingleton<IUserRepository>(_UserRepo());
  });
  tearDown(() async => getIt.reset());

  testWidgets('le restaurateur trouve ses outils et sorties dans Compte', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: AccountPage(
          user: UserOut(
            id: 1,
            email: 'owner@example.test',
            password: '',
            firstName: 'Resto',
            lastName: 'Test',
            accountType: 1,
            createdAt: DateTime(2024),
          ),
          onLogout: () {},
          onReplayTutorial: () {},
          onOpenPersonalReservations: () => opened = true,
          onOpenRestaurantMenu: () {},
          onOpenRestaurantSettings: () {},
        ),
      ),
    );

    await tester.scrollUntilVisible(find.text('Mes sorties'), 200);
    expect(find.text('Menu du restaurant'), findsOneWidget);
    expect(find.text('Paramètres du restaurant'), findsOneWidget);
    await tester.tap(find.text('Mes sorties'));
    expect(opened, true);
  });
}
