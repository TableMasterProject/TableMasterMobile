import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';

class ClientReservationsFeed extends StatelessWidget {
  const ClientReservationsFeed({
    super.key,
    required this.upcoming,
    required this.history,
    required this.showHistory,
    required this.onShowHistory,
    required this.onShowUpcoming,
    required this.onDiscover,
    required this.onOpenReservation,
    this.detailPane,
    this.loading = false,
    this.error,
    this.onRetry,
    this.hasMore = false,
    this.onLoadMore,
  });

  final List<ReservationOut> upcoming;
  final List<ReservationOut> history;
  final bool showHistory;
  final VoidCallback onShowHistory;
  final VoidCallback onShowUpcoming;
  final VoidCallback? onDiscover;
  final ValueChanged<ReservationOut> onOpenReservation;
  final Widget? detailPane;
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;
  final bool hasMore;
  final VoidCallback? onLoadMore;

  String _status(ReservationStatus status) => switch (status) {
    ReservationStatus.enAttente => 'En attente',
    ReservationStatus.validee => 'Confirmée',
    ReservationStatus.finie => 'Terminée',
    ReservationStatus.annuleeResto => 'Annulée par le restaurant',
    ReservationStatus.annuleeClient => 'Annulée',
  };

  Widget _tile(BuildContext context, ReservationOut reservation) {
    final colors = Theme.of(context).colorScheme;
    final status = reservation.status;
    final statusColor =
        status == ReservationStatus.enAttente
            ? const Color(0xFF995300)
            : status == ReservationStatus.validee
            ? const Color(0xFF236B4B)
            : colors.onSurfaceVariant;
    return Card(
      child: InkWell(
        onTap: () => onOpenReservation(reservation),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reservation.restaurant?.restaurantName ?? 'Restaurant',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat(
                  'dd/MM/yyyy · HH:mm',
                ).format(reservation.reservationDate),
              ),
              Text('${reservation.numberOfPeople} personnes'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _status(status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Text('Voir le détail'),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = showHistory ? history : upcoming;
    final list = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Mes réservations',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          showHistory
              ? 'Vos réservations passées et annulées'
              : 'Vos prochaines sorties',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        if (showHistory)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onShowUpcoming,
              icon: const Icon(Icons.arrow_back),
              label: const Text('À venir'),
            ),
          ),
        if (loading) const LinearProgressIndicator(),
        if (error != null) ...[
          Text(error!),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
        if (!loading && items.isEmpty) ...[
          const SizedBox(height: 50),
          Icon(
            Icons.event_available_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              showHistory
                  ? 'Aucune réservation passée.'
                  : 'Aucune réservation à venir.',
            ),
          ),
          if (!showHistory && onDiscover != null)
            Center(
              child: FilledButton.icon(
                onPressed: onDiscover,
                icon: const Icon(Icons.explore_outlined),
                label: const Text('Trouver un restaurant'),
              ),
            ),
        ],
        for (final reservation in items) ...[
          _tile(context, reservation),
          const SizedBox(height: 10),
        ],
        if (hasMore && onLoadMore != null)
          TextButton(onPressed: onLoadMore, child: const Text('Voir plus')),
        if (!showHistory)
          TextButton.icon(
            onPressed: onShowHistory,
            icon: const Icon(Icons.history),
            label: const Text('Voir l’historique'),
          ),
      ],
    );
    if (MediaQuery.sizeOf(context).width < 1024 || detailPane == null) {
      return list;
    }
    return Row(
      children: [
        SizedBox(width: 460, child: list),
        const VerticalDivider(width: 1),
        Expanded(child: detailPane!),
      ],
    );
  }
}
