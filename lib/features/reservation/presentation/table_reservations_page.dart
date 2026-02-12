import 'package:flutter/material.dart';
import 'package:table_master_mobile/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_out.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'package:intl/intl.dart';

class TableReservationsPage extends StatefulWidget {
  final int restaurantId;
  final TableEntityOut table;

  const TableReservationsPage({
    super.key,
    required this.restaurantId,
    required this.table,
  });

  @override
  State<TableReservationsPage> createState() => _TableReservationsPageState();
}

class _TableReservationsPageState extends State<TableReservationsPage> {
  final _repo = getIt<IReservationRepository>();
  bool _loading = false;
  String? _error;
  List<ReservationOut> _pending = [];
  List<ReservationOut> _validated = [];

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final today = DateTime.now();
      final dateStr =
          "${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      
      final validated = await _repo.getReservationsByRestaurant(
        widget.restaurantId,
        dateStr,
        widget.table.id,
      );
      final pending = await _repo.GetPendingReservationsByRestaurant(
        widget.restaurantId,
        widget.table.id,
      );

      // Tri chronologique
      validated.sort((a, b) => a.reservationDate.compareTo(b.reservationDate));
      pending.sort((a, b) => a.reservationDate.compareTo(b.reservationDate));

      setState(() {
        _pending = pending;
        _validated = validated;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _validate(int id, bool isValidate) async {
    try {
      await _repo.validateReservation(id, isValidate);
      await _loadReservations();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _delete(int id) async {
    try {
      await _repo.deleteReservation(id);
      await _loadReservations();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Grouping validated reservations by date
    final Map<String, List<ReservationOut>> grouped = {};
    for (var r in _validated) {
      final key = DateFormat('yyyy-MM-dd').format(r.reservationDate.toLocal());
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(r);
    }

    final sortedDates = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text('Réservations — Table ${widget.table.tableNumber}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Erreur: $_error'))
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildSectionHeader('En attente', colors),
                    const SizedBox(height: 8),
                    if (_pending.isEmpty)
                      _buildEmptyText('Aucune réservation en attente', colors),
                    ..._pending.map((r) => _buildReservationCard(r, colors, timeFormat, dateFormat, true)),
                    
                    const SizedBox(height: 24),
                    
                    ...sortedDates.map((dateKey) {
                      final isToday = dateKey == todayStr;
                      final title = isToday ? "Validées - Aujourd'hui" : "Validées - ${dateFormat.format(DateTime.parse(dateKey))}";
                      final reservations = grouped[dateKey]!;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(title, colors),
                          const SizedBox(height: 8),
                          ...reservations.map((r) => _buildReservationCard(r, colors, timeFormat, dateFormat, false)),
                          const SizedBox(height: 16),
                        ],
                      );
                    }),
                    
                    if (_validated.isEmpty)
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
    return Text(
      text,
      style: TextStyle(color: colors.onSurfaceVariant),
    );
  }

  Widget _buildReservationCard(ReservationOut r, ColorScheme colors, DateFormat timeFormat, DateFormat dateFormat, bool isPending) {
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
          ],
        ),
        trailing: isPending
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
}
