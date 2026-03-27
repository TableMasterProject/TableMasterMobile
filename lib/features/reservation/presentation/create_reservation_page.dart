import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_out.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_out.dart';

class CreateReservationPage extends StatefulWidget {
  final RestaurantOut restaurant;

  const CreateReservationPage({super.key, required this.restaurant});

  @override
  State<CreateReservationPage> createState() => _CreateReservationPageState();
}

class _CreateReservationPageState extends State<CreateReservationPage> {
  final IReservationRepository _reservationRepo = getIt<IReservationRepository>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _specialRequestController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _numberOfPeople = 2;
  TableEntityOut? _selectedTable;

  bool _isLoading = false;
  List<ReservationOut> _dayReservations = [];
  List<TimeOfDay> _availableSlots = [];

  @override
  void dispose() {
    _scrollController.dispose();
    _specialRequestController.dispose();
    super.dispose();
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

    final activities = widget.restaurant.dailyActivitys?.where((a) => a.dayOfWeek == dayOfWeek).toList() ?? [];

    if (activities.isEmpty || _isDayClosedException(_selectedDate!)) {
      setState(() => _availableSlots = []);
      return;
    }

    List<TimeOfDay> slots = [];
    for (var activity in activities) {
      final start = _parseTimeString(activity.startTime);
      final end = _parseTimeString(activity.endTime);

      DateTime current = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, start.hour, start.minute);
      DateTime endTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, end.hour, end.minute);

      while (current.isBefore(endTime)) {
        final slot = TimeOfDay(hour: current.hour, minute: current.minute);
        if (isToday) {
          if (current.isAfter(now.add(const Duration(minutes: 30)))) slots.add(slot);
        } else {
          slots.add(slot);
        }
        current = current.add(const Duration(minutes: 30));
      }
    }
    slots.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    setState(() {
      _availableSlots = slots;
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
      return (target.isAtSameMomentAs(begin) || target.isAfter(begin)) && (target.isAtSameMomentAs(end) || target.isBefore(end));
    }) ?? false;
  }

  Future<void> _fetchDayReservations() async {
    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final res = await _reservationRepo.getReservationsByRestaurant(widget.restaurant.id, dateStr, null);
      setState(() {
        _dayReservations = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getTableStatus(TableEntityOut table) {
    if (table.numberOfSeats < _numberOfPeople) return "Trop petite";
    if (_selectedTime == null) return "Choisir une heure";

    final reqStart = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute);
    final reqEnd = reqStart.add(const Duration(hours: 3));

    bool isBusy = _dayReservations.any((res) {
      if (res.tableId != table.id) return false;

      // Conversion pour s'assurer qu'on compare en local
      final resStart = res.reservationDate.toLocal();
      final resEnd = resStart.add(const Duration(hours: 3));

      // Algorithme de chevauchement : (Debut1 < Fin2) ET (Fin1 > Debut2)
      return reqStart.isBefore(resEnd) && reqEnd.isAfter(resStart);
    });

    return isBusy ? "Réservée" : "Disponible";
  }

  bool _isDaySelectable(DateTime day) {
    final hasActivity = widget.restaurant.dailyActivitys?.any((a) => a.dayOfWeek == day.weekday) ?? false;
    if (!hasActivity) return false;
    return !_isDayClosedException(day);
  }

  // Trouve le premier jour où le resto est ouvert pour éviter le crash du picker
  DateTime _getFirstValidDate() {
    DateTime date = DateTime.now();
    for (int i = 0; i < 90; i++) {
      DateTime checkDate = date.add(Duration(days: i));
      if (_isDaySelectable(checkDate)) {
        return checkDate;
      }
    }
    return date;
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
              Text(widget.restaurant.restaurantName, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),

              // DATE
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(_selectedDate == null ? "Choisir une date" : DateFormat('EEEE d MMMM', 'fr_FR').format(_selectedDate!)),
                  onTap: () async {
                    final initial = _selectedDate ?? _getFirstValidDate();
                    final date = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                      selectableDayPredicate: _isDaySelectable,
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
                const Text("Nombre de personnes", style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(onPressed: _numberOfPeople > 1 ? () => setState(() { _numberOfPeople--; _selectedTable = null; }) : null, icon: const Icon(Icons.remove)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text("$_numberOfPeople", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                    IconButton.filledTonal(onPressed: () => setState(() { _numberOfPeople++; _selectedTable = null; }), icon: const Icon(Icons.add)),
                  ],
                ),

                const Divider(height: 40),
                const Text("Heure de début (blocage 3h)", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<TimeOfDay>(
                  decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.access_time)),
                  value: _selectedTime,
                  hint: const Text("Sélectionnez l'heure"),
                  items: _availableSlots.map((t) => DropdownMenuItem(value: t, child: Text("${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}"))).toList(),
                  onChanged: (val) => setState(() { _selectedTime = val; _selectedTable = null; }),
                ),

                if (_selectedTime != null) ...[
                  const SizedBox(height: 24),
                  const Text("Choisir une table", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_isLoading) const Center(child: CircularProgressIndicator())
                  else ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.restaurant.tables?.length ?? 0,
                    itemBuilder: (context, index) {
                      final table = widget.restaurant.tables![index];
                      final status = _getTableStatus(table);
                      final isAvailable = status == "Disponible";
                      final isSelected = _selectedTable?.id == table.id;
                      return Card(
                        color: isSelected ? colors.primaryContainer : null,
                        child: ListTile(
                          enabled: isAvailable,
                          leading: Icon(Icons.table_bar, color: isAvailable ? colors.primary : Colors.grey),
                          title: Text("Table n°${table.tableNumber} (${table.numberOfSeats} places)"),
                          subtitle: Text(status, style: TextStyle(color: isAvailable ? Colors.green : Colors.red, fontWeight: isAvailable ? FontWeight.bold : null)),
                          onTap: () => setState(() => _selectedTable = table),
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 24),
                TextField(controller: _specialRequestController, decoration: const InputDecoration(labelText: "Demande spéciale", border: OutlineInputBorder()), maxLines: 2),
                const SizedBox(height: 32),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: (_selectedTable != null && !_isLoading) ? _submitReservation : null,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  child: _isLoading ? const CircularProgressIndicator() : const Text("Confirmer la réservation"),
                )),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReservation() async {
    if (_selectedTable == null || _selectedTime == null || _selectedDate == null) return;

    setState(() => _isLoading = true);
    try {
      final reservationDateTime = DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
        _selectedTime!.hour, _selectedTime!.minute,
      );

      final reservation = ReservationIn(
        userId: 1, // À REMPLACER
        tableId: _selectedTable!.id,
        restaurantId: widget.restaurant.id,
        reservationDate: reservationDateTime,
        numberOfPeople: _numberOfPeople,
        specialRequest: _specialRequestController.text,
      );

      await _reservationRepo.createReservation(reservation.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Réservation réussie !")));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
  }
}