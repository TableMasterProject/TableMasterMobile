import 'package:flutter/material.dart';

class ReservationsPage extends StatelessWidget {
  const ReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_outlined, size: 80, color: colors.primary),
          const SizedBox(height: 20),
          Text(
            "Vos réservations s'afficheront ici",
            style: TextStyle(fontSize: 18, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
