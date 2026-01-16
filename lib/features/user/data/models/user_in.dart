class UserIn {
  String email;
  String password;
  String firstName;
  String lastName;
  int accountType;

  UserIn({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.accountType,
  });

  // Conversion pour l'envoi vers ton API ASP.NET
  Map<String, dynamic> toJson() {
    return {
      'Email': email,
      'Password': password,
      'FirstName': firstName,
      'LastName': lastName,
      'AccountType': accountType,
    };
  }

  // Méthode copyWith pour UserIn
  UserIn copyWith({
    String? email,
    String? password,
    String? firstName,
    String? lastName,
    int? accountType,
  }) {
    return UserIn(
      email: email ?? this.email,
      password: password ?? this.password,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      accountType: accountType ?? this.accountType,
    );
  }
}