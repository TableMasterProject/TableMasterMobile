import '../../../auth/data/models/login_user_out.dart';
import '../../data/models/user_in.dart';
import '../../data/models/user_out.dart';

abstract class IUserRepository {
  Future<UserOut> getUserProfile(int id);
  Future<LoginUserOut> register(UserIn user);
  Future<UserOut> updateProfile(UserIn user);
  Future<bool> changePassword(String oldPassword, String newPassword);
  Future<bool> deleteAccount();
}
