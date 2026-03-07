import 'package:flutter/material.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_out.dart';

class RestaurantClientDetailPage extends StatelessWidget {
  final RestaurantOut restaurant;

  const RestaurantClientDetailPage({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(restaurant.restaurantName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              restaurant.addressString(),
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text('Cuisine: ${restaurant.cuisineType}'),
            const SizedBox(height: 8),
            Text('Téléphone: ${restaurant.phone}'),
            const SizedBox(height: 8),
            Text(restaurant.description),
            const SizedBox(height: 16),
            Text('Distance: ${restaurant.distance.toStringAsFixed(1)} km'),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                // TODO: implement reservation creation flow
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Créer une réservation')),
                );
              },
              icon: const Icon(Icons.event_available),
              label: const Text('Faire une réservation'),
            ),
          ],
        ),
      ),
    );
  }
}
