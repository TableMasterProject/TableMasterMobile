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
import 'package:table_master_mobile/features/table/data/models/table_entity_in.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_out.dart';
import 'package:table_master_mobile/features/table/domain/repositories/table_repository.dart';
import 'package:table_master_mobile/features/menu/data/models/menu_out.dart';
import 'package:table_master_mobile/features/menu/domain/repositories/menu_repository.dart';
import 'package:table_master_mobile/features/menu/presentation/menu_page.dart';
import 'package:table_master_mobile/features/daily_activity/presentation/hourly_activity_page.dart';
import 'package:table_master_mobile/features/closed_day_exception/presentation/exceptions_page.dart';
import 'package:table_master_mobile/features/review/presentation/pages/restaurant_reviews_page.dart';

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
  List<ReservationOut> _dailyReservations = [];
  List<MenuOut> _menuItems = [];

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
      await _loadDailyReservations(r.id);
      await _loadMenu(r.id);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadDailyReservations(int restaurantId) async {
    try {
      final today = DateTime.now();
      final dateStr =
          "${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      final validated = await _reservationRepo.getReservationsByRestaurant(
        restaurantId,
        dateStr,
        null,
      );

      final pending = await _reservationRepo.GetPendingReservationsByRestaurant(
        restaurantId,
        null,
      );

      final all = [...pending, ...validated];
      all.sort((a, b) => a.reservationDate.compareTo(b.reservationDate));

      setState(() => _dailyReservations = all);
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

  Future<void> _validate(int id, bool isValidate) async {
    try {
      await _reservationRepo.validateReservation(id, isValidate);
      if (_restaurant != null) {
        await _loadDailyReservations(_restaurant!.id);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _delete(int id) async {
    try {
      await _reservationRepo.deleteReservation(id);
      if (_restaurant != null) {
        await _loadDailyReservations(_restaurant!.id);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
            Text(
              "Aucun restaurant associé",
              style: TextStyle(fontSize: 18, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Erreur: $_error'));
    if (_restaurant == null) {
      return const Center(child: Text('Aucun détail de restaurant disponible'));
    }

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
        foregroundColor:
            isSelected ? colors.onPrimary : colors.onSurfaceVariant,
      ),
      child: Text(label),
    );
  }

  Widget _buildTablesView(ColorScheme colors, RestaurantOut restaurant) {
    final tables = restaurant.tables ?? [];
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tables",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: tables.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final t = tables[index];
                final tableReservations =
                    _dailyReservations.where((r) => r.tableId == t.id).toList();

                final pendingCount =
                    tableReservations.where((r) => !r.isValidate).length;
                final totalToday =
                    tableReservations
                        .where(
                          (r) =>
                              r.isValidate &&
                              DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(r.reservationDate.toLocal()) ==
                                  todayStr,
                        )
                        .length;

                return ListTile(
                  title: Text(
                    "Table ${t.tableNumber}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("${t.numberOfSeats} sièges"),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "$totalToday rés. aujourd'hui",
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (pendingCount > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.errorContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "$pendingCount en attente",
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onErrorContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => TableReservationsPage(
                              restaurantId: restaurant.id,
                              table: t,
                            ),
                      ),
                    );
                    _loadDailyReservations(restaurant.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsView(ColorScheme colors) {
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final pending = _dailyReservations.where((r) => !r.isValidate).toList();
    final validated = _dailyReservations.where((r) => r.isValidate).toList();

    final Map<String, List<ReservationOut>> grouped = {};
    for (var r in validated) {
      final key = DateFormat('yyyy-MM-dd').format(r.reservationDate.toLocal());
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(r);
    }
    final sortedDates = grouped.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: RefreshIndicator(
        onRefresh: () => _loadDailyReservations(_restaurant!.id),
        child: ListView(
          children: [
            Text(
              "Réservations",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            _buildSectionHeader('En attente', colors),
            const SizedBox(height: 8),
            if (pending.isEmpty)
              _buildEmptyText('Aucune réservation en attente', colors),
            ...pending.map(
              (r) => _buildReservationCard(
                r,
                colors,
                timeFormat,
                dateFormat,
                true,
              ),
            ),

            const SizedBox(height: 16),

            ...sortedDates.map((dateKey) {
              final isToday = dateKey == todayStr;
              final title =
                  isToday
                      ? "Validées - Aujourd'hui"
                      : "Validées - ${dateFormat.format(DateTime.parse(dateKey))}";
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(title, colors),
                  const SizedBox(height: 8),
                  ...grouped[dateKey]!.map(
                    (r) => _buildReservationCard(
                      r,
                      colors,
                      timeFormat,
                      dateFormat,
                      false,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }),

            if (validated.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Validées', colors),
                  const SizedBox(height: 8),
                  _buildEmptyText('Aucune réservation validée', colors),
                ],
              ),
          ],
        ),
      ),
    );
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
              Text(
                "Menu de l'établissement",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MenuPage(restaurantId: _restaurant!.id),
                    ),
                  );
                  _loadMenu(_restaurant!.id);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_menuItems.isEmpty)
            const Expanded(
              child: Center(child: Text("Aucun plat enregistré dans le menu")),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        item.itemName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(item.description),
                      trailing: Text(
                        "${item.price.toStringAsFixed(2)}€",
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colors) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colors.onSurface,
      ),
    );
  }

  Widget _buildEmptyText(String text, ColorScheme colors) {
    return Text(text, style: TextStyle(color: colors.onSurfaceVariant));
  }

  Widget _buildReservationCard(
    ReservationOut r,
    ColorScheme colors,
    DateFormat timeFormat,
    DateFormat dateFormat,
    bool isPending,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          r.user?.firstName ?? r.user?.email ?? 'Client',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPending)
              Text('Date : ${dateFormat.format(r.reservationDate.toLocal())}'),
            Text('Heure : ${timeFormat.format(r.reservationDate.toLocal())}'),
            Text('Nombre de personnes : ${r.numberOfPeople}'),
            if (r.specialRequest != null && r.specialRequest!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Demande : ${r.specialRequest}',
                  style: TextStyle(
                    color: colors.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            Text('Table : ${r.table?.tableNumber ?? 'N/A'}'),
          ],
        ),
        trailing:
            isPending
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => _validate(r.id, true),
                    ),
                    IconButton(
                      icon: Icon(Icons.cancel, color: colors.error),
                      onPressed: () => _delete(r.id),
                    ),
                  ],
                )
                : const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  Widget _buildSettingsView(
    BuildContext context,
    ColorScheme colors,
    RestaurantOut restaurant,
  ) {
    final days = [
      "Lundi",
      "Mardi",
      "Mercredi",
      "Jeudi",
      "Vendredi",
      "Samedi",
      "Dimanche",
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Paramètres du restaurant",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          _buildInfoCard(colors, "Informations Générales", [
            _buildInfoRow("Nom", restaurant.restaurantName),
            _buildInfoRow(
              "Créé le",
              DateFormat('dd/MM/yyyy').format(restaurant.createdAt),
            ),
            _buildInfoRow("Cuisine", restaurant.cuisineType),
            _buildInfoRow("Paiements", restaurant.paymentMethods),
            _buildInfoRow(
              "Note Moyenne",
              "${restaurant.averageRating.toStringAsFixed(1)} / 5 (${restaurant.numberOfReviews} avis)",
            ),
          ]),

          const SizedBox(height: 12),

          _buildInfoCard(colors, "Contact & Localisation", [
            _buildInfoRow(
              "Adresse",
              "${restaurant.streetNumber} ${restaurant.streetName}",
            ),
            _buildInfoRow(
              "Ville",
              "${restaurant.postalCode} ${restaurant.city}",
            ),
            _buildInfoRow("Téléphone", restaurant.phone),
            _buildInfoRow(
              "Validation Auto",
              restaurant.isAutoValidateReservation ? "Activée" : "Désactivée",
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                "Description : ${restaurant.description}",
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ]),

          const SizedBox(height: 12),

          // Horaires d'ouverture (DailyActivityOut)
          _buildInfoCard(colors, "Horaires d'ouverture", [
            if (restaurant.dailyActivitys == null ||
                restaurant.dailyActivitys!.isEmpty)
              const Text(
                "Aucun horaire configuré",
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              )
            else
              ...restaurant.dailyActivitys!.map(
                (a) => _buildInfoRow(
                  days[(a.dayOfWeek - 1) % 7],
                  "${a.startTime.substring(0, 5)} - ${a.endTime.substring(0, 5)}",
                ),
              ),
          ]),

          const SizedBox(height: 12),

          // Fermetures exceptionnelles (ClosedDayExceptionOut)
          _buildInfoCard(colors, "Fermetures exceptionnelles", [
            if (restaurant.closedDayExceptions == null ||
                restaurant.closedDayExceptions!.isEmpty)
              const Text(
                "Aucune exception configurée",
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              )
            else
              ...restaurant.closedDayExceptions!.map(
                (e) => _buildInfoRow(
                  DateFormat('dd/MM/yy').format(e.exceptionDateBegin),
                  "${e.reason} (${DateFormat('dd/MM/yy').format(e.exceptionDateEnd)})",
                ),
              ),
          ]),

          const SizedBox(height: 24),

          _buildSettingsButton(
            context,
            "Modifier le restaurant",
            Icons.edit,
            () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => Scaffold(
                        appBar: AppBar(
                          title: const Text("Modifier le restaurant"),
                        ),
                        body: Step4RestaurantInfoScreen(
                          onNext: (updatedData) async {
                            try {
                              await repo.updateRestaurant(
                                restaurant.id,
                                updatedData,
                              );
                              Navigator.pop(context);
                              _loadRestaurantIfNeeded();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur: $e')),
                              );
                            }
                          },
                          restaurantIn: restaurant,
                        ),
                      ),
                ),
              );
            },
          ),
          _buildSettingsButton(
            context,
            "Modifier horaires / activité",
            Icons.access_time,
            () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => HourlyActivityPage(restaurantId: restaurant.id),
                ),
              );
              _loadRestaurantIfNeeded();
            },
          ),
          _buildSettingsButton(
            context,
            "Exceptions de fermeture",
            Icons.event_busy,
            () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExceptionsPage(restaurantId: restaurant.id),
                ),
              );
              _loadRestaurantIfNeeded();
            },
          ),
          _buildSettingsButton(
            context,
            "Modifier les tables",
            Icons.table_restaurant,
            () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => Scaffold(
                        appBar: AppBar(
                          title: const Text("Modifier les tables"),
                        ),
                        body: Step5TableManagementScreen(
                          onNext: (newTables) async {
                            try {
                              for (var t in newTables.toAdd) {
                                await _tableRepo.addTable(_restaurant!.id, t);
                              }
                              // Normalement vide en création mais par sécurité :
                              for (var t in newTables.toUpdate) {
                                await _tableRepo.editTable(t.id, t);
                              }
                              for (var t in newTables.toDelete) {
                                await _tableRepo.removeTable(t.id);
                              }

                              Navigator.pop(context);
                              _loadRestaurantIfNeeded();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur: $e')),
                              );
                            }
                          },
                          initialTables: restaurant.tables,
                        ),
                      ),
                ),
              );
            },
          ),
          _buildSettingsButton(
            context,
            "Avis du restaurant",
            Icons.reviews,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => RestaurantReviewsPage(
                        restaurantId: widget.user.restaurantId!,
                      ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    ColorScheme colors,
    String title,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label :",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        ),
      ),
    );
  }
}
