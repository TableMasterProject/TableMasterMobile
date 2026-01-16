import '../../../user/data/models/user_out.dart';

class LoginUserOut {
  String accessToken;
  String refreshToken;
  UserOut user;

  LoginUserOut({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginUserOut.fromJson(Map<String, dynamic> json) {
    return LoginUserOut(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      user: UserOut.fromJson(json['user']),
    );
  }
}