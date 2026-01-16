class LoginTokenIn {
  String refreshToken;

  LoginTokenIn({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {
      'RefreshToken': refreshToken,
    };
  }
}