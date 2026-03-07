import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/reservation/data/models/search_reservations.dart';
import 'package:table_master_mobile/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'reservation_detail_page.dart';

class MyReservationsPage extends StatefulWidget {
  const MyReservationsPage({super.key});

  @override
  State<MyReservationsPage> createState() => _MyReservationsPageState();
}

class _MyReservationsPageState extends State<MyReservationsPage> {
  late IReservationRepository _repository;
  final SearchReservations _search = SearchReservations(
    offset: 0,
    pageSize: 50,
  );
  List<ReservationOut> _reservations = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = getIt<IReservationRepository>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _repository.getMyReservations(_search);
      setState(() {
        _reservations = list;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Erreur: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    if (_reservations.isEmpty) {
      return const Center(child: Text('Vous n\'avez pas de réservations'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        itemCount: _reservations.length,
        itemBuilder: (context, index) {
          final r = _reservations[index];
          final title = r.restaurant?.restaurantName;
          final statusIcon =
              r.isValidate
                  ? Icon(Icons.check_circle, color: Colors.green)
                  : Icon(Icons.cancel, color: Colors.red);

          return Card(
            child: ListTile(
              leading: statusIcon,
              title: Text(
                title ?? "Aucun restaurant associé",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date : ${dateFormat.format(r.reservationDate.toLocal())}',
                  ),
                  Text(
                    'Heure : ${timeFormat.format(r.reservationDate.toLocal())}',
                  ),
                  Text('Personnes : ${r.numberOfPeople}'),
                  if (r.specialRequest != null && r.specialRequest!.isNotEmpty)
                    Text('Demande : ${r.specialRequest}'),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final result = await Navigator.push<bool?>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReservationDetailPage(reservation: r),
                  ),
                );
                if (result == true) {
                  // refresh if reservation was cancelled in detail
                  _load();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
