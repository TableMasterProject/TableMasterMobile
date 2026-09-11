import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:table_master_mobile/core/session/session_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:table_master_mobile/features/user/data/datasources/user_datasource.dart';
import 'package:table_master_mobile/features/user/data/models/user_in.dart';
import 'package:table_master_mobile/features/user/data/models/user_out.dart';
import 'package:table_master_mobile/features/user/data/repositories/user_repository_impl.dart';

class _MockUserDataSource extends Mock implements UserDataSource {}

class _FakeUserIn extends Fake implements UserIn {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _MockUserDataSource dataSource;
  late UserRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(_FakeUserIn());
  });

  setUp(() {
    dataSource = _MockUserDataSource();
    FlutterSecureStorage.setMockInitialValues({});
    repository = UserRepositoryImpl(dataSource, session: SessionService());
  });

  UserOut buildUser({int id = 1}) => UserOut(
    id: id,
    email: 'lea@example.com',
    password: '',
    firstName: 'Léa',
    lastName: 'Martin',
    accountType: 0,
    createdAt: DateTime(2026, 1, 1),
  );

  group('UserRepositoryImpl', () {
    test(
      'getUserProfile renvoie l\'utilisateur depuis le datasource',
      () async {
        when(
          () => dataSource.getUserById(7),
        ).thenAnswer((_) async => buildUser(id: 7));

        final u = await repository.getUserProfile(7);

        expect(u.id, 7);
        expect(u.firstName, 'Léa');
        verify(() => dataSource.getUserById(7)).called(1);
      },
    );

    test('updateProfile délègue la mise à jour au datasource', () async {
      when(
        () => dataSource.updateUser(any()),
      ).thenAnswer((_) async => buildUser());

      final u = await repository.updateProfile(_FakeUserIn());

      expect(u.email, 'lea@example.com');
      verify(() => dataSource.updateUser(any())).called(1);
    });

    test('changePassword passe ancien et nouveau mot de passe', () async {
      when(
        () => dataSource.updatePassword('old', 'new'),
      ).thenAnswer((_) async => true);

      final ok = await repository.changePassword('old', 'new');

      expect(ok, isTrue);
      verify(() => dataSource.updatePassword('old', 'new')).called(1);
    });

    test('deleteAccount renvoie le booléen du datasource', () async {
      when(() => dataSource.deleteUser()).thenAnswer((_) async => true);

      final ok = await repository.deleteAccount();

      expect(ok, isTrue);
    });

    test('propage les erreurs du datasource', () async {
      when(() => dataSource.getUserById(any())).thenThrow(Exception('404'));

      expect(() => repository.getUserProfile(0), throwsException);
    });
  });
}
