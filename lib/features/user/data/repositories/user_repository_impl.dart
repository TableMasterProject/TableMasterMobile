import 'package:table_master_mobile/core/session/session_service.dart';
import 'package:table_master_mobile/features/auth/data/models/login_user_out.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_datasource.dart';
import '../models/user_in.dart';
import '../models/user_out.dart';

class UserRepositoryImpl implements IUserRepository {
  final UserDataSource remoteDataSource;
  final SessionService? _session;
  SessionService get session => _session ?? remoteDataSource.apiClient.session;
  UserRepositoryImpl(this.remoteDataSource, {SessionService? session})
    : _session = session;

  @override
  Future<UserOut> getUserProfile(int id) => remoteDataSource.getUserById(id);
  @override
  Future<LoginUserOut> register(UserIn user) async {
    final result = await remoteDataSource.addUser(user);
    await session.storeSession(result);
    return result;
  }

  @override
  Future<UserOut> updateProfile(UserIn user) =>
      remoteDataSource.updateUser(user);
  @override
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    final changed = await remoteDataSource.updatePassword(
      oldPassword,
      newPassword,
    );
    if (changed) await session.clear();
    return changed;
  }

  @override
  Future<bool> deleteAccount() async {
    final deleted = await remoteDataSource.deleteUser();
    if (deleted) await session.clear();
    return deleted;
  }
}
