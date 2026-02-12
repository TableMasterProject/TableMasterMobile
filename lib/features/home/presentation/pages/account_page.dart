import 'package:flutter/material.dart';
import 'package:table_master_mobile/features/user/data/models/user_out.dart';

class AccountPage extends StatelessWidget {
  final UserOut user;
  final VoidCallback onLogout;

  const AccountPage({super.key, required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * 0.9;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            children: [
              // Informations utilisateur
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow("Prénom", user.firstName, colors),
                      const SizedBox(height: 12),
                      _buildInfoRow("Nom", user.lastName, colors),
                      const SizedBox(height: 12),
                      _buildInfoRow("Email", user.email, colors),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        "Type de compte",
                        user.accountType == 0 ? "Client" : "Restaurant",
                        colors,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Boutons d'action principaux
              Text(
                "Paramètres",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Naviguer vers la page de modification du profil
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Modifier le profil"),
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Naviguer vers la page de changement de mot de passe
                  },
                  icon: const Icon(Icons.lock),
                  label: const Text("Changer le mot de passe"),
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Naviguer vers la page des avis
                  },
                  icon: const Icon(Icons.star_outline),
                  label: const Text("Mes Avis"),
                ),
              ),

              const SizedBox(height: 32),

              // Section dangereuse
              Text(
                "Gestion compte",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.error,
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showDeleteAccountDialog(context);
                  },
                  icon: Icon(Icons.delete_forever, color: colors.error),
                  label: const Text("Supprimer son compte"),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.error),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () {
                    _showLogoutDialog(context);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("Se déconnecter"),
                  style: FilledButton.styleFrom(backgroundColor: colors.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Se déconnecter"),
          content: const Text("Êtes-vous sûr de vouloir vous déconnecter ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                onLogout();
              },
              child: const Text("Se déconnecter"),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteRestaurantDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text("Supprimer le restaurant"),
          content: const Text(
            "Êtes-vous sûr de vouloir supprimer votre restaurant ? Cette action est irréversible.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Appeler la fonction de suppression du restaurant
              },
              style: FilledButton.styleFrom(backgroundColor: colors.tertiary),
              child: const Text("Supprimer"),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text("Supprimer le compte"),
          content: const Text(
            "Êtes-vous sûr de vouloir supprimer votre compte ? Toutes vos données seront perdues et cette action est irréversible.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Appeler la fonction de suppression du compte
              },
              style: FilledButton.styleFrom(backgroundColor: colors.error),
              child: const Text("Supprimer"),
            ),
          ],
        );
      },
    );
  }
}
