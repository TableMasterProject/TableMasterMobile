import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/app_constant.dart';
import '../../../../../core/models/restaurant_in.dart';

class Step4RestaurantInfoScreen extends StatefulWidget {
  final Function(RestaurantIn data) onNext;
  final RestaurantIn restaurantIn;

  const Step4RestaurantInfoScreen({super.key, required this.onNext, required this.restaurantIn});

  @override
  State<Step4RestaurantInfoScreen> createState() => _Step4RestaurantInfoScreenState();
}

class _Step4RestaurantInfoScreenState extends State<Step4RestaurantInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _streetNumController = TextEditingController();
  final TextEditingController _streetNameController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Listes de choix
  List<String> _selectedCuisines = [];

  List<String> _selectedPayments = [];

  bool _isAutoValidate = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.restaurantIn.restaurantName;
    _streetNumController.text = widget.restaurantIn.streetNumber;
    _streetNameController.text = widget.restaurantIn.streetName;
    _zipController.text = widget.restaurantIn.postalCode;
    _cityController.text = widget.restaurantIn.city;
    _phoneController.text = widget.restaurantIn.phone;
    _descriptionController.text = widget.restaurantIn.description;
    _isAutoValidate = widget.restaurantIn.isAutoValidateReservation;
    _selectedCuisines = widget.restaurantIn.cuisineType.split(",");
    _selectedPayments = widget.restaurantIn.paymentMethods.split(",");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetNumController.dispose();
    _streetNameController.dispose();
    _zipController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView( // Assure le scroll si le clavier ou le contenu dépasse
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Votre Restaurant", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.onSurface)),
            const SizedBox(height: 8),
            Text("Complétez les détails de votre établissement.", style: TextStyle(color: colors.onSurfaceVariant)),
            const SizedBox(height: 32),

            // Nom
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Nom du restaurant", prefixIcon: const Icon(Icons.restaurant), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              validator: (value) => (value == null || value.isEmpty) ? "Nom obligatoire" : null,
            ),
            const SizedBox(height: 16),

            // Téléphone
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: "Téléphone", prefixIcon: const Icon(Icons.phone), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              validator: (value) => (value == null || value.isEmpty) ? "Téléphone obligatoire" : null,
            ),
            const SizedBox(height: 16),

            // Adresse (Ligne 1)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: TextFormField(controller: _streetNumController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "N°", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (value) => (value == null || value.isEmpty) ? "Requis" : null)),
                const SizedBox(width: 12),
                Expanded(flex: 5, child: TextFormField(controller: _streetNameController, decoration: InputDecoration(labelText: "Nom de la rue", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (value) => (value == null || value.isEmpty) ? "Rue obligatoire" : null)),
              ],
            ),
            const SizedBox(height: 16),

            // Adresse (Ligne 2)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: TextFormField(controller: _zipController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: "CP", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (value) => (value == null || value.length < 5) ? "Invalide" : null)),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: TextFormField(controller: _cityController, decoration: InputDecoration(labelText: "Ville", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (value) => (value == null || value.isEmpty) ? "Ville obligatoire" : null)),
              ],
            ),
            const SizedBox(height: 24),

            // Type de cuisine (Choix multiples)
            Text("Type de cuisine", style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.cuisineOptions.map((type) {
                final isSelected = _selectedCuisines.contains(type);
                return FilterChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() { selected ? _selectedCuisines.add(type) : _selectedCuisines.remove(type); });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Méthodes de paiement
            Text("Méthodes de paiement", style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.paymentOptions.map((method) {
                final isSelected = _selectedPayments.contains(method);
                return FilterChip(
                  label: Text(method),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() { selected ? _selectedPayments.add(method) : _selectedPayments.remove(method); });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(labelText: "Description", hintText: "Présentez votre restaurant en quelques mots...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),

            // Auto-validation
            SwitchListTile(
              title: const Text("Validation automatique"),
              subtitle: const Text("Accepter les réservations sans confirmation manuelle"),
              value: _isAutoValidate,
              onChanged: (val) => setState(() => _isAutoValidate = val),
            ),

            const SizedBox(height: 32),

            // Bouton
            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final restaurant = widget.restaurantIn.copyWith(
                      restaurantName: _nameController.text.trim(),
                      streetNumber: _streetNumController.text.trim(),
                      streetName: _streetNameController.text.trim(),
                      postalCode: _zipController.text.trim(),
                      city: _cityController.text.trim(),
                      phone: _phoneController.text.trim(),
                      cuisineType: _selectedCuisines.join(","),
                      paymentMethods: _selectedPayments.join(","),
                      description: _descriptionController.text.trim(),
                      isAutoValidateReservation: _isAutoValidate,
                    );

                    widget.onNext(restaurant);
                  }
                },
                child: const Text("Continuer", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}