import 'package:flutter/material.dart';

import 'features/login/presentation/LoginPage.dart';

class AppConfig {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://localhost:8080', // Fallback
  );

  static const bool isProd = bool.fromEnvironment('IS_PROD');
  static const String appName = String.fromEnvironment('APP_NAME');
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F51B5),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F51B5),
          brightness: Brightness.dark,
        ),
      ),

      themeMode: ThemeMode.system,

      home: const LoginPage(),
    );
  }
}
