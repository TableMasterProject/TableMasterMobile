import 'package:flutter/material.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:table_master_mobile/features/reservation/presentation/reservation_detail_page.dart';

class ReservationDeepLinkPage extends StatefulWidget {
  final int reservationId;

  const ReservationDeepLinkPage({super.key, required this.reservationId});

  @override
  State<ReservationDeepLinkPage> createState() =>
      _ReservationDeepLinkPageState();
}

class _ReservationDeepLinkPageState extends State<ReservationDeepLinkPage> {
  final _reservationRepo = getIt<IReservationRepository>();
  late Future<ReservationOut> _reservationFuture;

  @override
  void initState() {
    super.initState();
    _reservationFuture = _reservationRepo.getReservationById(
      widget.reservationId,
    );
  }

  void _retry() {
    setState(() {
      _reservationFuture = _reservationRepo.getReservationById(
        widget.reservationId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReservationOut>(
      future: _reservationFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ReservationDetailPage(reservation: snapshot.data!);
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text("Réservation")),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_busy_rounded,
                      size: 56,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Impossible d'ouvrir cette réservation",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text("Réessayer"),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
