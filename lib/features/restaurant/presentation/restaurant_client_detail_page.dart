import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_out.dart';
import 'package:table_master_mobile/features/restaurant/domain/repositories/restaurant_repository.dart';

class RestaurantClientDetailPage extends StatefulWidget {
  final RestaurantOut restaurant;

  const RestaurantClientDetailPage({super.key, required this.restaurant});

  @override
  State<RestaurantClientDetailPage> createState() =>
      _RestaurantClientDetailPageState();
}

class _RestaurantClientDetailPageState extends State<RestaurantClientDetailPage>
    with SingleTickerProviderStateMixin {
  final IRestaurantRepository _repo = getIt<IRestaurantRepository>();
  RestaurantOut? _fullRestaurant;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchRestaurantDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchRestaurantDetails() async {
    try {
      final result = await _repo.getRestaurantDetails(widget.restaurant.id);
      if (mounted) {
        setState(() {
          _fullRestaurant = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load restaurant details: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: implement reservation creation flow
        },
        label: const Text('Faire une réservation'),
        icon: const Icon(Icons.event_available),
      ),
    );
  }

  Widget _buildBody() {
    final restaurant = _fullRestaurant ?? widget.restaurant;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                restaurant.restaurantName,
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  shadows: [const Shadow(blurRadius: 4, color: Colors.black45)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: colors.primaryContainer,
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 150,
                      color: colors.onPrimaryContainer.withOpacity(0.5),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(0.0, 0.5),
                        end: Alignment(0.0, 0.0),
                        colors: <Color>[Color(0x60000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: colors.primary,
                unselectedLabelColor: colors.onSurfaceVariant,
                tabs: const [
                  Tab(icon: Icon(Icons.info_outline), text: 'À propos'),
                  Tab(icon: Icon(Icons.restaurant_menu), text: 'Menu'),
                  Tab(icon: Icon(Icons.reviews_outlined), text: 'Avis'),
                ],
              ),
            ),
            pinned: true,
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAboutTab(context, restaurant),
          _buildMenuTab(context, restaurant),
          _buildReviewsTab(context, restaurant),
        ],
      ),
    );
  }

  Widget _buildAboutTab(BuildContext context, RestaurantOut restaurant) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final weekDays = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating
          _buildRatingSection(textTheme, colors, restaurant),
          const SizedBox(height: 24),

          // General Info
          _buildInfoTile(
            Icons.location_on,
            'Adresse',
            restaurant.addressString(),
          ),
          _buildInfoTile(Icons.phone, 'Téléphone', restaurant.phone),
          _buildInfoTile(Icons.restaurant, 'Cuisine', restaurant.cuisineType),
          const SizedBox(height: 16),
          const Divider(),

          // Description
          Text(
            'À propos de ${restaurant.restaurantName}',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(restaurant.description, style: textTheme.bodyLarge),
          const SizedBox(height: 24),

          // Opening Hours
          Text('Horaires d\'ouverture', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          if (restaurant.dailyActivitys != null)
            ...restaurant.dailyActivitys!.map((activity) {
              final day = weekDays[activity.dayOfWeek - 1];
              final start = activity.startTime.substring(0, 5);
              final end = activity.endTime.substring(0, 5);

              String schedule = '$day: $start - $end';

              return Text(schedule, style: textTheme.bodyMedium);
            }).toList(),
          const SizedBox(height: 24),

          // Exceptional Closures
          if (restaurant.closedDayExceptions?.isNotEmpty ?? false) ...[
            Text('Fermetures Exceptionnelles', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            ...restaurant.closedDayExceptions!.map((exception) {
              final format = DateFormat.yMd('fr_FR');
              String period = format.format(exception.exceptionDateBegin);
              if (exception.exceptionDateBegin != exception.exceptionDateEnd) {
                period += ' au ${format.format(exception.exceptionDateEnd)}';
              }
              return Text(
                '$period: ${exception.reason}',
                style: textTheme.bodyMedium,
              );
            }).toList(),
            const SizedBox(height: 24),
          ],

          // Tables
          if (restaurant.tables?.isNotEmpty ?? false) ...[
            Text('Tables disponibles', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children:
                  restaurant.tables!.map((table) {
                    return Chip(
                      label: Text(
                        'Table ${table.tableNumber} (${table.numberOfSeats}p)',
                      ),
                    );
                  }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuTab(BuildContext context, RestaurantOut restaurant) {
    final textTheme = Theme.of(context).textTheme;

    if (restaurant.menu == null || restaurant.menu!.isEmpty) {
      return const Center(child: Text('Le menu n\'est pas disponible.'));
    }

    // Group menu by category
    final menuByCategory = <String, List>{};
    for (var item in restaurant.menu!) {
      (menuByCategory[item.category] ??= []).add(item);
    }

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children:
          menuByCategory.entries.map((entry) {
            final category = entry.key;
            final items = entry.value;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(category, style: textTheme.headlineSmall),
                  ),
                  ...items.map((menuItem) {
                    return ListTile(
                      title: Text(
                        menuItem.itemName,
                        style: textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        menuItem.description,
                        style: textTheme.bodyMedium,
                      ),
                      trailing: Text(
                        '${menuItem.price.toStringAsFixed(2)} €',
                        style: textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildReviewsTab(BuildContext context, RestaurantOut restaurant) {
    final textTheme = Theme.of(context).textTheme;

    if (restaurant.reviews == null || restaurant.reviews!.isEmpty) {
      return const Center(child: Text('Aucun avis pour le moment.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8.0),
      itemCount: restaurant.reviews!.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final review = restaurant.reviews![index];
        return ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Avis d'un utilisateur", style: textTheme.titleMedium),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16.0,
                  );
                }),
              ),
            ],
          ),
          subtitle: Text(
            '${review.comment ?? ''}\n'
            '${DateFormat.yMMMd('fr_FR').format(review.createdAt)}',
            style: textTheme.bodyMedium,
          ),
        );
      },
    );
  }

  Widget _buildRatingSection(
    TextTheme textTheme,
    ColorScheme colors,
    RestaurantOut restaurant,
  ) {
    return Row(
      children: [
        Icon(Icons.star, color: Colors.amber, size: 28),
        const SizedBox(width: 8),
        Text(
          restaurant.averageRating.toStringAsFixed(1),
          style: textTheme.headlineSmall,
        ),
        const SizedBox(width: 8),
        Text(
          '(${restaurant.numberOfReviews} avis)',
          style: textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
