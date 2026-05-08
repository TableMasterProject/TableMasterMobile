import 'package:flutter/material.dart';
import 'package:table_master_mobile/core/app_constant.dart';
import 'package:table_master_mobile/features/auth/presentation/login/login_screen.dart';

class SessionManager {
  const SessionManager._();

  static void redirectToLogin() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
