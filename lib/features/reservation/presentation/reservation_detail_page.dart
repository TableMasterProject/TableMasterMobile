import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:table_master_mobile/core/injection.dart';

class ReservationDetailPage extends StatelessWidget {
  final ReservationOut reservation;

  const ReservationDetailPage({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    final repo = getIt<IReservationRepository>();

    Future<void> _confirmCancel() async {
      final should = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Annuler la réservation'),
              content: const Text(
                'Êtes-vous sûr de vouloir annuler cette réservation ?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Non'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Oui', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
      );

      if (should == true) {
        try {
          await repo.deleteReservation(reservation.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Réservation annulée')),
            );
            Navigator.pop(context, true);
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Détails de la réservation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reservation.restaurant != null) ...[
              Text(
                reservation.restaurant!.restaurantName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${reservation.restaurant!.streetNumber} ${reservation.restaurant!.streetName}, ${reservation.restaurant!.postalCode} ${reservation.restaurant!.city}',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              reservation.table != null
                  ? 'Table ${reservation.table!.tableNumber}'
                  : 'Restaurant #${reservation.restaurantId}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Date : ${dateFormat.format(reservation.reservationDate.toLocal())}',
            ),
            Text(
              'Heure : ${timeFormat.format(reservation.reservationDate.toLocal())}',
            ),
            Text('Personnes : ${reservation.numberOfPeople}'),
            if (reservation.specialRequest != null &&
                reservation.specialRequest!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Demande spéciale :'),
              Text(reservation.specialRequest!),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                reservation.isValidate
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : Icon(Icons.cancel, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  reservation.isValidate ? 'Validée' : 'En attente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: reservation.isValidate ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            // spacer left to push content up
            const Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FilledButton.icon(
          onPressed: _confirmCancel,
          icon: const Icon(Icons.cancel),
          label: const Text('Annuler la réservation'),
          style: FilledButton.styleFrom(backgroundColor: colors.error),
        ),
      ),
    );
  }
}
