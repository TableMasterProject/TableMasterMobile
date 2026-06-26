import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:table_master_mobile/core/notification_service.dart';
import 'package:table_master_mobile/features/auth/data/datasources/auth_datasource.dart';
import 'package:table_master_mobile/features/auth/data/repositories/auth_repository_impl.dart';

class _MockAuthDataSource extends Mock implements AuthDataSource {}

class _MockNotificationService extends Mock implements NotificationService {}

void main() {
  late _MockAuthDataSource dataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    dataSource = _MockAuthDataSource();
    repository = AuthRepositoryImpl(dataSource, _MockNotificationService());
  });

  group('AuthRepositoryImpl', () {
    test('forgotPassword délègue au datasource', () async {
      when(
        () => dataSource.forgotPassword('lea@example.com'),
      ).thenAnswer((_) async {});

      await repository.forgotPassword('lea@example.com');

      verify(() => dataSource.forgotPassword('lea@example.com')).called(1);
    });

    test('resetPassword délègue au datasource', () async {
      when(
        () => dataSource.resetPassword('token', 'NewPassword!2'),
      ).thenAnswer((_) async {});

      await repository.resetPassword('token', 'NewPassword!2');

      verify(
        () => dataSource.resetPassword('token', 'NewPassword!2'),
      ).called(1);
    });
  });
}
