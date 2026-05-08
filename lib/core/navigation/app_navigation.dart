import 'package:flutter/material.dart';

class AppNavigation {
  const AppNavigation._();

  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  static Future<T?> pushReplacement<T, TO>(
    BuildContext context,
    Widget page, {
    TO? result,
  }) {
    return Navigator.of(context).pushReplacement<T, TO>(
      MaterialPageRoute(builder: (_) => page),
      result: result,
    );
  }

  static void replaceAll(BuildContext context, Widget page) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }
}

