import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';

class ClientReservationDetailPane extends StatefulWidget {
  const ClientReservationDetailPane({
    super.key,
    required this.reservation,
    required this.onDelete,
    required this.onCancel,
    this.onOpenFull,
  });

  final ReservationOut reservation;
  final Future<void> Function() onDelete;
  final Future<void> Function() onCancel;
  final VoidCallback? onOpenFull;

  @override
  State<ClientReservationDetailPane> createState() =>
      _ClientReservationDetailPaneState();
}

class _ClientReservationDetailPaneState
    extends State<ClientReservationDetailPane> {
  bool _busy = false;

  Future<void> _confirmAction({required bool delete}) async {
    final approved = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              delete ? 'Retirer la demande ?' : 'Annuler la réservation ?',
            ),
            content: Text(
              delete
                  ? 'La demande en attente sera supprimée.'
                  : 'Le restaurant sera informé de votre annulation.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Retour'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  delete ? 'Confirmer le retrait' : 'Confirmer l’annulation',
                ),
              ),
            ],
          ),
    );
    if (approved != true || !mounted) return;
    setState(() => _busy = true);
    try {
      if (delete) {
        await widget.onDelete();
      } else {
        await widget.onCancel();
      }
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
    final pending = reservation.status == ReservationStatus.enAttente;
    final confirmed = reservation.status == ReservationStatus.validee;
    final status = switch (reservation.status) {
      ReservationStatus.enAttente => 'En attente',
      ReservationStatus.validee => 'Confirmée',
      ReservationStatus.finie => 'Terminée',
      ReservationStatus.annuleeResto => 'Annulée par le restaurant',
      ReservationStatus.annuleeClient => 'Annulée',
    };
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          reservation.restaurant?.restaurantName ?? 'Restaurant',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Text(
          DateFormat(
            'EEEE d MMMM yyyy · HH:mm',
            'fr_FR',
          ).format(reservation.reservationDate),
        ),
        const SizedBox(height: 8),
        Text(
          '${reservation.numberOfPeople} personnes · Table ${reservation.table?.tableNumber ?? reservation.tableId}',
        ),
        const SizedBox(height: 8),
        Text(
          status,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color:
                pending
                    ? const Color(0xFF995300)
                    : confirmed
                    ? const Color(0xFF236B4B)
                    : null,
          ),
        ),
        if (reservation.specialRequest?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Text('Demande : ${reservation.specialRequest!.trim()}'),
        ],
        if (_busy) const LinearProgressIndicator(),
        const SizedBox(height: 24),
        if (pending || confirmed)
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _confirmAction(delete: pending),
            icon: Icon(
              pending ? Icons.delete_outline : Icons.event_busy_outlined,
            ),
            label: Text(
              pending ? 'Retirer la demande' : 'Annuler la réservation',
            ),
          ),
        if (widget.onOpenFull != null)
          TextButton.icon(
            onPressed: widget.onOpenFull,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Voir la fiche complète'),
          ),
      ],
    );
  }
}
