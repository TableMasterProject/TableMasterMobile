import 'package:flutter/material.dart';

class Step6ErrorScreen extends StatefulWidget {
  final VoidCallback onRetry;
  final String? errorMessage;

  const Step6ErrorScreen({super.key, required this.onRetry, this.errorMessage});

  @override
  State<Step6ErrorScreen> createState() => _Step6ErrorScreenState();
}

class _Step6ErrorScreenState extends State<Step6ErrorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Lance une petite animation de secousse à l'ouverture
    _shakeController.forward();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Animation de secousse sur l'icône
          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final sineValue =
                  (1.0 - _shakeController.value) *
                  10 *
                  (0.5 - _shakeController.value).abs();
              return Transform.translate(
                offset: Offset(sineValue * 5, 0),
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: colors.error,
                size: 100,
              ),
            ),
          ),

          const SizedBox(height: 32),

          Text(
            "Oups ! Une erreur est survenue",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            widget.errorMessage ??
                "Nous n'avons pas pu finaliser votre inscription. Veuillez vérifier votre connexion ou réessayer plus tard.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),

          const Spacer(),

          // Bouton Réessayer
          SizedBox(
            width: double.infinity,
            height: 55,
            child: FilledButton.icon(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                "Réessayer",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Bouton Annuler / Retour
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Retourner à l'accueil",
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
