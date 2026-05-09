import 'package:flutter/material.dart';

class Step3AccountTypeScreen extends StatelessWidget {
  // On change le type pour passer l'info au parent (true = restaurant, false = client)
  final ValueChanged<int> onSelectType;

  const Step3AccountTypeScreen({super.key, required this.onSelectType});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quel type de compte souhaitez-vous créer ?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Cela nous aidera à personnaliser votre expérience.",
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 32),

          // Carte pour le compte Client
          _buildTypeCard(
            context,
            title: "Je suis un Client",
            description:
                "Je souhaite réserver des tables et consulter les menus.",
            icon: Icons.person_outline,
            onTap: () => onSelectType(0), // Envoie false
          ),

          const SizedBox(height: 16),

          // Carte pour le compte Restaurant
          _buildTypeCard(
            context,
            title: "Je suis un Restaurateur",
            description:
                "Je souhaite gérer mes réservations, mes tables et mon menu.",
            icon: Icons.restaurant,
            onTap: () => onSelectType(1), // Envoie true
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: colors.outlineVariant, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colors.primaryContainer,
              child: Icon(icon, color: colors.onPrimaryContainer, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.primary),
          ],
        ),
      ),
    );
  }
}
