import '../../data/models/google_auth_check_out.dart';
import '../../data/models/google_register_in.dart';
import '../../data/models/login_token_in.dart';
import '../../data/models/login_user_in.dart';
import '../../data/models/login_user_out.dart';

abstract class IAuthRepository {
  Future<LoginUserOut> login(LoginUserIn credentials);

  Future<LoginUserOut> refresh(LoginTokenIn tokenIn);

  Future<GoogleAuthCheckOut> checkGoogle(String idToken);

  Future<LoginUserOut> registerGoogle(GoogleRegisterIn model);

  Future<void> logout();

  Future<bool> isAuthenticated();
}
