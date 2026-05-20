import 'dart:async';
import 'package:flutter/material.dart';
import 'package:table_master_mobile/core/responsive/breakpoints.dart';
import 'package:table_master_mobile/core/signalr_service.dart';
import 'package:table_master_mobile/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_out.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'package:intl/intl.dart';

import '../data/models/reservation_in.dart';
import '../data/models/search_reservations.dart';
import 'widgets/reservation_card.dart';

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
  final _signalRService = getIt<SignalRService>();
  bool _loading = false;
  String? _error;
  List<ReservationOut> _reservations = [];
  List<ReservationOut> _summaryReservations = []; // Pour les compteurs badges
  int _selectedFilter = 0; // 0: Validées, 1: En attente, 2: Historique

  StreamSubscription? _subCreated;
  StreamSubscription? _subUpdate;
  StreamSubscription? _subDeleted;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _initSignalR();
  }

  @override
  void dispose() {
    _subCreated?.cancel();
    _subUpdate?.cancel();
    _subDeleted?.cancel();
    _signalRService.leaveRestaurantGroup(widget.restaurantId);
    super.dispose();
  }

  Future<void> _initSignalR() async {
    await _signalRService.init();
    await _signalRService.joinRestaurantGroup(widget.restaurantId);

    _subCreated = _signalRService.onReservationCreated.listen((res) {
      if (res.tableId == widget.table.id) {
        _loadAllData();
      }
    });

    _subUpdate = _signalRService.onReservationUpdateStatus.listen((res) {
      if (res.tableId == widget.table.id) {
        _loadAllData();
      }
    });

    _subDeleted = _signalRService.onReservationDeleted.listen((id) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    await _loadSummary();
    await _loadReservations();
  }

  Future<void> _loadSummary() async {
    try {
      SearchReservations search = SearchReservations();
      search.restaurantId = widget.restaurantId;
      search.tableId = widget.table.id;
      search.pageSize = 100;
      search.statuses = [
        ReservationStatus.enAttente,
        ReservationStatus.validee,
      ];
      final results = await _repo.getReservations(search);
      if (mounted) {
        setState(() {
          _summaryReservations = results;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement du résumé des réservations: $e');
    }
  }

  Future<void> _loadReservations() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      SearchReservations search = SearchReservations();
      search.restaurantId = widget.restaurantId;
      search.tableId = widget.table.id;
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
          ReservationStatus.annuleeClient,
        ];
      }

      final results = await _repo.getReservations(search);
      results.sort((a, b) => a.reservationDate.compareTo(b.reservationDate));

      if (mounted) {
        setState(() {
          _reservations = results;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(int id, ReservationStatus status) async {
    try {
      await _repo.updateReservationStatus(id, status);
      await _loadAllData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingTotal =
        _summaryReservations
            .where((r) => r.status == ReservationStatus.enAttente)
            .length;
    final todayTotal =
        _summaryReservations
            .where(
              (r) =>
                  r.status == ReservationStatus.validee &&
                  DateUtils.isSameDay(r.reservationDate, DateTime.now()),
            )
            .length;

    return Scaffold(
      appBar: AppBar(title: Text('Table ${widget.table.tableNumber}')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoints.maxListWidth),
          child: Column(
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
                      if (todayTotal > 0)
                        _buildCountBadge(todayTotal, Colors.blue),
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
                      if (pendingTotal > 0)
                        _buildCountBadge(pendingTotal, Colors.orange),
                    ],
                  ),
                  icon: const Icon(Icons.pending_actions),
                ),
                const ButtonSegment(
                  value: 2,
                  label: Text('Historique'),
                  icon: Icon(Icons.history),
                ),
              ],
              selected: {_selectedFilter},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  _selectedFilter = newSelection.first;
                });
                _loadReservations();
              },
            ),
          ),
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(child: Text('Erreur: $_error'))
                    : _reservations.isEmpty
                    ? const Center(child: Text('Aucune réservation trouvée'))
                    : RefreshIndicator(
                      onRefresh: _loadAllData,
                      child: _buildGroupedListView(),
                    ),
          ),
        ],
          ),
        ),
      ),
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
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGroupedListView() {
    final Map<String, List<ReservationOut>> grouped = {};
    for (var r in _reservations) {
      final dateStr = DateFormat(
        'yyyy-MM-dd',
      ).format(r.reservationDate.toLocal());
      if (!grouped.containsKey(dateStr)) grouped[dateStr] = [];
      grouped[dateStr]!.add(r);
    }

    final sortedKeys = grouped.keys.toList();
    if (_selectedFilter == 2) {
      sortedKeys.sort((a, b) => b.compareTo(a));
    } else {
      sortedKeys.sort((a, b) => a.compareTo(b));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateStr = sortedKeys[index];
        final items = grouped[dateStr]!;
        final displayDate = _getDisplayDate(dateStr);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                displayDate,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            ...items.map(
              (r) => ReservationCard(
                reservation: r,
                onStatusUpdate: (newStatus) => _updateStatus(r.id, newStatus),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  String _getDisplayDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return "AUJOURD'HUI";
    if (date == tomorrow) return "DEMAIN";
    if (date == yesterday) return "HIER";

    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date).toUpperCase();
  }
}
