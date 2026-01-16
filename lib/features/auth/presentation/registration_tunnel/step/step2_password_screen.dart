import 'package:flutter/material.dart';

class Step2PasswordScreen extends StatefulWidget {
  final Function(String password) onNext;
  final String password;

  const Step2PasswordScreen({super.key, required this.onNext, required this.password});

  @override
  State<Step2PasswordScreen> createState() => _Step2PasswordScreenState();
}

class _Step2PasswordScreenState extends State<Step2PasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour comparer les deux mots de passe
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  // Pour afficher/masquer le mot de passe
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _passwordController.text = widget.password;
    _confirmController.text = widget.password;
    _passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
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
              "Sécurité du compte",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              "Choisissez un mot de passe robuste pour protéger votre accès.",
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 32),

            // Champ Mot de passe
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: "Mot de passe",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return "Le mot de passe est obligatoire";
                if (value.length < 8) return "Il doit contenir au moins 8 caractères";
                if (!RegExp(r'[A-Z]').hasMatch(value)) return "Il faut au moins une majuscule";
                if (!RegExp(r'[0-9]').hasMatch(value)) return "Il faut au moins un chiffre";
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Champ Confirmation
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: "Confirmer le mot de passe",
                prefixIcon: const Icon(Icons.lock_reset),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return "Veuillez confirmer votre mot de passe";
                if (value != _passwordController.text) return "Les mots de passe ne correspondent pas";
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Rappel des règles (UX)
            _buildRule("Au moins 8 caractères", _passwordController.text.length >= 8),
            _buildRule("Au moins une majuscule", RegExp(r'[A-Z]').hasMatch(_passwordController.text)),
            _buildRule("Au moins un chiffre", RegExp(r'[0-9]').hasMatch(_passwordController.text)),

            const SizedBox(height: 40),

            // Bouton Continuer
            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onNext(_passwordController.text.trim());
                  }
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Continuer", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Petit widget pour afficher les règles de sécurité en temps réel
  Widget _buildRule(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isMet ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}