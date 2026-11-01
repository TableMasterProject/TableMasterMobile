import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/restaurant/presentation/widgets/service_reservation_card.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_out.dart';

class TableInspectionPanel extends StatelessWidget {
  const TableInspectionPanel({
    super.key,
    required this.table,
    required this.selectedDate,
    required this.pending,
    required this.confirmed,
    this.history = const [],
    required this.onClose,
    required this.onStatusUpdate,
    this.loading = false,
    this.error,
    this.onRetry,
    this.pendingHasMore = false,
    this.confirmedHasMore = false,
    this.historyHasMore = false,
    this.onLoadMore,
  });

  final TableEntityOut table;
  final DateTime selectedDate;
  final List<ReservationOut> pending;
  final List<ReservationOut> confirmed;
  final List<ReservationOut> history;
  final bool pendingHasMore;
  final bool confirmedHasMore;
  final bool historyHasMore;
  final Future<void> Function(ReservationStatus)? onLoadMore;
  final VoidCallback onClose;
  final Future<void> Function(int, ReservationStatus) onStatusUpdate;
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Table ${table.tableNumber}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              onPressed: onClose,
              tooltip: 'Fermer',
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        Text('${table.numberOfSeats} places'),
        if (loading) const LinearProgressIndicator(),
        if (error != null)
          Row(
            children: [
              Expanded(child: Text(error!)),
              if (onRetry != null)
                TextButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          ),
        const SizedBox(height: 20),
        Text('À traiter', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        if (pending.isEmpty) const Text('Aucune demande pour cette table.'),
        for (final reservation in pending) ...[
          ServiceReservationCard(
            key: ValueKey(reservation.id),
            reservation: reservation,
            onStatusUpdate: (status) => onStatusUpdate(reservation.id, status),
          ),
          const SizedBox(height: 10),
        ],
        if (pendingHasMore && onLoadMore != null)
          TextButton(
            onPressed: () => onLoadMore!(ReservationStatus.enAttente),
            child: const Text('Voir plus'),
          ),
        const SizedBox(height: 20),
        Text(
          'Confirmées · ${DateFormat('d MMM', 'fr_FR').format(selectedDate)}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        if (confirmed.isEmpty)
          const Text('Aucune réservation confirmée à cette date.'),
        for (final reservation in confirmed) ...[
          ServiceReservationCard(
            key: ValueKey(reservation.id),
            reservation: reservation,
            onStatusUpdate: (status) => onStatusUpdate(reservation.id, status),
          ),
          const SizedBox(height: 10),
        ],
        if (confirmedHasMore && onLoadMore != null)
          TextButton(
            onPressed: () => onLoadMore!(ReservationStatus.validee),
            child: const Text('Voir plus'),
          ),
        const SizedBox(height: 20),
        Text(
          'Historique du jour',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        if (history.isEmpty)
          const Text('Aucune réservation terminée ou annulée à cette date.'),
        for (final reservation in history) ...[
          ServiceReservationCard(
            key: ValueKey(reservation.id),
            reservation: reservation,
            onStatusUpdate: (status) => onStatusUpdate(reservation.id, status),
          ),
          const SizedBox(height: 10),
        ],
        if (historyHasMore && onLoadMore != null)
          TextButton(
            onPressed: () => onLoadMore!(ReservationStatus.finie),
            child: const Text('Voir plus'),
          ),
      ],
    );
  }
}
