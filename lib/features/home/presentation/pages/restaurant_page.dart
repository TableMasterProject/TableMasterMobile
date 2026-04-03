import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_master_mobile/features/user/data/models/user_out.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_out.dart';
import 'package:table_master_mobile/features/restaurant/domain/repositories/restaurant_repository.dart';
import 'package:table_master_mobile/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step4_restaurant_info_screen.dart';
import 'package:table_master_mobile/features/auth/presentation/registration_tunnel/step/step5_table_management_screen.dart';
import 'package:table_master_mobile/features/reservation/presentation/table_reservations_page.dart';
import 'package:table_master_mobile/features/table/domain/repositories/table_repository.dart';
import 'package:table_master_mobile/features/menu/data/models/menu_out.dart';
import 'package:table_master_mobile/features/menu/domain/repositories/menu_repository.dart';
import 'package:table_master_mobile/features/menu/presentation/menu_page.dart';
import 'package:table_master_mobile/features/daily_activity/presentation/hourly_activity_page.dart';
import 'package:table_master_mobile/features/closed_day_exception/presentation/exceptions_page.dart';
import 'package:table_master_mobile/features/review/presentation/pages/restaurant_reviews_page.dart';

import '../../../reservation/data/models/reservation_in.dart';
import '../../../reservation/data/models/search_reservations.dart';
import '../../../reservation/presentation/widgets/reservation_card.dart';

class RestaurantPage extends StatefulWidget {
  final UserOut user;

  const RestaurantPage({super.key, required this.user});

  @override
  State<RestaurantPage> createState() => _RestaurantPageState();
}

class _RestaurantPageState extends State<RestaurantPage> {
  int _viewIndex = 0; // 0 = tables, 1 = réservations, 2 = menu, 3 = paramètres
  RestaurantOut? _restaurant;
  bool _loading = false;
  String? _error;
  List<ReservationOut> _reservations = [];
  List<ReservationOut> _summaryReservations = []; // Pour les compteurs badges
  List<MenuOut> _menuItems = [];
  int _selectedFilter = 0; // 0: Validées, 1: En attente, 2: Historique

  final repo = getIt<IRestaurantRepository>();
  final _reservationRepo = getIt<IReservationRepository>();
  final _tableRepo = getIt<ITableRepository>();
  final _menuRepo = getIt<IMenuRepository>();

  @override
  void initState() {
    super.initState();
    _loadRestaurantIfNeeded();
  }

  Future<void> _loadRestaurantIfNeeded() async {
    final rid = widget.user.restaurantId;
    if (rid == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await repo.getRestaurantDetails(rid);
      setState(() => _restaurant = r);
      await _loadSummary(r.id);
      await _loadDailyReservations(r.id);
      await _loadMenu(r.id);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadSummary(int restaurantId) async {
    try {
      SearchReservations search = SearchReservations();
      search.restaurantId = restaurantId;
      search.pageSize = 100;
      search.statuses = [ReservationStatus.enAttente, ReservationStatus.validee];
      final results = await _reservationRepo.getReservations(search);
      setState(() {
        _summaryReservations = results;
      });
    } catch (e) {}
  }

  Future<void> _loadDailyReservations(int restaurantId) async {
    try {
      SearchReservations search = SearchReservations();
      search.restaurantId = restaurantId;
      search.pageSize = 50;

      if (_selectedFilter == 0) {
        search.statuses = [ReservationStatus.validee];
        search.minDate = DateTime.now();
      } else if (_selectedFilter == 1) {
        search.statuses = [ReservationStatus.enAttente];
      } else {
        search.statuses = [
          ReservationStatus.finie,
          ReservationStatus.annuleeResto,
          ReservationStatus.annuleeClient
        ];
      }

      final results = await _reservationRepo.getReservations(search);
      results.sort((a, b) => a.reservationDate.compareTo(b.reservationDate));

      setState(() {
        _reservations = results;
      });
    } catch (e) {
      // ignore
    }
  }

  Future<void> _loadMenu(int restaurantId) async {
    try {
      final menu = await _menuRepo.getByRestaurant(restaurantId);
      setState(() => _menuItems = menu);
    } catch (e) {
      // ignore
    }
  }

  Future<void> _updateStatus(int id, ReservationStatus status) async {
    try {
      await _reservationRepo.updateReservationStatus(id, status);
      if (_restaurant != null) {
        await _loadSummary(_restaurant!.id);
        await _loadDailyReservations(_restaurant!.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (widget.user.restaurantId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_outlined, size: 80, color: colors.primary),
            const SizedBox(height: 20),
            Text("Aucun restaurant associé", style: TextStyle(fontSize: 18, color: colors.onSurfaceVariant)),
          ],
        ),
      );
    }

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Erreur: $_error'));
    if (_restaurant == null) return const Center(child: Text('Aucun détail de restaurant disponible'));

    final restaurant = _restaurant!;

    Widget body;
    switch (_viewIndex) {
      case 1:
        body = _buildReservationsView(colors);
        break;
      case 2:
        body = _buildMenuView(colors);
        break;
      case 3:
        body = _buildSettingsView(context, colors, restaurant);
        break;
      default:
        body = _buildTablesView(colors, restaurant);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTabButton("Tables", 0, colors),
                const SizedBox(width: 8),
                _buildTabButton("Réservations", 1, colors),
                const SizedBox(width: 8),
                _buildTabButton("Menu", 2, colors),
                const SizedBox(width: 8),
                _buildTabButton("Paramètres", 3, colors),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: body),
      ],
    );
  }

  Widget _buildTabButton(String label, int index, ColorScheme colors) {
    final isSelected = _viewIndex == index;
    return FilledButton(
      onPressed: () => setState(() => _viewIndex = index),
      style: FilledButton.styleFrom(
        backgroundColor: isSelected ? colors.primary : colors.surfaceVariant,
        foregroundColor: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
      ),
      child: Text(label),
    );
  }

  Widget _buildTablesView(ColorScheme colors, RestaurantOut restaurant) {
    final tables = restaurant.tables ?? [];
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Gestion des Tables", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.onSurface)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: tables.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final t = tables[index];

                // Calcul des compteurs basés sur summaryReservations (tous statuts actifs)
                final tableRes = _summaryReservations.where((r) => r.tableId == t.id).toList();

                final pendingCount = tableRes.where((r) => r.status == ReservationStatus.enAttente).length;
                final todayCount = tableRes.where((r) =>
                  r.status == ReservationStatus.validee &&
                  DateUtils.isSameDay(r.reservationDate, now)
                ).length;

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
                      child: Text(t.tableNumber.toString(), style: TextStyle(color: colors.onPrimaryContainer, fontWeight: FontWeight.bold)),
                    ),
                    title: Text("Table ${t.tableNumber}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${t.numberOfSeats} places disponibles"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (todayCount > 0)
                          _buildTableBadge(todayCount.toString(), Colors.blue, Icons.event),
                        if (pendingCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: _buildTableBadge(pendingCount.toString(), Colors.orange, Icons.pending_actions),
                          ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, size: 20),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TableReservationsPage(restaurantId: restaurant.id, table: t)),
                      );
                      _loadSummary(restaurant.id);
                      _loadDailyReservations(restaurant.id);
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

  Widget _buildTableBadge(String text, Color color, IconData icon) {
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
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildReservationsView(ColorScheme colors) {
    final pendingTotal = _summaryReservations.where((r) => r.status == ReservationStatus.enAttente).length;
    final todayTotal = _summaryReservations.where((r) => r.status == ReservationStatus.validee && DateUtils.isSameDay(r.reservationDate, DateTime.now())).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(
                value: 0,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Validées'),
                    if (todayTotal > 0) _buildCountBadge(todayTotal, Colors.blue),
                  ],
                ),
                icon: const Icon(Icons.check_circle_outline),
              ),
              ButtonSegment(
                value: 1,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Attente'),
                    if (pendingTotal > 0) _buildCountBadge(pendingTotal, Colors.orange),
                  ],
                ),
                icon: const Icon(Icons.pending_actions),
              ),
              const ButtonSegment(value: 2, label: Text('Historique'), icon: Icon(Icons.history)),
            ],
            selected: {_selectedFilter},
            onSelectionChanged: (Set<int> newSelection) {
              setState(() {
                _selectedFilter = newSelection.first;
              });
              _loadDailyReservations(_restaurant!.id);
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadSummary(_restaurant!.id);
              await _loadDailyReservations(_restaurant!.id);
            },
            child: _reservations.isEmpty
                ? const Center(child: Text("Aucune réservation"))
                : _buildGroupedList(colors),
          ),
        ),
      ],
    );
  }

  Widget _buildCountBadge(int count, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildGroupedList(ColorScheme colors) {
    final Map<String, List<ReservationOut>> grouped = {};
    
    for (var r in _reservations) {
      final date = r.reservationDate.toLocal();
      final key = DateFormat('yyyy-MM-dd').format(date);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(r);
    }

    final sortedDates = grouped.keys.toList();
    if (_selectedFilter == 2) {
      sortedDates.sort((a, b) => b.compareTo(a));
    } else {
      sortedDates.sort((a, b) => a.compareTo(b));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIndex) {
        final dateKey = sortedDates[dateIndex];
        final dayReservations = grouped[dateKey]!;
        final displayDate = _getDisplayDate(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Text(
                displayDate,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            ...dayReservations.map((r) => ReservationCard(
              reservation: r,
              onStatusUpdate: (newStatus) => _updateStatus(r.id, newStatus),
            )),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  String _getDisplayDate(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return "AUJOURD'HUI";
    if (date == tomorrow) return "DEMAIN";
    if (date == yesterday) return "HIER";
    
    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date).toUpperCase();
  }

  Widget _buildMenuView(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Menu de l'établissement", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.onSurface)),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => MenuPage(restaurantId: _restaurant!.id)));
                  _loadMenu(_restaurant!.id);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_menuItems.isEmpty) const Expanded(child: Center(child: Text("Aucun plat enregistré dans le menu")))
          else Expanded(
            child: ListView.builder(
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item.description),
                    trailing: Text("${item.price.toStringAsFixed(2)}€", style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsView(BuildContext context, ColorScheme colors, RestaurantOut restaurant) {
    final days = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Paramètres du restaurant", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.onSurface)),
          const SizedBox(height: 12),
          _buildInfoCard(colors, "Informations Générales", [
            _buildInfoRow("Nom", restaurant.restaurantName),
            _buildInfoRow("Créé le", DateFormat('dd/MM/yyyy').format(restaurant.createdAt)),
            _buildInfoRow("Cuisine", restaurant.cuisineType),
            _buildInfoRow("Paiements", restaurant.paymentMethods),
            _buildInfoRow("Note Moyenne", "${restaurant.averageRating.toStringAsFixed(1)} / 5 (${restaurant.numberOfReviews} avis)"),
          ]),
          const SizedBox(height: 12),
          _buildInfoCard(colors, "Contact & Localisation", [
            _buildInfoRow("Adresse", "${restaurant.streetNumber} ${restaurant.streetName}"),
            _buildInfoRow("Ville", "${restaurant.postalCode} ${restaurant.city}"),
            _buildInfoRow("Téléphone", restaurant.phone),
            _buildInfoRow("Validation Auto", restaurant.isAutoValidateReservation ? "Activée" : "Désactivée"),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text("Description : ${restaurant.description}", style: const TextStyle(fontSize: 13)),
            ),
          ]),
          const SizedBox(height: 12),
          _buildInfoCard(colors, "Horaires d'ouverture", [
            if (restaurant.dailyActivitys == null || restaurant.dailyActivitys!.isEmpty) const Text("Aucun horaire configuré", style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic))
            else ...restaurant.dailyActivitys!.map((a) => _buildInfoRow(days[(a.dayOfWeek - 1) % 7], "${a.startTime.substring(0, 5)} - ${a.endTime.substring(0, 5)}")),
          ]),
          const SizedBox(height: 12),
          _buildInfoCard(colors, "Fermetures exceptionnelles", [
            if (restaurant.closedDayExceptions == null || restaurant.closedDayExceptions!.isEmpty) const Text("Aucune exception configurée", style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic))
            else ...restaurant.closedDayExceptions!.map((e) => _buildInfoRow(DateFormat('dd/MM/yy').format(e.exceptionDateBegin), "${e.reason} (${DateFormat('dd/MM/yy').format(e.exceptionDateEnd)})")),
          ]),
          const SizedBox(height: 24),
          _buildSettingsButton(context, "Modifier le restaurant", Icons.edit, () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text("Modifier le restaurant")), body: Step4RestaurantInfoScreen(onNext: (updatedData) async {
              try {
                await repo.updateRestaurant(restaurant.id, updatedData);
                Navigator.pop(context);
                _loadRestaurantIfNeeded();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
              }
            }, restaurantIn: restaurant))));
          }),
          _buildSettingsButton(context, "Modifier horaires / activité", Icons.access_time, () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => HourlyActivityPage(restaurantId: restaurant.id)));
            _loadRestaurantIfNeeded();
          }),
          _buildSettingsButton(context, "Exceptions de fermeture", Icons.event_busy, () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => ExceptionsPage(restaurantId: restaurant.id)));
            _loadRestaurantIfNeeded();
          }),
          _buildSettingsButton(context, "Modifier les tables", Icons.table_restaurant, () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text("Modifier les tables")), body: Step5TableManagementScreen(onNext: (newTables) async {
              try {
                for (var t in newTables.toAdd) { await _tableRepo.addTable(_restaurant!.id, t); }
                for (var t in newTables.toUpdate) { await _tableRepo.editTable(t.id, t); }
                for (var t in newTables.toDelete) { await _tableRepo.removeTable(t.id); }
                Navigator.pop(context);
                _loadRestaurantIfNeeded();
              } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'))); }
            }, initialTables: restaurant.tables))));
          }),
          _buildSettingsButton(context, "Avis du restaurant", Icons.reviews, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => RestaurantReviewsPage(restaurantId: widget.user.restaurantId!)));
          }),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme colors, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.primary)),
          const Divider(),
          ...children,
        ]),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 120, child: Text("$label :", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }

  Widget _buildSettingsButton(BuildContext context, String label, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label))),
    );
  }
}
