import '../../../user/data/models/user_in.dart';

class GoogleRegisterIn {
  final String googleRegistrationToken;
  final UserIn user;

  const GoogleRegisterIn({
    required this.googleRegistrationToken,
    required this.user,
  });

  Map<String, dynamic> toJson() {
    return {
      'GoogleRegistrationToken': googleRegistrationToken,
      'Email': user.email,
      'FirstName': user.firstName,
      'LastName': user.lastName,
      'AccountType': user.accountType,
    };
  }
}
