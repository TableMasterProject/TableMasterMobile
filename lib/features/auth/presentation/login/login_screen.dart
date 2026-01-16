import 'package:flutter/material.dart';
import '../../../../core/app_config.dart';
import '../../../../core/injection.dart';
import '../../data/models/login_user_in.dart';
import '../../domain/repositories/auth_repository.dart';
import '../registration_tunnel/registration_stepper_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. Contrôleurs pour récupérer le texte
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 2. Gestion de l'état
  bool _isLoading = false;
  final _authRepo = getIt<IAuthRepository>();

  // 3. Fonction de connexion
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Appel du repository avec le modèle LoginUserIn
      final credentials = LoginUserIn(email: email, password: password);
      final result = await _authRepo.login(credentials);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bienvenue ${result.user.firstName} !")),
        );
        // TODO: Rediriger vers l'accueil (ex: Navigator.pushReplacement)
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppConfig.appName,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colors.primary),
              ),
              const SizedBox(height: 20),
              Icon(Icons.lock_outline, size: 80, color: colors.primary),
              const SizedBox(height: 20),
              Text(
                "Bienvenue",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colors.onSurface),
              ),
              const SizedBox(height: 8),
              Text("Connectez-vous pour continuer", style: TextStyle(color: colors.onSurfaceVariant)),
              const SizedBox(height: 40),

              // Champ Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Champ Password
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Mot de passe",
                  prefixIcon: const Icon(Icons.password_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // Bouton Login
              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Se connecter", style: TextStyle(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 16),
              TextButton(onPressed: () {}, child: const Text("Mot de passe oublié ?")),
              const SizedBox(height: 10),

              // Bouton Créer un compte
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistrationStepperScreen()));
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Créer un compte", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}