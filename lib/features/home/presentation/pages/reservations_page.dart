import 'package:flutter/material.dart';
import 'package:table_master_mobile/features/reservation/presentation/my_reservations_page.dart';

class ReservationsPage extends StatelessWidget {
  const ReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect to the real MyReservationsPage so that the home tab shows
    // the user's reservations with details and cancellation.
    return const MyReservationsPage();
  }
}
