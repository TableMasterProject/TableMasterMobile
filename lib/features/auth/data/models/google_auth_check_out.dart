import 'login_user_out.dart';

class GoogleAuthCheckOut {
  final bool needsOnboarding;
  final String? googleRegistrationToken;
  final String? email;
  final String? firstName;
  final String? lastName;
  final LoginUserOut? login;

  GoogleAuthCheckOut({
    required this.needsOnboarding,
    this.googleRegistrationToken,
    this.email,
    this.firstName,
    this.lastName,
    this.login,
  });

  factory GoogleAuthCheckOut.fromJson(Map<String, dynamic> json) {
    final hasLogin =
        (json['accessToken'] as String?)?.isNotEmpty == true &&
        (json['refreshToken'] as String?)?.isNotEmpty == true &&
        json['user'] != null;

    return GoogleAuthCheckOut(
      needsOnboarding: json['needsOnboarding'] == true,
      googleRegistrationToken: json['googleRegistrationToken'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      login: hasLogin ? LoginUserOut.fromJson(json) : null,
    );
  }

  GoogleOnboardingData toOnboardingData() {
    return GoogleOnboardingData(
      googleRegistrationToken: googleRegistrationToken ?? '',
      email: email ?? '',
      firstName: firstName ?? '',
      lastName: lastName ?? '',
    );
  }
}

class GoogleOnboardingData {
  final String googleRegistrationToken;
  final String email;
  final String firstName;
  final String lastName;

  const GoogleOnboardingData({
    required this.googleRegistrationToken,
    required this.email,
    required this.firstName,
    required this.lastName,
  });
}
