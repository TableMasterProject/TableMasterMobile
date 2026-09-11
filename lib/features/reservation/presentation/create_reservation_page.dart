import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'package:table_master_mobile/core/signalr_service.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_availability_out.dart';
import 'package:table_master_mobile/features/reservation/data/models/search_reservations.dart';
import 'package:table_master_mobile/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_out.dart';
import 'package:table_master_mobile/features/room/data/models/restaurant_room_in.dart';
import 'package:table_master_mobile/features/room/data/models/restaurant_room_out.dart';
import 'package:table_master_mobile/features/room/presentation/widgets/room_plan_canvas.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_out.dart';

class CreateReservationPage extends StatefulWidget {
  final RestaurantOut restaurant;

  const CreateReservationPage({super.key, required this.restaurant});

  @override
  State<CreateReservationPage> createState() => _CreateReservationPageState();
}

class _CreateReservationPageState extends State<CreateReservationPage> {
  final IReservationRepository _reservationRepo =
      getIt<IReservationRepository>();
  final SignalRService _signalRService = getIt<SignalRService>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _specialRequestController =
      TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _numberOfPeople = 2;
  TableEntityOut? _selectedTable;
  int _selectedRoomIndex = 0;

  bool _isLoading = false;
  List<ReservationAvailabilityOut> _dayReservations = [];
  List<TimeOfDay> _availableSlots = [];
  StreamSubscription? _subUpdate;
  StreamSubscription? _subDeleted;

  @override
  void initState() {
    super.initState();
    _initSignalR();
  }

  @override
  void dispose() {
    _subUpdate?.cancel();
    _subDeleted?.cancel();
    _signalRService.leaveRestaurantGroup(widget.restaurant.id);
    _scrollController.dispose();
    _specialRequestController.dispose();
    super.dispose();
  }

  Future<void> _initSignalR() async {
    // Les abonnements sont posés avant la connexion : sinon les événements
    // reçus pendant l'établissement du lien sont perdus, et un dispose()
    // survenant entre-temps annulerait des abonnements encore nuls, créés
    // juste après et jamais libérés.

    // Écoute des mises à jour de statut (validation/annulation)
    _subUpdate = _signalRService.onReservationUpdateStatus.listen((res) {
      if (res.restaurantId == widget.restaurant.id && _selectedDate != null) {
        if (DateUtils.isSameDay(res.reservationDate, _selectedDate)) {
          _fetchDayReservations();
        }
      }
    });

    _subDeleted = _signalRService.onReservationDeleted.listen((id) {
      _fetchDayReservations();
    });

    // joinRestaurantGroup établit la connexion si nécessaire.
    await _signalRService.joinRestaurantGroup(widget.restaurant.id);
  }

  // --- Logique métier ---

  Future<void> _loadDayData() async {
    if (_selectedDate == null) return;
    _updateAvailableSlots();
    await _fetchDayReservations();
  }

  void _updateAvailableSlots() {
    if (_selectedDate == null) return;
    final dayOfWeek = _selectedDate!.weekday;
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(_selectedDate, now);

    final activities =
        widget.restaurant.dailyActivitys
            ?.where((a) => a.dayOfWeek == dayOfWeek)
            .toList() ??
        [];

    if (activities.isEmpty || _isDayClosedException(_selectedDate!)) {
      setState(() => _availableSlots = []);
      return;
    }

    List<TimeOfDay> slots = [];
    for (var activity in activities) {
      final start = _parseTimeString(activity.startTime);
      final end = _parseTimeString(activity.endTime);

      DateTime current = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        start.hour,
        start.minute,
      );
      DateTime endTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        end.hour,
        end.minute,
      );

      while (current.isBefore(endTime)) {
        final slot = TimeOfDay(hour: current.hour, minute: current.minute);

        if (isToday) {
          if (current.isAfter(now.add(const Duration(minutes: 30)))) {
            slots.add(slot);
          }
        } else {
          slots.add(slot);
        }
        current = current.add(const Duration(minutes: 30));
      }
    }

    slots.sort(
      (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
    );

    setState(() {
      _availableSlots = List.from(slots);
      _selectedTime = null;
      _selectedTable = null;
    });
  }

  TimeOfDay _parseTimeString(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool _isDayClosedException(DateTime date) {
    return widget.restaurant.closedDayExceptions?.any((e) {
          final target = DateUtils.dateOnly(date);
          final begin = DateUtils.dateOnly(e.exceptionDateBegin);
          final end = DateUtils.dateOnly(e.exceptionDateEnd);
          return (target.isAtSameMomentAs(begin) || target.isAfter(begin)) &&
              (target.isAtSameMomentAs(end) || target.isBefore(end));
        }) ??
        false;
  }

  Future<void> _fetchDayReservations() async {
    if (_selectedDate == null) return;
    setState(() => _isLoading = true);
    try {
      SearchReservations searchReservations = SearchReservations();
      searchReservations.restaurantId = widget.restaurant.id;
      searchReservations.minDate = _selectedDate;
      searchReservations.maxDate = _selectedDate;
      searchReservations.statuses = [ReservationStatus.validee];
      final res = await _reservationRepo.getAvailability(searchReservations);
      if (mounted) {
        setState(() {
          _dayReservations = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getTableStatus(TableEntityOut table) {
    if (table.numberOfSeats < _numberOfPeople) return "Trop petite";
    if (_selectedTime == null) return "Choisir une heure";

    final reqStart = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    const safetyMargin = Duration(minutes: 90);

    bool isBusy = _dayReservations.any((res) {
      if (res.tableId != table.id) return false;

      final resStart = res.reservationDate.toLocal();
      final conflictStart = resStart.subtract(safetyMargin);
      final conflictEnd = resStart.add(safetyMargin);

      return (reqStart.isAfter(conflictStart) &&
              reqStart.isBefore(conflictEnd)) ||
          reqStart.isAtSameMomentAs(resStart);
    });

    return isBusy ? "Déjà réservée" : "Disponible";
  }

  bool _isDaySelectable(DateTime day) {
    final hasActivity =
        widget.restaurant.dailyActivitys?.any(
          (a) => a.dayOfWeek == day.weekday,
        ) ??
        false;
    if (!hasActivity) return false;
    return !_isDayClosedException(day);
  }

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
        createdAt: DateTime.now(),
      ),
    ];
  }

  DateTime _getFirstValidDate() {
    final today = DateUtils.dateOnly(DateTime.now());
    for (int i = 0; i < 90; i++) {
      DateTime checkDate = today.add(Duration(days: i));
      if (_isDaySelectable(checkDate)) {
        return checkDate;
      }
    }
    return today;
  }

  Widget _buildRoomSelectionPlan(ColorScheme colors) {
    final rooms = _roomsForPlan();
    if (_selectedRoomIndex >= rooms.length) _selectedRoomIndex = 0;

    final room = rooms[_selectedRoomIndex];
    final allTables = widget.restaurant.tables ?? [];
    final roomTables =
        allTables
            .where(
              (table) =>
                  table.roomId == room.id ||
                  (room.id == 0 && table.roomId == null),
            )
            .toList();
    final statuses = {
      for (final table in roomTables) table.id: _getTableStatus(table),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                rooms.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: entry.key == _selectedRoomIndex,
                      label: Text(entry.value.name),
                      onSelected:
                          (_) => setState(() {
                            _selectedRoomIndex = entry.key;
                            _selectedTable = null;
                          }),
                    ),
                  );
                }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        RoomPlanCanvas(
          boundaryPoints: room.boundaryPoints,
          tables: roomTables,
          selectedTableId: _selectedTable?.id,
          tableStatuses: statuses,
          onTableSelected: (table) {
            if (table is! TableEntityOut) return;
            if (_getTableStatus(table) != 'Disponible') return;
            setState(() => _selectedTable = table);
          },
        ),
        const SizedBox(height: 8),
        if (_selectedTable != null)
          Text(
            'Table n°${_selectedTable!.tableNumber} sélectionnée (${_selectedTable!.numberOfSeats} places)',
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text("Réserver une table")),
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.restaurant.restaurantName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    _selectedDate == null
                        ? "Choisir une date"
                        : DateFormat(
                          'EEEE d MMMM',
                          'fr_FR',
                        ).format(_selectedDate!),
                  ),
                  onTap: () async {
                    if (widget.restaurant.dailyActivitys == null ||
                        widget.restaurant.dailyActivitys!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Ce restaurant n'a pas d'horaires configurés.",
                          ),
                        ),
                      );
                      return;
                    }

                    final now = DateTime.now();
                    final firstDate = DateUtils.dateOnly(now);
                    final lastDate = firstDate.add(const Duration(days: 90));

                    DateTime initial = _selectedDate ?? _getFirstValidDate();
                    if (initial.isBefore(firstDate)) initial = firstDate;
                    if (initial.isAfter(lastDate)) initial = lastDate;

                    final date = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: firstDate,
                      lastDate: lastDate,
                      selectableDayPredicate: _isDaySelectable,
                      locale: const Locale('fr', 'FR'),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                        _selectedTime = null;
                        _selectedTable = null;
                      });
                      _loadDayData();
                    }
                  },
                ),
              ),

              if (_selectedDate != null) ...[
                const SizedBox(height: 20),
                const Text(
                  "Heure de début (blocage 1h30 avant/après)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<TimeOfDay>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  initialValue: _selectedTime,
                  hint: const Text("Sélectionnez l'heure"),
                  items:
                      _availableSlots
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(
                                "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}",
                              ),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (val) => setState(() {
                        _selectedTime = val;
                        _selectedTable = null;
                      }),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Nombre de personnes",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      onPressed:
                          _numberOfPeople > 1
                              ? () => setState(() {
                                _numberOfPeople--;
                                _selectedTable = null;
                              })
                              : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "$_numberOfPeople",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed:
                          () => setState(() {
                            _numberOfPeople++;
                            _selectedTable = null;
                          }),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),

                const Divider(height: 40),

                if (_selectedTime != null) ...[
                  const SizedBox(height: 24),
                  const Text(
                    "Choisir une table",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    _buildRoomSelectionPlan(colors),
                ],

                const SizedBox(height: 24),
                TextField(
                  controller: _specialRequestController,
                  decoration: const InputDecoration(
                    labelText: "Demande spéciale",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        (_selectedTable != null && !_isLoading)
                            ? _submitReservation
                            : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator()
                            : const Text("Confirmer la réservation"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReservation() async {
    if (_selectedTable == null ||
        _selectedTime == null ||
        _selectedDate == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final reservationDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final reservation = ReservationIn(
        userId: 0,
        tableId: _selectedTable!.id,
        restaurantId: widget.restaurant.id,
        reservationDate: reservationDateTime,
        numberOfPeople: _numberOfPeople,
        status: ReservationStatus.enAttente,
        specialRequest: _specialRequestController.text,
      );

      await _reservationRepo.createReservation(reservation.toJson());

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Réservation réussie !")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
      }
    }
  }
}
