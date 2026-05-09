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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.primary,
                    colors.primary.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: colors.onPrimary.withValues(alpha: 0.2),
                    child: Text(
                      "${_currentUser.firstName[0].toUpperCase()}${_currentUser.lastName[0].toUpperCase()}",
                      style: textTheme.headlineMedium?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "${_currentUser.firstName} ${_currentUser.lastName}",
                    style: textTheme.headlineSmall?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentUser.email,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.onPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colors.onPrimary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _currentUser.accountType == 0
                          ? "Compte Client"
                          : "Compte Restaurateur",
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Paramètres du profil"),
                  _buildMenuCard([
                    _buildMenuTile(
                      icon: Icons.person_outline,
                      title: "Modifier mes informations",
                      subtitle: "Nom, prénom et email",
                      onTap: () => _navigateToEditProfile(context),
                    ),
                    _buildMenuTile(
                      icon: Icons.lock_outline,
                      title: "Mot de passe",
                      subtitle: "Sécurisez votre accès",
                      onTap: () => _navigateToChangePassword(context),
                    ),
                  ]),

                  const SizedBox(height: 24),
                  _buildSectionTitle("Activités"),
                  _buildMenuCard([
                    _buildMenuTile(
                      icon: Icons.star_outline,
                      title: "Mes Avis",
                      subtitle: "Consulter vos retours d'expérience",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyReviewsPage(),
                          ),
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: 32),
                  _buildSectionTitle("Sécurité"),
                  _buildMenuCard([
                    _buildMenuTile(
                      icon: Icons.logout,
                      title: "Se déconnecter",
                      titleColor: colors.primary,
                      onTap: () => _showLogoutDialog(context),
                    ),
                    _buildMenuTile(
                      icon: Icons.delete_forever_outlined,
                      title: "Supprimer le compte",
                      titleColor: colors.error,
                      showDivider: false,
                      onTap: () => _showDeleteAccountDialog(context),
                    ),
                  ]),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(children: children),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    bool showDivider = true,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: titleColor ?? colors.onSurfaceVariant),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: titleColor ?? colors.onSurface,
            ),
          ),
          subtitle: subtitle != null ? Text(subtitle) : null,
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: colors.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }

  void _navigateToEditProfile(BuildContext context) async {
    final userIn = UserIn(
      email: _currentUser.email,
      firstName: _currentUser.firstName,
      lastName: _currentUser.lastName,
      accountType: _currentUser.accountType,
      password: "",
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              appBar: AppBar(title: const Text("Modifier le profil")),
              body: Step1UserInfoScreen(
                user: userIn,
                onNext: (updatedUser) async {
                  try {
                    await userRepo.updateProfile(updatedUser);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _refreshProfile();
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                  }
                },
              ),
            ),
      ),
    );
  }

  void _navigateToChangePassword(BuildContext context) async {
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
                    if (!context.mounted) return;
                    if (success) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mot de passe mis à jour !'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                  }
                },
              ),
            ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Se déconnecter"),
          content: const Text(
            "Souhaitez-vous vraiment vous déconnecter de votre compte ?",
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
      builder: (BuildContext dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: const Text("Supprimer le compte"),
          content: const Text(
            "Cette action est irréversible. Toutes vos données seront définitivement supprimées.",
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Annuler"),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  final success = await userRepo.deleteAccount();
                  if (!dialogContext.mounted) return;
                  if (success) {
                    Navigator.pop(dialogContext);
                    widget.onLogout();
                  }
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
