import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:table_master_mobile/features/auth/data/models/login_user_out.dart';

import '../../domain/repositories/user_repository.dart';
import '../datasources/user_datasource.dart';
import '../models/user_in.dart';
import '../models/user_out.dart';

class UserRepositoryImpl implements IUserRepository {
  final UserDataSource remoteDataSource;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  UserRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserOut> getUserProfile(int id) async {
    return await remoteDataSource.getUserById(id);
  }

  @override
  Future<LoginUserOut> register(UserIn user) async {
    final result = await remoteDataSource.addUser(user);

    await _saveTokens(result.accessToken, result.refreshToken);

    return result;
  }

  @override
  Future<UserOut> updateProfile(UserIn user) async {
    return await remoteDataSource.updateUser(user);
  }

  @override
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    return await remoteDataSource.updatePassword(oldPassword, newPassword);
  }

  @override
  Future<bool> deleteAccount() async {
    return await remoteDataSource.deleteUser();
  }

  Future<void> _saveTokens(String access, String refresh) async {
    await storage.write(key: 'access_token', value: access);
    await storage.write(key: 'refresh_token', value: refresh);
  }
}
