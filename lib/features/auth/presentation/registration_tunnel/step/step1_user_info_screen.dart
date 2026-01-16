import 'package:flutter/material.dart';

class Step1UserInfoScreen extends StatefulWidget {
  final VoidCallback onNext;

  const Step1UserInfoScreen({super.key, required this.onNext});

  @override
  State<Step1UserInfoScreen> createState() => _Step1UserInfoScreenState();
}

class _Step1UserInfoScreenState extends State<Step1UserInfoScreen> {
  // Clé pour gérer la validation du formulaire
  final _formKey = GlobalKey<FormState>();

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
                    widget.onNext();
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