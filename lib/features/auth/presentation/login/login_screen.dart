import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:table_master_mobile/core/google/google_sign_in_service.dart';
import 'package:table_master_mobile/core/responsive/breakpoints.dart';
import 'package:table_master_mobile/core/widgets/table_master_logo.dart';
import 'package:table_master_mobile/features/home/presentation/home_screen.dart';
import '../../../../core/injection.dart';
import '../../data/models/login_user_in.dart';
import '../../data/models/login_user_out.dart';
import '../../domain/repositories/auth_repository.dart';
import '../registration_tunnel/registration_stepper_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  final _authRepo = getIt<IAuthRepository>();
  final _googleSignInService = GoogleSignInService();

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
      final credentials = LoginUserIn(email: email, password: password);
      LoginUserOut result = await _authRepo.login(credentials);

      if (mounted) {
        _openHome(result);
      }
    } catch (e) {
      if (mounted) {
        _showError(e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);

    try {
      final idToken = await _googleSignInService.signInAndGetIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception("Token Google indisponible");
      }

      final result = await _authRepo.checkGoogle(idToken);
      final login = result.login;

      if (!mounted) return;
      if (!result.needsOnboarding && login != null) {
        _openHome(login);
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => RegistrationStepperScreen(
                googleOnboarding: result.toOnboardingData(),
                onCompleted: _openHome,
              ),
        ),
      );
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled && mounted) {
        _showError(e);
      }
    } catch (e) {
      if (mounted) {
        _showError(e);
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _openHome(LoginUserOut result) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => HomeScreen(user: result.user)),
      (route) => false,
    );
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Erreur : ${error.toString()}"),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final showSidePanel = context.isDesktop;

    final form = _LoginForm(
      colors: colors,
      isLoading: _isLoading,
      isGoogleLoading: _isGoogleLoading,
      emailController: _emailController,
      passwordController: _passwordController,
      onLogin: _handleLogin,
      onGoogleLogin: _handleGoogleLogin,
      onRegister: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RegistrationStepperScreen(),
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child:
            showSidePanel
                ? Row(
                  children: [
                    Expanded(child: _SidePanel(colors: colors)),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: Breakpoints.maxFormWidth,
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: form,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: Breakpoints.maxFormWidth,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: form,
                    ),
                  ),
                ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final ColorScheme colors;
  final bool isLoading;
  final bool isGoogleLoading;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;
  final VoidCallback onGoogleLogin;
  final VoidCallback onRegister;

  const _LoginForm({
    required this.colors,
    required this.isLoading,
    required this.isGoogleLoading,
    required this.emailController,
    required this.passwordController,
    required this.onLogin,
    required this.onGoogleLogin,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: TableMasterLogo(size: 160)),
        const SizedBox(height: 28),
        Text(
          "Bienvenue",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Connectez-vous pour continuer",
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: "Email",
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => onLogin(),
          decoration: const InputDecoration(
            labelText: "Mot de passe",
            prefixIcon: Icon(Icons.password_rounded),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: isLoading || isGoogleLoading ? null : onLogin,
            child:
                isLoading
                    ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                    : const Text(
                      "Se connecter",
                      style: TextStyle(fontSize: 16),
                    ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: isLoading || isGoogleLoading ? null : onGoogleLogin,
            icon:
                isGoogleLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                    : const Icon(Icons.g_mobiledata_rounded, size: 30),
            label: const Text(
              "Continuer avec Google",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: isLoading || isGoogleLoading ? null : () {},
          child: const Text("Mot de passe oublié ?"),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: isLoading || isGoogleLoading ? null : onRegister,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.primary),
            ),
            child: const Text(
              "Créer un compte",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _SidePanel extends StatelessWidget {
  final ColorScheme colors;
  const _SidePanel({required this.colors});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.primaryContainer],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: 72,
              color: colors.onPrimary,
            ),
            const SizedBox(height: 32),
            Text(
              "Table Master",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: colors.onPrimary,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Réservez vos tables. Gérez votre salle.\nLe tout depuis une seule interface.",
              style: TextStyle(
                fontSize: 18,
                color: colors.onPrimary.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
