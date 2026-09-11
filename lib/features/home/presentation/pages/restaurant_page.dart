import 'package:table_master_mobile/core/time/paris_time.dart';
import 'package:flutter/material.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'package:table_master_mobile/core/navigation/app_navigation.dart';
import 'package:table_master_mobile/core/responsive/breakpoints.dart';
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
import 'package:table_master_mobile/features/room/data/models/restaurant_room_in.dart';
import 'package:table_master_mobile/features/room/data/models/restaurant_room_out.dart';
import 'package:table_master_mobile/features/room/domain/repositories/room_repository.dart';
import 'package:table_master_mobile/features/room/presentation/widgets/room_plan_canvas.dart';
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
      roomRepository: getIt<IRoomRepository>(),
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
        roomRepository: getIt<IRoomRepository>(),
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
          initialRooms: restaurant.rooms,
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
        const SnackBar(
          content: Text("Informations du restaurant mises à jour."),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _saveTableSettings(TableChanges changes) async {
    AppSavingDialog.show(context);
    try {
      await _controller.saveTableSettings(changes);
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Tables mises à jour.")));
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _openQuickReservation(RestaurantOut restaurant) async {
    final tables = restaurant.tables ?? <TableEntityOut>[];
    if (tables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ajoutez une table avant de réserver.")),
      );
      return;
    }

    final reservation = await showDialog<QuickReservationIn>(
      context: context,
      builder: (context) => _QuickReservationDialog(tables: tables),
    );
    if (reservation == null || !mounted) return;

    AppSavingDialog.show(context);
    try {
      await _controller.createQuickReservation(reservation);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Réservation rapide créée.")),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (widget.user.restaurantId == null &&
            _controller.restaurant == null) {
          return AppEmptyState(
            icon: Icons.restaurant_outlined,
            message: "Aucun restaurant associé",
            action:
                widget.user.accountType == 1
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
            onQuickReservation: () => _openQuickReservation(restaurant),
          ),
        };

        return Column(
          children: [
            _RestaurantTabs(
              selectedIndex: _controller.viewIndex,
              pendingCount:
                  _controller.summaryReservations
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
            _TabButton(
              label: "Tables",
              index: 0,
              selectedIndex: selectedIndex,
              onChanged: onChanged,
            ),
            const SizedBox(width: 8),
            _TabButton(
              label: "Réservations",
              index: 1,
              selectedIndex: selectedIndex,
              badgeCount: pendingCount,
              onChanged: onChanged,
            ),
            const SizedBox(width: 8),
            _TabButton(
              label: "Menu",
              index: 2,
              selectedIndex: selectedIndex,
              onChanged: onChanged,
            ),
            const SizedBox(width: 8),
            _TabButton(
              label: "Paramètres",
              index: 3,
              selectedIndex: selectedIndex,
              onChanged: onChanged,
            ),
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
            backgroundColor:
                isSelected ? colors.primary : colors.surfaceContainerHighest,
            foregroundColor:
                isSelected ? colors.onPrimary : colors.onSurfaceVariant,
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
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
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

class _QuickReservationDialog extends StatefulWidget {
  final List<TableEntityOut> tables;

  const _QuickReservationDialog({required this.tables});

  @override
  State<_QuickReservationDialog> createState() =>
      _QuickReservationDialogState();
}

class _QuickReservationDialogState extends State<_QuickReservationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  late int _tableId;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  int _people = 2;

  @override
  void initState() {
    super.initState();
    _tableId = widget.tables.first.id;
    final now = ParisTime.now().add(const Duration(minutes: 15));
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = ParisTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;

    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked == null) return;

    setState(() => _selectedTime = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (!ParisTime.isValidSlot(
      _selectedDate,
      _selectedTime.hour,
      _selectedTime.minute,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cette heure n'existe pas ou est ambiguë à Paris."),
        ),
      );
      return;
    }
    final date = ParisTime.at(
      _selectedDate,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    if (date.isBefore(ParisTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("La réservation ne peut pas être dans le passé."),
        ),
      );
      return;
    }
    final phone = _phoneController.text.trim();
    final note = _noteController.text.trim();

    Navigator.of(context).pop(
      QuickReservationIn(
        tableId: _tableId,
        reservationDate: date,
        numberOfPeople: _people,
        guestName: _nameController.text.trim(),
        guestPhone: phone.isEmpty ? null : phone,
        specialRequest: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dateLabel = MaterialLocalizations.of(
      context,
    ).formatMediumDate(_selectedDate);
    final timeLabel = _selectedTime.format(context);

    return AlertDialog(
      title: const Text("Réservation rapide"),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _tableId,
                  decoration: const InputDecoration(
                    labelText: "Table",
                    prefixIcon: Icon(Icons.table_restaurant_outlined),
                  ),
                  items:
                      widget.tables
                          .map(
                            (table) => DropdownMenuItem(
                              value: table.id,
                              child: Text(
                                "Table ${table.tableNumber} · ${table.numberOfSeats} places",
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _tableId = value);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(dateLabel),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.schedule_outlined),
                        label: Text(timeLabel),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Nom",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator:
                      (value) =>
                          value == null || value.trim().isEmpty
                              ? "Nom obligatoire"
                              : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Téléphone",
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton.outlined(
                      tooltip: "Retirer un convive",
                      onPressed:
                          _people > 1
                              ? () => setState(() => _people -= 1)
                              : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Expanded(
                      child: Text(
                        "$_people convive${_people > 1 ? 's' : ''}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton.outlined(
                      tooltip: "Ajouter un convive",
                      onPressed: () => setState(() => _people += 1),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Note",
                    prefixIcon: Icon(Icons.note_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Annuler"),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check),
          label: const Text("Créer"),
        ),
      ],
    );
  }
}

class _TablesView extends StatefulWidget {
  final RestaurantOut restaurant;
  final List<ReservationOut> summaryReservations;
  final Future<void> Function() onTableChanged;
  final VoidCallback onQuickReservation;

  const _TablesView({
    required this.restaurant,
    required this.summaryReservations,
    required this.onTableChanged,
    required this.onQuickReservation,
  });

  @override
  State<_TablesView> createState() => _TablesViewState();
}

class _TablesViewState extends State<_TablesView> {
  List<RestaurantRoomOut> _roomsForPlan() {
    final rooms = widget.restaurant.rooms;
    if (rooms != null && rooms.isNotEmpty) return rooms;

    return [
      RestaurantRoomOut(
        id: 0,
        restaurantId: widget.restaurant.id,
        name: 'Salle principale',
        sortOrder: 0,
        boundaryPoints: RestaurantRoomIn.defaultRoom().boundaryPoints,
        createdAt: ParisTime.now(),
      ),
    ];
  }

  List<TableEntityOut> _tablesForRoom(RestaurantRoomOut room) {
    final tables = widget.restaurant.tables ?? <TableEntityOut>[];
    return tables
        .where(
          (table) =>
              table.roomId == room.id || (room.id == 0 && table.roomId == null),
        )
        .toList();
  }

  List<ReservationOut> _reservationsForTable(TableEntityOut table) {
    return widget.summaryReservations
        .where((reservation) => reservation.tableId == table.id)
        .toList();
  }

  String _tableStatusLabel(TableEntityOut table, DateTime now) {
    final reservations = _reservationsForTable(table);
    final pendingCount =
        reservations
            .where(
              (reservation) =>
                  reservation.status == ReservationStatus.enAttente,
            )
            .length;
    final todayValidatedCount =
        reservations
            .where(
              (reservation) =>
                  reservation.status == ReservationStatus.validee &&
                  DateUtils.isSameDay(reservation.reservationDate, now),
            )
            .length;

    if (pendingCount > 0 && todayValidatedCount > 0) {
      return '$pendingCount att. / $todayValidatedCount valid.';
    }
    if (pendingCount > 0) return '$pendingCount attente';
    if (todayValidatedCount > 0) return '$todayValidatedCount validee';
    return '';
  }

  Future<void> _openTable(TableEntityOut table) async {
    await AppNavigation.push<void>(
      context,
      TableReservationsPage(restaurantId: widget.restaurant.id, table: table),
    );
    await widget.onTableChanged();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tables = widget.restaurant.tables ?? <TableEntityOut>[];
    final rooms = _roomsForPlan();
    final now = ParisTime.now();

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: Breakpoints.maxContentWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Gestion des tables",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: widget.onQuickReservation,
                    icon: const Icon(Icons.add),
                    label: const Text("Réservation"),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child:
                    tables.isEmpty
                        ? const AppEmptyState(
                          icon: Icons.table_bar_outlined,
                          message: "Aucune table configurée",
                        )
                        : _RoomTablePlan(
                          rooms: rooms,
                          reservationsForTable: _reservationsForTable,
                          now: now,
                          onTableSelected: _openTable,
                          tablesForRoom: _tablesForRoom,
                          tableStatusLabel: _tableStatusLabel,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomTablePlan extends StatelessWidget {
  final List<RestaurantRoomOut> rooms;
  final List<ReservationOut> Function(TableEntityOut table)
  reservationsForTable;
  final List<TableEntityOut> Function(RestaurantRoomOut room) tablesForRoom;
  final String Function(TableEntityOut table, DateTime now) tableStatusLabel;
  final DateTime now;
  final ValueChanged<TableEntityOut> onTableSelected;

  const _RoomTablePlan({
    required this.rooms,
    required this.reservationsForTable,
    required this.tablesForRoom,
    required this.tableStatusLabel,
    required this.now,
    required this.onTableSelected,
  });

  @override
  Widget build(BuildContext context) {
    final useTwoColumnLayout = context.isDesktop && rooms.length > 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!useTwoColumnLayout) {
          return ListView(
            children: [
              ...rooms.map(_buildRoomSection),
              const SizedBox(height: 4),
              const _TableLegend(),
            ],
          );
        }

        const spacing = 16.0;
        final tileWidth = (constraints.maxWidth - spacing) / 2;
        final tileHeight = (tileWidth / 1.25) + 86;

        return CustomScrollView(
          slivers: [
            SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: tileWidth / tileHeight,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildRoomSection(rooms[index], bottomPadding: 0),
                childCount: rooms.length,
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 4),
                child: _TableLegend(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRoomSection(
    RestaurantRoomOut room, {
    double bottomPadding = 18,
  }) {
    return _RoomPlanSection(
      room: room,
      roomTables: tablesForRoom(room),
      reservationsForTable: reservationsForTable,
      tableStatusLabel: tableStatusLabel,
      now: now,
      onTableSelected: onTableSelected,
      bottomPadding: bottomPadding,
    );
  }
}

class _TableLegend extends StatelessWidget {
  const _TableLegend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _TableBadge(
          text: "validées aujourd'hui",
          color: Colors.blue,
          icon: Icons.event,
        ),
        _TableBadge(
          text: 'en attente',
          color: Colors.orange,
          icon: Icons.pending_actions,
        ),
      ],
    );
  }
}

class _RoomPlanSection extends StatelessWidget {
  final RestaurantRoomOut room;
  final List<TableEntityOut> roomTables;
  final List<ReservationOut> Function(TableEntityOut table)
  reservationsForTable;
  final String Function(TableEntityOut table, DateTime now) tableStatusLabel;
  final DateTime now;
  final ValueChanged<TableEntityOut> onTableSelected;
  final double bottomPadding;

  const _RoomPlanSection({
    required this.room,
    required this.roomTables,
    required this.reservationsForTable,
    required this.tableStatusLabel,
    required this.now,
    required this.onTableSelected,
    this.bottomPadding = 18,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tableStatuses = {
      for (final table in roomTables) table.id: tableStatusLabel(table, now),
    };
    final pendingBadgeCounts = <int, int>{};
    final validatedBadgeCounts = <int, int>{};

    for (final table in roomTables) {
      final reservations = reservationsForTable(table);
      pendingBadgeCounts[table.id] =
          reservations
              .where(
                (reservation) =>
                    reservation.status == ReservationStatus.enAttente,
              )
              .length;
      validatedBadgeCounts[table.id] =
          reservations
              .where(
                (reservation) =>
                    reservation.status == ReservationStatus.validee &&
                    DateUtils.isSameDay(reservation.reservationDate, now),
              )
              .length;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  room.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${roomTables.length} table${roomTables.length > 1 ? 's' : ''}',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (roomTables.isEmpty)
            Text(
              "Aucune table dans cette salle",
              style: TextStyle(color: colors.onSurfaceVariant),
            )
          else
            RoomPlanCanvas(
              boundaryPoints: room.boundaryPoints,
              tables: roomTables,
              tableStatuses: tableStatuses,
              pendingBadgeCounts: pendingBadgeCounts,
              validatedBadgeCounts: validatedBadgeCounts,
              disableUnavailableTables: false,
              onTableSelected: (table) {
                if (table is TableEntityOut) onTableSelected(table);
              },
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
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
    final pendingTotal =
        summaryReservations
            .where(
              (reservation) =>
                  reservation.status == ReservationStatus.enAttente,
            )
            .length;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Breakpoints.maxListWidth),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(
                    label: "Validées",
                    index: 0,
                    selectedFilter: selectedFilter,
                    onChanged: onFilterChanged,
                  ),
                  _FilterChip(
                    label: "En attente ($pendingTotal)",
                    index: 1,
                    selectedFilter: selectedFilter,
                    onChanged: onFilterChanged,
                  ),
                  _FilterChip(
                    label: "Historique",
                    index: 2,
                    selectedFilter: selectedFilter,
                    onChanged: onFilterChanged,
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  reservations.isEmpty
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
                              onStatusUpdate:
                                  (newStatus) =>
                                      onStatusUpdate(reservation.id, newStatus),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
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

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Breakpoints.maxGridWidth),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Votre menu",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () async {
                      await AppNavigation.push<void>(
                        context,
                        MenuPage(restaurantId: restaurantId),
                      );
                      await onMenuChanged();
                    },
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child:
                    menuItems.isEmpty
                        ? const AppEmptyState(
                          icon: Icons.restaurant_menu,
                          message: "Aucun plat ajouté au menu",
                        )
                        : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 240,
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
                                side: BorderSide(
                                  color: colors.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        color: colors.secondaryContainer
                                            .withValues(alpha: 0.3),
                                        child: const Icon(
                                          Icons.restaurant_menu,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.itemName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          "${item.price.toStringAsFixed(2)} €",
                                          style: TextStyle(
                                            color: colors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
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
        ),
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
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: Breakpoints.maxContentWidth,
        ),
        child: ListView(
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
              onTap:
                  () => AppNavigation.push<void>(
                    context,
                    HourlyActivityPage(restaurantId: restaurant.id),
                  ),
            ),
            AppSettingTile(
              icon: Icons.calendar_today_outlined,
              title: "Fermetures exceptionnelles",
              subtitle: "Gérer les jours fériés et vacances",
              onTap:
                  () => AppNavigation.push<void>(
                    context,
                    ExceptionsPage(restaurantId: restaurant.id),
                  ),
            ),
            AppSettingTile(
              icon: Icons.star_outline_rounded,
              title: "Avis clients",
              subtitle: "Consulter les notes et commentaires",
              onTap:
                  () => AppNavigation.push<void>(
                    context,
                    RestaurantReviewsPage(restaurantId: restaurant.id),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsStepPage extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsStepPage({required this.title, required this.child});

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
