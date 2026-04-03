import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_out.dart';
import 'package:table_master_mobile/features/restaurant/domain/repositories/restaurant_repository.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localisation.dart';

class ReservationDetailPage extends StatefulWidget {
  final ReservationOut reservation;

  const ReservationDetailPage({super.key, required this.reservation});

  @override
  State<ReservationDetailPage> createState() => _ReservationDetailPageState();
}

class _ReservationDetailPageState extends State<ReservationDetailPage> {
  final IRestaurantRepository _restauRepo = getIt<IRestaurantRepository>();
  final IReservationRepository _resRepo = getIt<IReservationRepository>();

  RestaurantOut? _fullRestaurant;
  bool _isLoading = true;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    Localisation.checkPermission();
    _fetchFullData();
  }

  Future<void> _fetchFullData() async {
    try {
      final res = await _restauRepo.getRestaurantDetails(widget.reservation.restaurantId);
      if (mounted) {
        setState(() {
          _fullRestaurant = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des détails: $e')),
        );
      }
    }
  }

  Future<void> _openDirections() async {
    final r = _fullRestaurant ?? widget.reservation.restaurant;
    if (r == null) return;

    // Utilisation des coordonnées si disponibles pour une précision absolue, sinon l'adresse textuelle.
    final location = (r.latitude != null && r.longitude != null)
        ? "${r.latitude},${r.longitude}"
        : r.addressString();

    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}");

    // L'OS propose automatiquement l'appli de navigation installée (Google Maps, Waze, Apple Maps...)
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _makeCall() async {
    final phone = _fullRestaurant?.phone ?? widget.reservation.restaurant?.phone;
    if (phone == null) return;
    final url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.reservation;
    final restau = _fullRestaurant ?? res.restaurant;
    final colors = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 500,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restau?.restaurantName ?? "Réservation",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, shadows: [Shadow(blurRadius: 12, color: Colors.black87)])),
                  if (restau != null)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                        const SizedBox(width: 4),
                        Text("${restau.averageRating} • ${restau.cuisineType}",
                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.normal)),
                      ],
                    ),
                ],
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (restau?.latitude != null)
                    GoogleMap(
                      initialCameraPosition: CameraPosition(target: LatLng(restau!.latitude!, restau.longitude!), zoom: 16),
                      markers: {
                        Marker(
                          markerId: const MarkerId('res'),
                          position: LatLng(restau.latitude!, restau.longitude!),
                          infoWindow: InfoWindow(title: restau.restaurantName, snippet: restau.addressString()),
                        ),
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      mapToolbarEnabled: true,
                      onMapCreated: (c) => _mapController = c,
                    )
                  else
                    Container(color: colors.primaryContainer, child: Icon(Icons.restaurant, size: 80, color: colors.onPrimaryContainer.withOpacity(0.3))),
                  const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black38, Colors.transparent, Colors.black87]))),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _isLoading
                ? const LinearProgressIndicator()
                : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: _buildStatusBadge(res.isValidate)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(context, Icons.directions, "Itinéraire", _openDirections),
                      _buildActionButton(context, Icons.phone, "Appeler", _makeCall),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Text("Détails de la réservation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildInfoTile(context, Icons.calendar_today, "Date", dateFormat.format(res.reservationDate.toLocal())),
                  _buildInfoTile(context, Icons.access_time, "Heure", timeFormat.format(res.reservationDate.toLocal())),
                  _buildInfoTile(context, Icons.people, "Couverts", "${res.numberOfPeople} personnes"),
                  _buildInfoTile(context, Icons.table_bar, "Table", res.table != null ? "Table n°${res.table!.tableNumber}" : "Assignation à l'arrivée"),

                  const SizedBox(height: 32),
                  const Text("Contact & Localisation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListTile(
                    onTap: _openDirections,
                    leading: const Icon(Icons.location_on, color: Colors.red),
                    title: Text(restau?.addressString() ?? "Chargement..."),
                    subtitle: const Text("Ouvrir l'itinéraire"),
                    trailing: const Icon(Icons.chevron_right),
                    shape: RoundedRectangleBorder(side: BorderSide(color: colors.outlineVariant), borderRadius: BorderRadius.circular(12)),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    onTap: _makeCall,
                    leading: const Icon(Icons.phone, color: Colors.green),
                    title: Text(restau?.phone ?? "Chargement..."),
                    subtitle: const Text("Appeler le restaurant"),
                    trailing: const Icon(Icons.chevron_right),
                    shape: RoundedRectangleBorder(side: BorderSide(color: colors.outlineVariant), borderRadius: BorderRadius.circular(12)),
                  ),
                  if (restau?.description != null && restau!.description.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text("À propos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(restau!.description, style: TextStyle(color: colors.onSurfaceVariant, height: 1.5)),
                  ],

                  if (res.specialRequest != null && res.specialRequest!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text("Votre note", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: colors.surfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.outlineVariant)),
                      child: Text(res.specialRequest!, style: const TextStyle(fontStyle: FontStyle.italic)),
                    ),
                  ],
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmCancel(context),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text("ANNULER LA RÉSERVATION", style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(foregroundColor: colors.error, side: BorderSide(color: colors.error, width: 2), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isValidate) {
    final color = isValidate ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color)),
      child: Text(isValidate ? "✓ RÉSERVATION CONFIRMÉE" : "⟳ CONFIRMATION EN ATTENTE", style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Column(children: [IconButton.filledTonal(onPressed: onTap, icon: Icon(icon)), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]);
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Icon(icon, size: 22, color: colors.primary),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12, color: colors.outline)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final should = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler ?'),
        content: const Text('Souhaitez-vous vraiment annuler votre réservation ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error), child: const Text('Oui, annuler')),
        ],
      ),
    );
    if (should == true) {
      try {
        await _resRepo.deleteReservation(widget.reservation.id);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        }
      }
    }
  }
}
