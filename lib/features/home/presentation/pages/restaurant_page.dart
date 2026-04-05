import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_master_mobile/core/signalr_service.dart';
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
  final _signalRService = getIt<SignalRService>();
  final _audioPlayer = AudioPlayer();

  StreamSubscription? _subCreated;
  StreamSubscription? _subValidated;
  StreamSubscription? _subDeleted;

  @override
  void initState() {
    super.initState();
    _loadRestaurantIfNeeded().then((_) => _initSignalR());
  }

  @override
  void dispose() {
    _subCreated?.cancel();
    _subValidated?.cancel();
    _subDeleted?.cancel();
    if (_restaurant != null) {
      _signalRService.leaveRestaurantGroup(_restaurant!.id);
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initSignalR() async {
    if (_restaurant == null) return;

    _subCreated = _signalRService.onReservationCreated.listen((res) {
      print("onReservationCreated");
      if (res.restaurantId == _restaurant?.id) {
        _playSound();
        _refreshData();
        _showNotificationSnackBar("Nouvelle demande de réservation !");
      }
    });

    _subValidated = _signalRService.onReservationValidated.listen((res) {
      print("onReservationValidated");
      if (res.restaurantId == _restaurant?.id) {
        _refreshData();
      }
    });

    _subDeleted = _signalRService.onReservationDeleted.listen((id) {
      _refreshData();
    });

    await _signalRService.init();
    await _signalRService.joinRestaurantGroup(_restaurant!.id);
  }

  void _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      print("Erreur lecture son: $e");
    }
  }

  void _showNotificationSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: "Voir",
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _viewIndex = 1; // Go to reservations view
              _selectedFilter = 1; // Show pending
            });
            _loadDailyReservations(_restaurant!.id);
          },
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    if (_restaurant != null) {
      await _loadSummary(_restaurant!.id);
      await _loadDailyReservations(_restaurant!.id);
    }
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
      if (mounted) {
        setState(() {
          _summaryReservations = results;
        });
      }
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

      if (mounted) {
        setState(() {
          _reservations = results;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _loadMenu(int restaurantId) async {
    try {
      final menu = await _menuRepo.getByRestaurant(restaurantId);
      if (mounted) {
        setState(() => _menuItems = menu);
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _updateStatus(int id, ReservationStatus status) async {
    try {
      await _reservationRepo.updateReservationStatus(id, status);
      await _refreshData();
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
    int badgeCount = 0;
    if (index == 1) {
      badgeCount = _summaryReservations.where((r) => r.status == ReservationStatus.enAttente).length;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        FilledButton(
          onPressed: () => setState(() => _viewIndex = index),
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
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '$badgeCount',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
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
                      _refreshData();
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildFilterChip("Validées", 0, colors),
              const SizedBox(width: 8),
              _buildFilterChip("En attente ($pendingTotal)", 1, colors),
              const SizedBox(width: 8),
              _buildFilterChip("Historique", 2, colors),
            ],
          ),
        ),
        Expanded(
          child: _reservations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 48, color: colors.outline),
                      const SizedBox(height: 16),
                      Text("Aucune réservation", style: TextStyle(color: colors.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _reservations.length,
                  itemBuilder: (context, index) {
                    final res = _reservations[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ReservationCard(
                        reservation: res,
                        onStatusUpdate: (newStatus) => _updateStatus(res.id, newStatus),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int index, ColorScheme colors) {
    final isSelected = _selectedFilter == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() => _selectedFilter = index);
          _loadDailyReservations(_restaurant!.id);
        }
      },
    );
  }

  Widget _buildMenuView(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Votre Menu", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.onSurface)),
              IconButton.filledTonal(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => MenuPage(restaurantId: _restaurant!.id)));
                  _loadMenu(_restaurant!.id);
                },
                icon: const Icon(Icons.edit),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _menuItems.isEmpty
                ? const Center(child: Text("Aucun plat ajouté au menu"))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
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
                                  Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text("${item.price.toStringAsFixed(2)} €", style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
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

  Widget _buildSettingsView(BuildContext context, ColorScheme colors, RestaurantOut restaurant) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Paramètres du restaurant", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.onSurface)),
        const SizedBox(height: 24),
        _buildSettingTile(
          context,
          Icons.storefront_outlined,
          "Informations du restaurant",
          "Nom, adresse, type de cuisine...",
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => Step4RestaurantInfoScreen(onNext: (data) {}, restaurantIn: restaurant))),
        ),
        _buildSettingTile(
          context,
          Icons.table_bar_outlined,
          "Gestion des tables",
          "Ajouter ou modifier vos tables",
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => Step5TableManagementScreen(onNext: (changes) {}, initialTables: restaurant.tables))),
        ),
        _buildSettingTile(
          context,
          Icons.access_time_outlined,
          "Horaires d'ouverture",
          "Gérer vos créneaux quotidiens",
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => HourlyActivityPage(restaurantId: restaurant.id))),
        ),
        _buildSettingTile(
          context,
          Icons.calendar_today_outlined,
          "Fermetures exceptionnelles",
          "Gérer les jours fériés et vacances",
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExceptionsPage(restaurantId: restaurant.id))),
        ),
        _buildSettingTile(
          context,
          Icons.star_outline_rounded,
          "Avis clients",
          "Consulter les notes et commentaires",
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantReviewsPage(restaurantId: restaurant.id))),
        ),
        const SizedBox(height: 32),
        const Divider(),
        ListTile(
          title: const Text("Déconnexion"),
          leading: const Icon(Icons.logout, color: Colors.red),
          onTap: () {}, // implémenter déconnexion
        ),
      ],
    );
  }

  Widget _buildSettingTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant.withOpacity(0.5)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: colors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }
}
