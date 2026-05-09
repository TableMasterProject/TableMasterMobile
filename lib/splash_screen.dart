import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'package:table_master_mobile/core/widgets/table_master_logo.dart';
import 'package:table_master_mobile/features/user/domain/repositories/user_repository.dart';
import 'package:table_master_mobile/features/auth/presentation/login/login_screen.dart';
import 'features/home/presentation/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final storage = const FlutterSecureStorage();
  final userRepo = getIt<IUserRepository>();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Récupérer le token
      String? token = await storage.read(key: 'access_token');
      String? userId = await storage.read(key: 'user_id');

      if (token != null && userId != null) {
        // Charger l'utilisateur depuis l'API
        final user = await userRepo.getUserProfile(int.parse(userId));

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
            (route) => false,
          );
        }
      } else {
        // Aucun token, aller au login
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      // En cas d'erreur, aller au login
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const TableMasterLogo(size: 210),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
