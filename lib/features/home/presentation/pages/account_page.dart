import 'package:flutter/material.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/change_password_screen.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step1_user_info_screen.dart';
import 'package:table_master_mobile/features/user/data/models/user_in.dart';
import 'package:table_master_mobile/features/user/data/models/user_out.dart';
import 'package:table_master_mobile/features/user/domain/repositories/user_repository.dart';
import 'package:table_master_mobile/features/review/presentation/pages/my_reviews_page.dart';

class AccountPage extends StatefulWidget {
  final UserOut user;
  final VoidCallback onLogout;

  const AccountPage({super.key, required this.user, required this.onLogout});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final userRepo = getIt<IUserRepository>();
  late UserOut _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  Future<void> _refreshProfile() async {
    try {
      final updated = await userRepo.getUserProfile(_currentUser.id);
      setState(() => _currentUser = updated);
    } catch (e) {
      // ignore
    }
  }

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
                      _buildInfoRow("Prénom", _currentUser.firstName, colors),
                      const SizedBox(height: 12),
                      _buildInfoRow("Nom", _currentUser.lastName, colors),
                      const SizedBox(height: 12),
                      _buildInfoRow("Email", _currentUser.email, colors),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        "Type de compte",
                        _currentUser.accountType == 0 ? "Client" : "Restaurant",
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

              _buildSettingsButton(
                context,
                "Modifier le profil",
                Icons.edit,
                () async {
                  final userIn = UserIn(
                    email: _currentUser.email,
                    firstName: _currentUser.firstName,
                    lastName: _currentUser.lastName,
                    accountType: _currentUser.accountType,
                    password: "", // Not used for update
                  );

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => Scaffold(
                            appBar: AppBar(
                              title: const Text("Modifier le profil"),
                            ),
                            body: Step1UserInfoScreen(
                              user: userIn,
                              onNext: (updatedUser) async {
                                try {
                                  await userRepo.updateProfile(updatedUser);
                                  Navigator.pop(context);
                                  _refreshProfile();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Erreur: $e')),
                                  );
                                }
                              },
                            ),
                          ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              _buildSettingsButton(
                context,
                "Changer le mot de passe",
                Icons.lock,
                () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => Scaffold(
                            appBar: AppBar(title: const Text("Mot de passe")),
                            body: ChangePasswordScreen(
                              onConfirm: (oldPwd, newPwd) async {
                                try {
                                  final success = await userRepo.changePassword(
                                    oldPwd,
                                    newPwd,
                                  );
                                  if (success) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Mot de passe mis à jour !',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Erreur: $e')),
                                  );
                                }
                              },
                            ),
                          ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              _buildSettingsButton(context, "Mes Avis", Icons.star_outline, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyReviewsPage(),
                  ),
                );
              }),

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

  Widget _buildSettingsButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
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
                widget.onLogout();
              },
              child: const Text("Se déconnecter"),
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
              onPressed: () async {
                try {
                  final success = await userRepo.deleteAccount();
                  if (success) {
                    Navigator.pop(context);
                    widget.onLogout();
                  }
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la suppression: $e'),
                    ),
                  );
                }
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
