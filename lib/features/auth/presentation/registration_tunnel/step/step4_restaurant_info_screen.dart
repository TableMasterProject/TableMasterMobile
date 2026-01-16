import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Step4RestaurantInfoScreen extends StatefulWidget {
  final VoidCallback onNext;

  const Step4RestaurantInfoScreen({super.key, required this.onNext});

  @override
  State<Step4RestaurantInfoScreen> createState() => _Step4RestaurantInfoScreenState();
}

class _Step4RestaurantInfoScreenState extends State<Step4RestaurantInfoScreen> {
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
              "Votre Restaurant",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Toutes les informations sont obligatoires.",
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 32),

            // Nom du Restaurant
            TextFormField(
              decoration: InputDecoration(
                labelText: "Nom du restaurant",
                prefixIcon: const Icon(Icons.restaurant),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) => (value == null || value.isEmpty) ? "Nom obligatoire" : null,
            ),
            const SizedBox(height: 16),

            // Ligne Numéro et Nom de rue
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Numéro de rue
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "N°",
                      hintText: "12",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? "Requis" : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Nom de la rue
                Expanded(
                  flex: 5,
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: "Nom de la rue",
                      prefixIcon: const Icon(Icons.map_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? "Rue obligatoire" : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ligne Code Postal et Ville
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Code Postal
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: "CP",
                      hintText: "75000",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Requis";
                      if (value.length < 5) return "Invalide";
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Ville
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: "Ville",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? "Ville obligatoire" : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Bouton Continuer
            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton(
                onPressed: () {
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