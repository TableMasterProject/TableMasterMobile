import '../../data/models/login_token_in.dart';
import '../../data/models/login_user_in.dart';
import '../../data/models/login_user_out.dart';

abstract class IAuthRepository {
  Future<LoginUserOut> login(LoginUserIn credentials);

  Future<LoginUserOut> refresh(LoginTokenIn tokenIn);

  Future<void> logout();

  Future<bool> isAuthenticated();
}
