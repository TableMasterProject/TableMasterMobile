import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  final Function(String oldPassword, String newPassword) onConfirm;

  const ChangePasswordScreen({super.key, required this.onConfirm});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return "Le mot de passe est obligatoire";
    if (value.length < 8) return "Il doit contenir au moins 8 caractères";
    if (!RegExp(r'[A-Z]').hasMatch(value)) return "Il faut au moins une majuscule";
    if (!RegExp(r'[0-9]').hasMatch(value)) return "Il faut au moins un chiffre";
    return null;
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
              "Changer de mot de passe",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.onSurface),
            ),
            const SizedBox(height: 32),

            // Ancien mot de passe
            TextFormField(
              controller: _oldPasswordController,
              obscureText: _obscureOld,
              decoration: InputDecoration(
                labelText: "Ancien mot de passe",
                prefixIcon: const Icon(Icons.lock_open),
                suffixIcon: IconButton(
                  icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureOld = !_obscureOld),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) => (value == null || value.isEmpty) ? "Requis" : null,
            ),
            const SizedBox(height: 24),

            // Nouveau mot de passe
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: "Nouveau mot de passe",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: _validateNewPassword,
            ),
            const SizedBox(height: 16),

            // Confirmation
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: "Confirmer le nouveau mot de passe",
                prefixIcon: const Icon(Icons.lock_reset),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value != _newPasswordController.text) return "Les mots de passe ne correspondent pas";
                return null;
              },
            ),

            const SizedBox(height: 24),
            _buildRule("Au moins 8 caractères", _newPasswordController.text.length >= 8),
            _buildRule("Au moins une majuscule", RegExp(r'[A-Z]').hasMatch(_newPasswordController.text)),
            _buildRule("Au moins un chiffre", RegExp(r'[0-9]').hasMatch(_newPasswordController.text)),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onConfirm(_oldPasswordController.text, _newPasswordController.text);
                  }
                },
                child: const Text("Mettre à jour", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRule(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(isMet ? Icons.check_circle : Icons.circle_outlined, size: 16, color: isMet ? Colors.green : Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 13, color: isMet ? Colors.green : Colors.grey)),
        ],
      ),
    );
  }
}
