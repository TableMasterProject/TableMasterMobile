class LoginUserIn {
  String email;
  String password;

  LoginUserIn({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'Email': email,
      'Password': password,
    };
  }
}