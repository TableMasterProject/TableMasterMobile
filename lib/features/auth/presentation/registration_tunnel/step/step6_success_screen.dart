import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

class Step6SuccessScreen extends StatefulWidget {
  final VoidCallback finish;

  const Step6SuccessScreen({super.key, required this.finish});

  @override
  State<Step6SuccessScreen> createState() => _Step6SuccessScreenState();
}

class _Step6SuccessScreenState extends State<Step6SuccessScreen> {
  late ConfettiController _controllerCenter;

  @override
  void initState() {
    super.initState();
    _controllerCenter = ConfettiController(duration: const Duration(seconds: 10));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 1), () {
        // On vérifie si l'utilisateur est toujours sur l'écran
        if (mounted) {
          _controllerCenter.play(); // marche
        }
      });
    });

  }

  @override
  void dispose() {
    _controllerCenter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Utilisation d'un Stack pour superposer les confettis au-dessus du texte
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 100,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Félicitations !",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Votre compte a été créé avec succès.\nVous pouvez maintenant profiter de toutes les fonctionnalités de TableMaster.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton.icon(
                  onPressed: widget.finish,
                  icon: const Icon(Icons.rocket_launch_rounded),
                  label: const Text(
                    "Commencer l'aventure",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // --- LE CANON À CONFETTIS ---
        ConfettiWidget(
          confettiController: _controllerCenter,
          blastDirectionality: BlastDirectionality.explosive,
          blastDirection: 3.14 / 2, // Tire vers le bas (90 degrés en radians)
          numberOfParticles: 50, // Plus de particules pour bien les voir
          gravity: 0.5,
          shouldLoop: false,
          colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
        ),

      ],
    );
  }
}