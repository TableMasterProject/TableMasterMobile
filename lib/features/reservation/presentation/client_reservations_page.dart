import 'dart:async';

import 'package:flutter/material.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'package:table_master_mobile/core/refresh_scheduler.dart';
import 'package:table_master_mobile/core/signalr_service.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';
import 'package:table_master_mobile/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:table_master_mobile/features/reservation/presentation/controllers/client_reservations_controller.dart';
import 'package:table_master_mobile/features/reservation/presentation/reservation_detail_page.dart';
import 'package:table_master_mobile/features/reservation/presentation/widgets/client_reservations_feed.dart';
import 'package:table_master_mobile/features/reservation/presentation/widgets/client_reservation_detail_pane.dart';

class ClientReservationsPage extends StatefulWidget {
  const ClientReservationsPage({
    super.key,
    required this.userId,
    this.onDiscover,
  });

  final int userId;
  final VoidCallback? onDiscover;

  @override
  State<ClientReservationsPage> createState() => _ClientReservationsPageState();
}

class _ClientReservationsPageState extends State<ClientReservationsPage> {
  late final ClientReservationsController _controller;
  late final SignalRService _signalR;
  late final RefreshScheduler _refresh;
  final _subscriptions = <StreamSubscription<dynamic>>[];
  bool _showHistory = false;
  ReservationOut? _selected;

  @override
  void initState() {
    super.initState();
    _controller = ClientReservationsController(
      repository: getIt<IReservationRepository>(),
    );
    _signalR = getIt<SignalRService>();
    _refresh = RefreshScheduler(_reload);
    unawaited(_controller.loadUpcoming());
    unawaited(_initRealtime());
  }

  Future<void> _initRealtime() async {
    _subscriptions.add(
      _signalR.onResynchronized.listen((_) => _refresh.schedule()),
    );
    _subscriptions.add(
      _signalR.onReservationCreated.listen((reservation) {
        if (reservation.userId == widget.userId) _refresh.schedule();
      }),
    );
    _subscriptions.add(
      _signalR.onReservationUpdateStatus.listen((reservation) {
        if (reservation.userId == widget.userId) _refresh.schedule();
      }),
    );
    _subscriptions.add(
      _signalR.onReservationDeleted.listen((_) => _refresh.schedule()),
    );
    try {
      await _signalR.joinUserGroup(widget.userId);
    } catch (_) {
      // La liste reste consultable même sans temps réel.
    }
  }

  Future<void> _reload() async {
    await _controller.loadUpcoming();
    if (_showHistory) await _controller.loadHistory();
  }

  Future<void> _openDetail(ReservationOut reservation) async {
    if (MediaQuery.sizeOf(context).width >= 1024) {
      setState(() => _selected = reservation);
      return;
    }
    final changed = await Navigator.of(context).push<bool?>(
      MaterialPageRoute(
        builder: (_) => ReservationDetailPage(reservation: reservation),
      ),
    );
    if (changed == true) await _reload();
  }

  Future<void> _openFullDetail(ReservationOut reservation) async {
    final changed = await Navigator.of(context).push<bool?>(
      MaterialPageRoute(
        builder: (_) => ReservationDetailPage(reservation: reservation),
      ),
    );
    if (changed == true) await _reload();
  }

  void _openHistory() {
    setState(() {
      _showHistory = true;
      _selected = null;
    });
    unawaited(_controller.loadHistory());
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_signalR.leaveUserGroup(widget.userId));
    _refresh.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget? _detailPane() {
    final reservation = _selected;
    if (reservation == null) return null;
    return ClientReservationDetailPane(
      key: ValueKey(reservation.id),
      reservation: reservation,
      onDelete: () async {
        await _controller.repository.deleteReservation(reservation.id);
        if (mounted) setState(() => _selected = null);
        await _reload();
      },
      onCancel: () async {
        await _controller.repository.updateReservationStatus(
          reservation.id,
          ReservationStatus.annuleeClient,
        );
        if (mounted) setState(() => _selected = null);
        await _reload();
      },
      onOpenFull: () => _openFullDetail(reservation),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final history = _showHistory;
      return RefreshIndicator(
        onRefresh: _reload,
        child: ClientReservationsFeed(
          upcoming: _controller.upcoming,
          history: _controller.history,
          showHistory: history,
          onShowHistory: _openHistory,
          onShowUpcoming:
              () => setState(() {
                _showHistory = false;
                _selected = null;
              }),
          onDiscover: widget.onDiscover,
          onOpenReservation: _openDetail,
          detailPane: _detailPane(),
          loading:
              history
                  ? _controller.historyLoading
                  : _controller.upcomingLoading,
          error: history ? _controller.historyError : _controller.upcomingError,
          onRetry:
              () => unawaited(
                history
                    ? _controller.loadHistory()
                    : _controller.loadUpcoming(),
              ),
          hasMore:
              history
                  ? _controller.historyHasMore
                  : _controller.upcomingHasMore,
          onLoadMore:
              () => unawaited(
                history
                    ? _controller.loadMoreHistory()
                    : _controller.loadMoreUpcoming(),
              ),
        ),
      );
    },
  );
}
