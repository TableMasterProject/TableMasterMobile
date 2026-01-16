import 'package:flutter/material.dart';
import 'package:table_master_mobile/core/models/user_in.dart';

class Step1UserInfoScreen extends StatefulWidget {
  final Function(UserIn user) onNext;

  final UserIn user;

  const Step1UserInfoScreen({super.key, required this.onNext, required this.user});

  @override
  State<Step1UserInfoScreen> createState() => _Step1UserInfoScreenState();
}

class _Step1UserInfoScreenState extends State<Step1UserInfoScreen> {
  // Clé pour gérer la validation du formulaire
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.user.firstName;
    _lastNameController.text = widget.user.lastName;
    _emailController.text = widget.user.email;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Informations personnelles",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Veuillez renseigner vos informations pour créer votre profil.",
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 32),

            // Champ Prénom
            TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: "Prénom",
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Veuillez entrer votre prénom";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Champ Nom
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: "Nom",
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Veuillez entrer votre nom";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Champ Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "L'email est obligatoire";
                }
                // Regex simple pour valider l'email
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value)) {
                  return "Veuillez entrer un email valide";
                }
                return null;
              },
            ),
            const SizedBox(height: 40),

            // Bouton Continuer
            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton(
                onPressed: () {
                  // On valide le formulaire avant de passer à la suite
                  if (_formKey.currentState!.validate()) {
                    final user = widget.user.copyWith(
                      email: _emailController.text.trim(),
                      firstName: _firstNameController.text.trim(),
                      lastName: _lastNameController.text.trim()
                    );
                    widget.onNext(user);
                  }
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Continuer", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}