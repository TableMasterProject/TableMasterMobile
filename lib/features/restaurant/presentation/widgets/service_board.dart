import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/restaurant/presentation/widgets/service_reservation_card.dart';

class ServiceBoard extends StatelessWidget {
  const ServiceBoard({
    super.key,
    required this.pending,
    required this.confirmed,
    required this.selectedDate,
    required this.onDateChanged,
    required this.onStatusUpdate,
    this.tablePlan,
    this.pendingHasMore = false,
    this.confirmedHasMore = false,
    this.onLoadMorePending,
    this.onLoadMoreConfirmed,
    this.loading = false,
    this.error,
    this.onRetry,
  });

  final List<ReservationOut> pending;
  final List<ReservationOut> confirmed;
  final DateTime selectedDate;
  final Future<void> Function(DateTime) onDateChanged;
  final Future<void> Function(int, ReservationStatus) onStatusUpdate;
  final Widget? tablePlan;
  final bool pendingHasMore;
  final bool confirmedHasMore;
  final Future<void> Function()? onLoadMorePending;
  final Future<void> Function()? onLoadMoreConfirmed;
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'),
    );
    if (date != null) await onDateChanged(date);
  }

  List<Widget> _cards(
    List<ReservationOut> reservations, {
    required String emptyText,
    required bool hasMore,
    Future<void> Function()? onLoadMore,
  }) => [
    if (reservations.isEmpty)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(emptyText),
      ),
    for (final reservation in reservations) ...[
      ServiceReservationCard(
        key: ValueKey(reservation.id),
        reservation: reservation,
        onStatusUpdate: (status) => onStatusUpdate(reservation.id, status),
      ),
      const SizedBox(height: 10),
    ],
    if (hasMore && onLoadMore != null)
      TextButton(onPressed: onLoadMore, child: const Text('Voir plus')),
  ];

  Widget _pendingSection(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('À traiter', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      ..._cards(
        pending,
        emptyText: 'Aucune demande en attente.',
        hasMore: pendingHasMore,
        onLoadMore: onLoadMorePending,
      ),
    ],
  );

  Widget _confirmedSection(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Confirmées',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          TextButton.icon(
            onPressed: () => _pickDate(context),
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(DateFormat('d MMM', 'fr_FR').format(selectedDate)),
          ),
        ],
      ),
      const SizedBox(height: 12),
      ..._cards(
        confirmed,
        emptyText: 'Aucune réservation confirmée à cette date.',
        hasMore: confirmedHasMore,
        onLoadMore: onLoadMoreConfirmed,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final wide = screenWidth >= 1440;
        final desktop = screenWidth >= 1024;
        final intro = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service', style: Theme.of(context).textTheme.headlineSmall),
            Text(
              'Demandes et planning au même endroit',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (loading) const LinearProgressIndicator(),
            if (error != null)
              Row(
                children: [
                  Expanded(child: Text(error!)),
                  if (onRetry != null)
                    TextButton(
                      onPressed: onRetry,
                      child: const Text('Réessayer'),
                    ),
                ],
              ),
            const SizedBox(height: 18),
          ],
        );
        if (!desktop) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              intro,
              _pendingSection(context),
              const SizedBox(height: 24),
              _confirmedSection(context),
            ],
          );
        }

        Widget pane(Widget content) => Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [content],
          ),
        );
        final reservations =
            wide
                ? <Widget>[
                  pane(_pendingSection(context)),
                  const VerticalDivider(width: 1),
                  pane(_confirmedSection(context)),
                ]
                : <Widget>[
                  pane(
                    Column(
                      children: [
                        _pendingSection(context),
                        const SizedBox(height: 24),
                        _confirmedSection(context),
                      ],
                    ),
                  ),
                ];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: intro,
            ),
            Expanded(
              child: Row(
                children: [
                  ...reservations,
                  if (tablePlan != null) ...[
                    const VerticalDivider(width: 1),
                    Expanded(child: tablePlan!),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
