import 'package:flutter/material.dart';
import 'package:table_master_mobile/features/user/data/models/user_out.dart';

class RestaurantPage extends StatelessWidget {
  final UserOut user;

class RestaurantPage extends StatefulWidget {
  final UserOut user;

  const RestaurantPage({super.key, required this.user});

  @override
  State<RestaurantPage> createState() => _RestaurantPageState();
}

class _RestaurantPageState extends State<RestaurantPage> {
  int _viewIndex = 0; // 0 = tables, 1 = réservations, 2 = paramètres

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final restaurant = widget.user.restaurant;

    if (restaurant == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_outlined,
              size: 80,
              color: colors.primary,
            ),
            const SizedBox(height: 20),
            Text(
              "Aucun restaurant associé",
              style: TextStyle(
                fontSize: 18,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    Widget body;
    switch (_viewIndex) {
      case 1:
        body = _buildPendingReservationsView(colors);
        break;
      case 2:
        body = _buildSettingsView(context, colors, restaurant);
        break;
      default:
        body = _buildTablesView(colors, restaurant);
    }

    return Column(
      children: [
        // Top buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => setState(() => _viewIndex = 0),
                  style: FilledButton.styleFrom(backgroundColor: _viewIndex == 0 ? colors.primary : colors.surface),
                  child: Text("Tables", style: TextStyle(color: _viewIndex == 0 ? colors.onPrimary : colors.onSurface)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _viewIndex = 1),
                  child: const Text("Réservations en attente"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _viewIndex = 2),
                  child: const Text("Paramètres"),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Body
        Expanded(child: body),
      ],
    );
  }

  Widget _buildTablesView(ColorScheme colors, dynamic restaurant) {
    final tables = restaurant.tables ?? [];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tables", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.onSurface)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: tables.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final t = tables[index];
                return ListTile(
                  title: Text("Table ${t.tableNumber}"),
                  subtitle: Text("${t.numberOfSeats} sièges"),
                  trailing: IconButton(
                    icon: Icon(Icons.edit, color: colors.primary),
                    onPressed: () {
                      // Aller à la gestion des tables
                      Navigator.push(context, MaterialPageRoute(builder: (_) => Step5TableManagementScreen(onNext: (newTables) { Navigator.pop(context); })));
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingReservationsView(ColorScheme colors) {
    // Mock data for now - replace with real fetch later
    final List<Map<String, String>> _pending = [
      {"name": "Dupont", "date": "2026-02-14 20:00"},
      {"name": "Martin", "date": "2026-02-15 19:30"},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Réservations en attente", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.onSurface)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: _pending.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final r = _pending[index];
                return ListTile(
                  title: Text(r['name'] ?? ''),
                  subtitle: Text(r['date'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: colors.primary),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Réservation acceptée pour ${r['name']}")));
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: colors.error),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Réservation refusée pour ${r['name']}")));
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsView(BuildContext context, ColorScheme colors, dynamic restaurant) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Paramètres du restaurant", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.onSurface)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restaurant.restaurantName ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.onSurface)),
                  const SizedBox(height: 8),
                  Text("Adresse: ${restaurant.streetNumber} ${restaurant.streetName}, ${restaurant.postalCode} ${restaurant.city}", style: TextStyle(color: colors.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text("Téléphone: ${restaurant.phone}", style: TextStyle(color: colors.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text("Note moyenne: ${restaurant.averageRating?.toStringAsFixed(1) ?? '0.0'}", style: TextStyle(color: colors.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text("Nombre d'avis: ${restaurant.numberOfReviews ?? 0}", style: TextStyle(color: colors.onSurfaceVariant)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Modifier le restaurant -> Step4
                Navigator.push(context, MaterialPageRoute(builder: (_) => Step4RestaurantInfoScreen(onNext: (r) { Navigator.pop(context); }, restaurantIn: restaurant)));
              },
              icon: const Icon(Icons.edit),
              label: const Text("Modifier le restaurant"),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Modifier le menu
              },
              icon: const Icon(Icons.menu_book),
              label: const Text("Modifier le menu"),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Modifier horaires/activité
              },
              icon: const Icon(Icons.access_time),
              label: const Text("Modifier horaires / activité"),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Modifier fermetures exceptionnelles
              },
              icon: const Icon(Icons.event_busy),
              label: const Text("Exceptions de fermeture"),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Modifier les tables -> Step5
                Navigator.push(context, MaterialPageRoute(builder: (_) => Step5TableManagementScreen(onNext: (newTables) { Navigator.pop(context); })));
              },
              icon: const Icon(Icons.table_restaurant),
              label: const Text("Modifier les tables"),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Afficher les avis du restaurant
              },
              icon: const Icon(Icons.reviews),
              label: const Text("Avis du restaurant"),
            ),
          ),
        ],
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final restaurant = user.restaurant;

    return restaurant == null
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_outlined, size: 80, color: colors.primary),
              const SizedBox(height: 20),
              Text(
                "Aucun restaurant associé",
                style: TextStyle(fontSize: 18, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        )
        : SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations du restaurant
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow("Nom", restaurant.restaurantName, colors),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        "Adresse",
                        "${restaurant.streetNumber} ${restaurant.streetName}, ${restaurant.postalCode} ${restaurant.city}",
                        colors,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow("Téléphone", restaurant.phone, colors),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        "Type de cuisine",
                        restaurant.cuisineType,
                        colors,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Boutons d'action
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Naviguer vers la page de gestion des tables
                  },
                  icon: const Icon(Icons.table_restaurant),
                  label: const Text("Gérer les tables"),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Naviguer vers la page des réservations du restaurant
                  },
                  icon: const Icon(Icons.event),
                  label: const Text("Mes réservations"),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Naviguer vers la page de modification du restaurant
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Modifier le restaurant"),
                ),
              ),
            ],
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
}
