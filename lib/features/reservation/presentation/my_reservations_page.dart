import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_master_mobile/core/signalr_service.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/reservation/data/models/search_reservations.dart';
import 'package:table_master_mobile/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:table_master_mobile/core/injection.dart';
import '../data/models/reservation_in.dart';
import 'reservation_detail_page.dart';
import 'widgets/reservation_card.dart';

class MyReservationsPage extends StatefulWidget {
  final int userId;

  const MyReservationsPage({super.key, required this.userId});

  @override
  State<MyReservationsPage> createState() => _MyReservationsPageState();
}

class _MyReservationsPageState extends State<MyReservationsPage> {
  late IReservationRepository _repository;
  final _signalRService = getIt<SignalRService>();
  List<ReservationOut> _reservations = [];
  List<ReservationOut> _summaryReservations = []; 
  bool _isLoading = false;
  String? _error;
  int _selectedFilter = 0; // 0: Validées, 1: En attente, 2: Historique

  StreamSubscription? _subCreated;
  StreamSubscription? _subUpdate;
  StreamSubscription? _subDeleted;

  @override
  void initState() {
    super.initState();
    _repository = getIt<IReservationRepository>();
    _loadAllData();
    _initSignalR();
  }

  @override
  void dispose() {
    _subCreated?.cancel();
    _subUpdate?.cancel();
    _subDeleted?.cancel();
    _signalRService.leaveUserGroup(widget.userId);
    super.dispose();
  }

  Future<void> _initSignalR() async {
    await _signalRService.init();
    await _signalRService.joinUserGroup(widget.userId);

    _subCreated = _signalRService.onReservationCreated.listen((res) {
      if (res.userId == widget.userId) {
        _loadAllData();
      }
    });

    _subUpdate = _signalRService.onReservationUpdateStatus.listen((res) {
      if (res.userId == widget.userId) {
        _loadAllData();
        _showStatusUpdateSnackBar(res);
      }
    });

    _subDeleted = _signalRService.onReservationDeleted.listen((id) {
       _loadAllData();
    });
  }

  void _showStatusUpdateSnackBar(ReservationOut res) {
    if (!mounted) return;
    String statusLabel = "";
    Color color = Colors.blue;

    switch (res.status) {
      case ReservationStatus.validee: 
        statusLabel = "validée"; 
        color = Colors.green; 
        break;
      case ReservationStatus.annuleeResto: 
        statusLabel = "annulée par le restaurant"; 
        color = Colors.red; 
        break;
      case ReservationStatus.finie: 
        statusLabel = "terminée"; 
        color = Colors.blue; 
        break;
      default: return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Votre réservation chez ${res.restaurant?.restaurantName ?? 'le restaurant'} a été $statusLabel."),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadAllData() async {
    await _loadSummary();
    await _load();
  }

  Future<void> _loadSummary() async {
    try {
      final search = SearchReservations(
        offset: 0,
        pageSize: 100,
        statuses: [ReservationStatus.enAttente, ReservationStatus.validee],
      );
      final list = await _repository.getMyReservations(search);
      if (mounted) {
        setState(() {
          _summaryReservations = list;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement du résumé des réservations: $e');
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      List<ReservationStatus> statuses;
      DateTime? minDate;

      if (_selectedFilter == 0) {
        statuses = [ReservationStatus.validee];
        minDate = DateTime.now(); 
      } else if (_selectedFilter == 1) {
        statuses = [ReservationStatus.enAttente];
      } else {
        statuses = [
          ReservationStatus.finie,
          ReservationStatus.annuleeResto,
          ReservationStatus.annuleeClient
        ];
      }

      final search = SearchReservations(
        offset: 0,
        pageSize: 50,
        statuses: statuses,
        minDate: minDate,
      );

      final list = await _repository.getMyReservations(search);
      list.sort((a, b) => a.reservationDate.compareTo(b.reservationDate));
      
      if (mounted) {
        setState(() {
          _reservations = list;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    final pendingTotal = _summaryReservations.where((r) => r.status == ReservationStatus.enAttente).length;
    final todayTotal = _summaryReservations.where((r) => 
      r.status == ReservationStatus.validee && 
      DateUtils.isSameDay(r.reservationDate, DateTime.now())
    ).length;

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
              if (newSelection.first != _selectedFilter) {
                setState(() => _selectedFilter = newSelection.first);
                _load();
              }
            },
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text('Erreur: $_error'))
                  : _reservations.isEmpty
                      ? const Center(child: Text('Aucune réservation'))
                      : RefreshIndicator(
                          onRefresh: _loadAllData,
                          child: _buildGroupedList(colors),
                        ),
        ),
      ],
    );
  }

  Widget _buildCountBadge(int count, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildGroupedList(ColorScheme colors) {
    final Map<String, List<ReservationOut>> grouped = {};
    for (var r in _reservations) {
      final key = DateFormat('yyyy-MM-dd').format(r.reservationDate.toLocal());
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(r);
    }
    final sortedDates = grouped.keys.toList();
    if (_selectedFilter == 2) { sortedDates.sort((a, b) => b.compareTo(a)); } 
    else { sortedDates.sort((a, b) => a.compareTo(b)); }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIndex) {
        final dateKey = sortedDates[dateIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Text(_getDisplayDate(dateKey), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.primary)),
            ),
            ...grouped[dateKey]!.map((r) => GestureDetector(
              onTap: () async {
                final result = await Navigator.push<bool?>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReservationDetailPage(reservation: r),
                  ),
                );
                if (result == true) {
                  _loadAllData();
                }
              },
              child: ReservationCard(reservation: r),
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
    if (date == today) return "AUJOURD'HUI";
    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date).toUpperCase();
  }
}
