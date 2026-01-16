import 'package:flutter/material.dart';

import 'core/app_config.dart';
import 'core/injection.dart';
import 'features/auth/presentation/login/login_screen.dart';



void main() {
  WidgetsFlutterBinding.ensureInitialized();

  setupDependencies();

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

      home: const LoginScreen(),
    );
  }
}
