import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'package:table_master_mobile/core/navigation/app_navigation.dart';
import 'package:table_master_mobile/core/signalr_service.dart';
import 'package:table_master_mobile/core/widgets/async_state_widgets.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step4_restaurant_info_screen.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step5_table_management_screen.dart';
import 'package:table_master_mobile/features/closed_day_exception/presentation/exceptions_page.dart';
import 'package:table_master_mobile/features/daily_activity/presentation/hourly_activity_page.dart';
import 'package:table_master_mobile/features/menu/data/models/menu_out.dart';
import 'package:table_master_mobile/features/menu/domain/repositories/menu_repository.dart';
import 'package:table_master_mobile/features/menu/presentation/menu_page.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:table_master_mobile/features/reservation/presentation/table_reservations_page.dart';
import 'package:table_master_mobile/features/reservation/presentation/widgets/reservation_card.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_in.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_out.dart';
import 'package:table_master_mobile/features/restaurant/domain/repositories/restaurant_repository.dart';
import 'package:table_master_mobile/features/restaurant/presentation/controllers/restaurant_controller.dart';
import 'package:table_master_mobile/features/restaurant/presentation/restaurant_setup_flow.dart';
import 'package:table_master_mobile/features/review/presentation/pages/restaurant_reviews_page.dart';
import 'package:table_master_mobile/features/table/data/models/table_changes.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_out.dart';
import 'package:table_master_mobile/features/table/domain/repositories/table_repository.dart';
import 'package:table_master_mobile/features/user/data/models/user_out.dart';

class RestaurantPage extends StatefulWidget {
  final UserOut user;

  const RestaurantPage({super.key, required this.user});

  @override
  State<RestaurantPage> createState() => _RestaurantPageState();
}

class _RestaurantPageState extends State<RestaurantPage> {
  late final RestaurantController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RestaurantController(
      restaurantRepository: getIt<IRestaurantRepository>(),
      reservationRepository: getIt<IReservationRepository>(),
      tableRepository: getIt<ITableRepository>(),
      menuRepository: getIt<IMenuRepository>(),
      signalRService: getIt<SignalRService>(),
    )..onNewReservation = _showNewReservationSnackBar;

    _controller.loadForUser(widget.user);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showNewReservationSnackBar() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Nouvelle demande de réservation !"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: "Voir",
          textColor: Colors.white,
          onPressed: () {
            _controller.selectView(1);
            _controller.selectReservationFilter(1);
          },
        ),
      ),
    );
  }

  Future<void> _openCreateRestaurantFlow() async {
    final createdRestaurant = await AppNavigation.push<RestaurantOut>(
      context,
      RestaurantSetupFlow(
        user: widget.user,
        restaurantRepository: getIt<IRestaurantRepository>(),
        tableRepository: getIt<ITableRepository>(),
      ),
    );

    if (createdRestaurant == null || !mounted) return;

    await _controller.attachCreatedRestaurant(widget.user, createdRestaurant);
  }

  Future<void> _openRestaurantInfo(RestaurantOut restaurant) async {
    await AppNavigation.push<void>(
      context,
      _SettingsStepPage(
        title: "Informations du restaurant",
        child: Step4RestaurantInfoScreen(
          restaurantIn: restaurant,
          onNext: (data) => _saveRestaurantSettings(data),
        ),
      ),
    );
  }

  Future<void> _openTableManagement(RestaurantOut restaurant) async {
    await AppNavigation.push<void>(
      context,
      _SettingsStepPage(
        title: "Gestion des tables",
        child: Step5TableManagementScreen(
          initialTables: restaurant.tables,
          onNext: (changes) => _saveTableSettings(changes),
        ),
      ),
    );
  }

  Future<void> _saveRestaurantSettings(RestaurantIn restaurant) async {
    AppSavingDialog.show(context);
    try {
      await _controller.saveRestaurantSettings(restaurant);
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informations du restaurant mises à jour.")),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _saveTableSettings(TableChanges changes) async {
    AppSavingDialog.show(context);
    try {
      await _controller.saveTableSettings(changes);
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tables mises à jour.")),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (widget.user.restaurantId == null && _controller.restaurant == null) {
          return AppEmptyState(
            icon: Icons.restaurant_outlined,
            message: "Aucun restaurant associé",
            action: widget.user.accountType == 1
                ? FilledButton.icon(
                    onPressed: _openCreateRestaurantFlow,
                    icon: const Icon(Icons.add_business_outlined),
                    label: const Text("Créer son restaurant"),
                  )
                : null,
          );
        }

        if (_controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_controller.error != null) {
          return AppErrorState(
            message: "Erreur: ${_controller.error}",
            onRetry: () => _controller.loadForUser(widget.user),
          );
        }

        final restaurant = _controller.restaurant;
        if (restaurant == null) {
          return const AppEmptyState(
            icon: Icons.restaurant_outlined,
            message: "Aucun détail de restaurant disponible",
          );
        }

        final body = switch (_controller.viewIndex) {
          1 => _ReservationsView(
              reservations: _controller.reservations,
              summaryReservations: _controller.summaryReservations,
              selectedFilter: _controller.selectedFilter,
              onFilterChanged: _controller.selectReservationFilter,
              onStatusUpdate: _controller.updateReservationStatus,
            ),
          2 => _MenuView(
              restaurantId: restaurant.id,
              menuItems: _controller.menuItems,
              onMenuChanged: () => _controller.loadMenu(restaurant.id),
            ),
          3 => _SettingsView(
              restaurant: restaurant,
              onOpenInfo: () => _openRestaurantInfo(restaurant),
              onOpenTables: () => _openTableManagement(restaurant),
            ),
          _ => _TablesView(
              restaurant: restaurant,
              summaryReservations: _controller.summaryReservations,
              onTableChanged: _controller.refreshReservationData,
            ),
        };

        return Column(
          children: [
            _RestaurantTabs(
              selectedIndex: _controller.viewIndex,
              pendingCount: _controller.summaryReservations
                  .where((r) => r.status == ReservationStatus.enAttente)
                  .length,
              onChanged: _controller.selectView,
            ),
            const Divider(height: 1),
            Expanded(child: body),
          ],
        );
      },
    );
  }
}

class _RestaurantTabs extends StatelessWidget {
  final int selectedIndex;
  final int pendingCount;
  final ValueChanged<int> onChanged;

  const _RestaurantTabs({
    required this.selectedIndex,
    required this.pendingCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _TabButton(label: "Tables", index: 0, selectedIndex: selectedIndex, onChanged: onChanged),
            const SizedBox(width: 8),
            _TabButton(
              label: "Réservations",
              index: 1,
              selectedIndex: selectedIndex,
              badgeCount: pendingCount,
              onChanged: onChanged,
            ),
            const SizedBox(width: 8),
            _TabButton(label: "Menu", index: 2, selectedIndex: selectedIndex, onChanged: onChanged),
            const SizedBox(width: 8),
            _TabButton(label: "Paramètres", index: 3, selectedIndex: selectedIndex, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final int index;
  final int selectedIndex;
  final int badgeCount;
  final ValueChanged<int> onChanged;

  const _TabButton({
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onChanged,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isSelected = selectedIndex == index;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        FilledButton(
          onPressed: () => onChanged(index),
          style: FilledButton.styleFrom(
            backgroundColor: isSelected ? colors.primary : colors.surfaceVariant,
            foregroundColor: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
          ),
          child: Text(label),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -5,
            top: -5,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _TablesView extends StatelessWidget {
  final RestaurantOut restaurant;
  final List<ReservationOut> summaryReservations;
  final Future<void> Function() onTableChanged;

  const _TablesView({
    required this.restaurant,
    required this.summaryReservations,
    required this.onTableChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tables = restaurant.tables ?? <TableEntityOut>[];
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Gestion des tables",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.onSurface),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: tables.isEmpty
                ? const AppEmptyState(
                    icon: Icons.table_bar_outlined,
                    message: "Aucune table configurée",
                  )
                : ListView.separated(
                    itemCount: tables.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final table = tables[index];
                      final tableReservations = summaryReservations
                          .where((reservation) => reservation.tableId == table.id)
                          .toList();
                      final pendingCount = tableReservations
                          .where((reservation) => reservation.status == ReservationStatus.enAttente)
                          .length;
                      final todayCount = tableReservations
                          .where(
                            (reservation) =>
                                reservation.status == ReservationStatus.validee &&
                                DateUtils.isSameDay(reservation.reservationDate, now),
                          )
                          .length;

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: colors.outlineVariant.withOpacity(0.5)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: colors.primaryContainer,
                            child: Text(
                              table.tableNumber.toString(),
                              style: TextStyle(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            "Table ${table.tableNumber}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("${table.numberOfSeats} places disponibles"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (todayCount > 0)
                                _TableBadge(text: todayCount.toString(), color: Colors.blue, icon: Icons.event),
                              if (pendingCount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: _TableBadge(
                                    text: pendingCount.toString(),
                                    color: Colors.orange,
                                    icon: Icons.pending_actions,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right, size: 20),
                            ],
                          ),
                          onTap: () async {
                            await AppNavigation.push<void>(
                              context,
                              TableReservationsPage(restaurantId: restaurant.id, table: table),
                            );
                            await onTableChanged();
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
}

class _TableBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _TableBadge({
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ReservationsView extends StatelessWidget {
  final List<ReservationOut> reservations;
  final List<ReservationOut> summaryReservations;
  final int selectedFilter;
  final ValueChanged<int> onFilterChanged;
  final Future<void> Function(int id, ReservationStatus status) onStatusUpdate;

  const _ReservationsView({
    required this.reservations,
    required this.summaryReservations,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pendingTotal = summaryReservations
        .where((reservation) => reservation.status == ReservationStatus.enAttente)
        .length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _FilterChip(label: "Validées", index: 0, selectedFilter: selectedFilter, onChanged: onFilterChanged),
              const SizedBox(width: 8),
              _FilterChip(
                label: "En attente ($pendingTotal)",
                index: 1,
                selectedFilter: selectedFilter,
                onChanged: onFilterChanged,
              ),
              const SizedBox(width: 8),
              _FilterChip(label: "Historique", index: 2, selectedFilter: selectedFilter, onChanged: onFilterChanged),
            ],
          ),
        ),
        Expanded(
          child: reservations.isEmpty
              ? AppEmptyState(
                  icon: Icons.event_busy,
                  message: "Aucune réservation",
                  action: Text(
                    "Les réservations apparaîtront ici.",
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: reservations.length,
                  itemBuilder: (context, index) {
                    final reservation = reservations[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ReservationCard(
                        reservation: reservation,
                        onStatusUpdate: (newStatus) => onStatusUpdate(reservation.id, newStatus),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int index;
  final int selectedFilter;
  final ValueChanged<int> onChanged;

  const _FilterChip({
    required this.label,
    required this.index,
    required this.selectedFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedFilter == index,
      onSelected: (selected) {
        if (selected) onChanged(index);
      },
    );
  }
}

class _MenuView extends StatelessWidget {
  final int restaurantId;
  final List<MenuOut> menuItems;
  final Future<void> Function() onMenuChanged;

  const _MenuView({
    required this.restaurantId,
    required this.menuItems,
    required this.onMenuChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Votre menu",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.onSurface),
              ),
              IconButton.filledTonal(
                onPressed: () async {
                  await AppNavigation.push<void>(context, MenuPage(restaurantId: restaurantId));
                  await onMenuChanged();
                },
                icon: const Icon(Icons.edit),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: menuItems.isEmpty
                ? const AppEmptyState(
                    icon: Icons.restaurant_menu,
                    message: "Aucun plat ajouté au menu",
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: colors.outlineVariant.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: Container(
                                  width: double.infinity,
                                  color: colors.secondaryContainer.withOpacity(0.3),
                                  child: const Icon(Icons.restaurant_menu, size: 40),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.itemName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "${item.price.toStringAsFixed(2)} €",
                                    style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
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
}

class _SettingsView extends StatelessWidget {
  final RestaurantOut restaurant;
  final VoidCallback onOpenInfo;
  final VoidCallback onOpenTables;

  const _SettingsView({
    required this.restaurant,
    required this.onOpenInfo,
    required this.onOpenTables,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "Paramètres du restaurant",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        AppSettingTile(
          icon: Icons.storefront_outlined,
          title: "Informations du restaurant",
          subtitle: "Nom, adresse, type de cuisine...",
          onTap: onOpenInfo,
        ),
        AppSettingTile(
          icon: Icons.table_bar_outlined,
          title: "Gestion des tables",
          subtitle: "Ajouter ou modifier vos tables",
          onTap: onOpenTables,
        ),
        AppSettingTile(
          icon: Icons.access_time_outlined,
          title: "Horaires d'ouverture",
          subtitle: "Gérer vos créneaux quotidiens",
          onTap: () => AppNavigation.push<void>(
            context,
            HourlyActivityPage(restaurantId: restaurant.id),
          ),
        ),
        AppSettingTile(
          icon: Icons.calendar_today_outlined,
          title: "Fermetures exceptionnelles",
          subtitle: "Gérer les jours fériés et vacances",
          onTap: () => AppNavigation.push<void>(
            context,
            ExceptionsPage(restaurantId: restaurant.id),
          ),
        ),
        AppSettingTile(
          icon: Icons.star_outline_rounded,
          title: "Avis clients",
          subtitle: "Consulter les notes et commentaires",
          onTap: () => AppNavigation.push<void>(
            context,
            RestaurantReviewsPage(restaurantId: restaurant.id),
          ),
        ),
      ],
    );
  }
}

class _SettingsStepPage extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsStepPage({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.surface,
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(child: child),
    );
  }
}
