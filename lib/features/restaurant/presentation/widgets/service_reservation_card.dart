import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';

class ServiceReservationCard extends StatefulWidget {
  const ServiceReservationCard({
    super.key,
    required this.reservation,
    required this.onStatusUpdate,
  });

  final ReservationOut reservation;
  final Future<void> Function(ReservationStatus status) onStatusUpdate;

  @override
  State<ServiceReservationCard> createState() => _ServiceReservationCardState();
}

class _ServiceReservationCardState extends State<ServiceReservationCard> {
  bool _busy = false;

  Future<void> _update(ReservationStatus status) async {
    if (_busy) return;
    if (status == ReservationStatus.annuleeResto) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(
                widget.reservation.status == ReservationStatus.enAttente
                    ? 'Refuser la demande ?'
                    : 'Annuler la réservation ?',
              ),
              content: const Text('Le client sera informé de cette décision.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Retour'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirmer'),
                ),
              ],
            ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await widget.onStatusUpdate(status);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action impossible. Réessayez.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservation = widget.reservation;
    final colors = Theme.of(context).colorScheme;
    final pending = reservation.status == ReservationStatus.enAttente;
    final name =
        reservation.guestName?.trim().isNotEmpty == true
            ? reservation.guestName!.trim()
            : reservation.user?.firstName ??
                reservation.user?.email ??
                'Client';
    final date = DateFormat(
      'EEE d MMM · HH:mm',
      'fr_FR',
    ).format(reservation.reservationDate);
    final statusColor =
        pending ? const Color(0xFF995300) : const Color(0xFF236B4B);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    pending ? 'À traiter' : 'Confirmée',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(date, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              '${reservation.numberOfPeople} personnes · Table ${reservation.table?.tableNumber ?? reservation.tableId}',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            if (reservation.specialRequest?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text('Demande : ${reservation.specialRequest!.trim()}'),
            ],
            const SizedBox(height: 12),
            if (_busy) const LinearProgressIndicator(),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        _busy
                            ? null
                            : () => _update(
                              pending
                                  ? ReservationStatus.validee
                                  : ReservationStatus.finie,
                            ),
                    icon: Icon(pending ? Icons.check : Icons.done_all),
                    label: Text(pending ? 'Valider' : 'Terminer'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _busy
                            ? null
                            : () => _update(ReservationStatus.annuleeResto),
                    child: Text(pending ? 'Refuser' : 'Annuler'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
