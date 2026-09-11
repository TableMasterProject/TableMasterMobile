import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:table_master_mobile/core/notification_service.dart';
import 'package:table_master_mobile/core/signalr_service.dart';
import 'package:table_master_mobile/core/session/session_service.dart';
import 'package:table_master_mobile/features/auth/data/datasources/auth_datasource.dart';
import 'package:table_master_mobile/features/auth/data/models/login_user_in.dart';
import 'package:table_master_mobile/features/auth/data/models/login_user_out.dart';
import 'package:table_master_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:table_master_mobile/features/user/data/datasources/user_datasource.dart';
import 'package:table_master_mobile/features/user/data/models/user_in.dart';
import 'package:table_master_mobile/features/user/data/repositories/user_repository_impl.dart';
import '../../core/api_client_session_test.dart' show sessionData;

class AuthSource extends Mock implements AuthDataSource {}

class UserSource extends Mock implements UserDataSource {}

class Notifications extends Mock implements NotificationService {}

class SignalR extends Mock implements SignalRService {}

class Credentials extends Fake implements LoginUserIn {}

class Registration extends Fake implements UserIn {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SessionService session;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    session = SessionService();
  });
  tearDown(() async {
    await session.dispose();
  });
  test('inscription stocke jetons et user_id via session', () async {
    final source = UserSource();
    final user = Registration();
    when(
      () => source.addUser(user),
    ).thenAnswer((_) async => LoginUserOut.fromJson(sessionData()));
    final repo = UserRepositoryImpl(source, session: session);
    await repo.register(user);
    expect(await session.accessToken, 'new');
    expect(await session.storage.read(key: 'user_id'), '7');
  });
  test(
    'changement password invalide jetons et coupe temps réel après succès',
    () async {
      await session.storeSessionData(sessionData());
      final source = UserSource();
      var stopped = false;
      session.addTeardown(() async {
        stopped = true;
      });
      when(
        () => source.updatePassword('old', 'new'),
      ).thenAnswer((_) async => true);
      final repo = UserRepositoryImpl(source, session: session);
      expect(await repo.changePassword('old', 'new'), isTrue);
      expect(await session.accessToken, isNull);
      expect(stopped, isTrue);
    },
  );
  test('échec password conserve la session', () async {
    await session.storeSessionData(sessionData());
    final source = UserSource();
    when(
      () => source.updatePassword('old', 'new'),
    ).thenAnswer((_) async => false);
    final repo = UserRepositoryImpl(source, session: session);
    expect(await repo.changePassword('old', 'new'), isFalse);
    expect(await session.accessToken, 'new');
  });
  test('login stocke session avant notification', () async {
    final source = AuthSource();
    final credentials = Credentials();
    final notification = Notifications();
    when(
      () => source.login(credentials),
    ).thenAnswer((_) async => LoginUserOut.fromJson(sessionData()));
    when(() => notification.registerTokenForCurrentUser()).thenAnswer((
      _,
    ) async {
      expect(await session.accessToken, 'new');
    });
    final repo = AuthRepositoryImpl(
      source,
      notification,
      SignalR(),
      session: session,
    );
    await repo.login(credentials);
    expect(await session.storage.read(key: 'user_id'), '7');
  });
}
