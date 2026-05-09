import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_out.dart';
import 'package:table_master_mobile/features/restaurant/domain/repositories/restaurant_repository.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'package:table_master_mobile/features/review/presentation/pages/add_review_page.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localisation.dart';
import '../data/models/reservation_in.dart';

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

    final location = (r.latitude != null && r.longitude != null)
        ? "${r.latitude},${r.longitude}"
        : r.addressString();

    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}");
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

    final bool canReview = res.status == ReservationStatus.finie;
    final bool isEnAttente = res.status == ReservationStatus.enAttente;
    final bool isValidee = res.status == ReservationStatus.validee;
    final bool isCancel = res.status == ReservationStatus.annuleeResto || res.status == ReservationStatus.annuleeClient;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
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
                    )
                  else
                    Container(color: colors.primaryContainer, child: Icon(Icons.restaurant, size: 80, color: colors.onPrimaryContainer.withValues(alpha: 0.3))),
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
                  Center(child: _buildStatusBadge(res.status)),
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
                    Text(restau.description, style: TextStyle(color: colors.onSurfaceVariant, height: 1.5)),
                  ],

                  if (res.specialRequest != null && res.specialRequest!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text("Note spéciale pour le restaurateur", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: colors.surfaceContainerHighest.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.outlineVariant)),
                      child: Text(res.specialRequest!, style: const TextStyle(fontStyle: FontStyle.italic)),
                    ),
                  ],
                  const SizedBox(height: 160),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: (isCancel)? null : Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canReview)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddReviewPage(
                            userId: res.userId,
                            restaurantId: res.restaurantId,
                            restaurantName: restau?.restaurantName ?? "le restaurant",
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.star_rate_rounded),
                    label: const Text("NOTER MON EXPÉRIENCE", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              if(isEnAttente || isValidee)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => isEnAttente ? _confirmDelete(context) : _confirmCancel(context),
                    icon: Icon(isEnAttente ? Icons.delete_forever_outlined : Icons.cancel_outlined),
                    label: Text(
                        isEnAttente ? "SUPPRIMER LA DEMANDE" : "ANNULER LA RÉSERVATION",
                        style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.error,
                      side: BorderSide(color: colors.error, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ReservationStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case ReservationStatus.enAttente:
        color = Colors.orange;
        label = "EN ATTENTE";
        icon = Icons.pending_rounded;
        break;
      case ReservationStatus.validee:
        color = Colors.green;
        label = "CONFIRMÉE";
        icon = Icons.verified_rounded;
        break;
      case ReservationStatus.finie:
        color = Colors.blue;
        label = "TERMINÉE";
        icon = Icons.check_circle_rounded;
        break;
      case ReservationStatus.annuleeResto:
        color = Colors.red;
        label = "ANNULÉE PAR LE RESTO";
        icon = Icons.cancel_rounded;
        break;
      case ReservationStatus.annuleeClient:
        color = Colors.red;
        label = "ANNULÉE PAR VOUS";
        icon = Icons.person_off_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color, width: 1.5)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12, letterSpacing: 1.1)),
        ],
      ),
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

  Future<void> _confirmDelete(BuildContext context) async {
    final should = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la demande ?'),
        content: const Text('Votre demande de réservation n\'a pas encore été traitée. Souhaitez-vous la retirer définitivement ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Retour')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error), 
            child: const Text('Supprimer définitivement')
          ),
        ],
      ),
    );

    if (should == true) {
      try {
        await _resRepo.deleteReservation(widget.reservation.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande supprimée')));
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final should = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la réservation ?'),
        content: const Text('Votre réservation est validée. Souhaitez-vous informer le restaurant que vous ne viendrez pas ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Garder la réservation')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Confirmer l\'annulation')
          ),
        ],
      ),
    );
    if (should == true) {
      try {
        await _resRepo.updateReservationStatus(widget.reservation.id, ReservationStatus.annuleeClient);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Réservation annulée')));
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }
}
