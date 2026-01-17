import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/app_config.dart';
import 'core/app_constant.dart';
import 'core/injection.dart';
import 'features/auth/presentation/login/login_screen.dart';
import 'features/home/presentation/home_screen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupDependencies();

  const storage = FlutterSecureStorage();
  String? token = await storage.read(key: 'access_token');

  Widget initialScreen = (token != null) ? const HomeScreen() : const LoginScreen();

  runApp(MyApp(initialScreen: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});

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
      navigatorKey: navigatorKey,
      home: initialScreen,
    );
  }
}
