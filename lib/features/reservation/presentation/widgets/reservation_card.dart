import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/reservation_in.dart';
import '../../data/models/reservation_out.dart';

class ReservationCard extends StatelessWidget {
  final ReservationOut reservation;
  final Function(ReservationStatus)? onStatusUpdate;

  const ReservationCard({
    super.key,
    required this.reservation,
    this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    final r = reservation;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant.withOpacity(0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _buildStatusIcon(r.status),
        title: Text(
          r.user?.firstName ?? r.user?.email ?? 'Client',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('${dateFormat.format(r.reservationDate.toLocal())} à ${timeFormat.format(r.reservationDate.toLocal())}'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('${r.numberOfPeople} convives'),
                ],
              ),
              if (r.specialRequest != null && r.specialRequest!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.note_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Demande : ${r.specialRequest}',
                          style: TextStyle(color: colors.primary, fontStyle: FontStyle.italic, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.table_restaurant_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('Table : ${r.table?.tableNumber ?? 'N/A'}'),
                ],
              ),
              const SizedBox(height: 8),
              _buildStatusChip(r.status),
            ],
          ),
        ),
        trailing: _buildActions(r, colors),
      ),
    );
  }

  Widget _buildActions(ReservationOut r, ColorScheme colors) {
    if (onStatusUpdate == null) return const SizedBox.shrink();

    if (r.status == ReservationStatus.enAttente) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: () => onStatusUpdate!(ReservationStatus.validee),
            tooltip: "Valider",
          ),
          IconButton(
            icon: Icon(Icons.cancel, color: colors.error),
            onPressed: () => onStatusUpdate!(ReservationStatus.annuleeResto),
            tooltip: "Annuler",
          ),
        ],
      );
    } else if (r.status == ReservationStatus.validee) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.blue),
            onPressed: () => onStatusUpdate!(ReservationStatus.finie),
            tooltip: "Marquer comme fini",
          ),
          IconButton(
            icon: Icon(Icons.cancel, color: colors.error),
            onPressed: () => onStatusUpdate!(ReservationStatus.annuleeResto),
            tooltip: "Annuler",
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStatusIcon(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.validee:
        return const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white, size: 18));
      case ReservationStatus.enAttente:
        return const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.timer, color: Colors.white, size: 18));
      case ReservationStatus.finie:
        return const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.done_all, color: Colors.white, size: 18));
      default:
        return const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.close, color: Colors.white, size: 18));
    }
  }

  Widget _buildStatusChip(ReservationStatus status) {
    Color color;
    String label;
    switch (status) {
      case ReservationStatus.enAttente: color = Colors.orange; label = "EN ATTENTE"; break;
      case ReservationStatus.validee: color = Colors.green; label = "CONFIRMÉE"; break;
      case ReservationStatus.finie: color = Colors.blue; label = "TERMINÉE"; break;
      case ReservationStatus.annuleeResto: color = Colors.red; label = "ANNULÉE (RESTO)"; break;
      case ReservationStatus.annuleeClient: color = Colors.red; label = "ANNULÉE (CLIENT)"; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
