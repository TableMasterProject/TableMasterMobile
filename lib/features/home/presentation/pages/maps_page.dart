import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:table_master_mobile/core/responsive/breakpoints.dart';
import 'package:table_master_mobile/features/restaurant/domain/repositories/restaurant_repository.dart';
import 'package:table_master_mobile/features/restaurant/data/models/search_restaurant.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_out.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'package:table_master_mobile/features/restaurant/presentation/restaurant_client_detail_page.dart';
import 'package:table_master_mobile/core/app_constant.dart';

import '../../../../core/localisation.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  final IRestaurantRepository _repo = getIt<IRestaurantRepository>();
  final SearchRestaurant _search = SearchRestaurant(offset: 0, pageSize: 50);

  String? _selectedCuisine;
  String? _selectedPayment;

  bool _isInitializing = true;
  LatLng _mapCenter = const LatLng(48.8566, 2.3522);
  LatLng? _lastSearchCenter;
  StreamSubscription<Position>? _positionStream;
  bool _userMovedMap = false;
  static const double _searchDistanceThreshold = 500; // meters

  bool _loading = false;
  String? _error;
  List<RestaurantOut> _restaurants = [];
  Set<Marker> _markers = {};

  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initLocationAndData();
  }

  Future<void> _initLocationAndData() async {
    setState(() => _isInitializing = true);

    try {
      // 1. Demande de permission
      await Localisation.checkPermission();

      // 2. Tente de récupérer la position
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 7),
        ),
      );

      _mapCenter = LatLng(pos.latitude, pos.longitude);
      _search.latitude = pos.latitude;
      _search.longitude = pos.longitude;
      _search.currentUserLatitude = pos.latitude;
      _search.currentUserLongitude = pos.longitude;
    } catch (e) {
      debugPrint(
        "Localisation non disponible (timeout ou refus), repli sur Paris: $e",
      );
      // Valeurs par défaut déjà réglées sur Paris
      _search.latitude = _mapCenter.latitude;
      _search.longitude = _mapCenter.longitude;
    }

    // 3. On charge les restaurants AVANT de retirer le loader
    await _loadRestaurants();

    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  void _onCameraMove(CameraPosition pos) {
    _mapCenter = pos.target;
    _userMovedMap = true;
  }

  void _onCameraIdle() {
    // if user moved map manually, check threshold
    if (_userMovedMap) {
      _userMovedMap = false;
      _maybeSearchNewArea();
      return;
    }

    // debounce to avoid multiple calls when camera moving programmatically
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _search.latitude = _mapCenter.latitude;
      _search.longitude = _mapCenter.longitude;
      _loadRestaurants();
    });
  }

  Future<void> _loadRestaurants() async {
    _lastSearchCenter = _mapCenter;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _repo.getAllRestaurants(_search);
      setState(() {
        _restaurants = list;
        _updateMarkers();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openDetail(RestaurantOut r) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantClientDetailPage(restaurant: r),
      ),
    );
  }

  void _updateMarkers() {
    final markers = <Marker>{};
    for (var r in _restaurants) {
      if (r.latitude != null && r.longitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId(r.id.toString()),
            position: LatLng(r.latitude!, r.longitude!),
            onTap: () => _openDetail(r),
            infoWindow: InfoWindow(
              title: r.restaurantName,
              snippet: r.cuisineType,
              onTap: () => _openDetail(r),
            ),
          ),
        );
      }
    }
    setState(() => _markers = markers);
  }

  void _applyFilters() {
    _search.cuisineType = _selectedCuisine;
    _search.paymentMethods = _selectedPayment;
    _loadRestaurants();
  }

  void _maybeSearchNewArea() {
    if (_lastSearchCenter == null) {
      _search.latitude = _mapCenter.latitude;
      _search.longitude = _mapCenter.longitude;
      _loadRestaurants();
      return;
    }
    final dist = Geolocator.distanceBetween(
      _lastSearchCenter!.latitude,
      _lastSearchCenter!.longitude,
      _mapCenter.latitude,
      _mapCenter.longitude,
    );
    if (dist > _searchDistanceThreshold) {
      _search.latitude = _mapCenter.latitude;
      _search.longitude = _mapCenter.longitude;
      _loadRestaurants();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recherche...')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                "Recherche des restaurants à proximité...",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    Widget filterSection = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCuisine,
              decoration: const InputDecoration(
                labelText: 'Cuisine',
                border: OutlineInputBorder(),
              ),
              items:
                  AppConstants.cuisineOptions
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
              onChanged: (v) {
                setState(() => _selectedCuisine = v);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedPayment,
              decoration: const InputDecoration(
                labelText: 'Payment',
                border: OutlineInputBorder(),
              ),
              items:
                  AppConstants.paymentOptions
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
              onChanged: (v) {
                setState(() => _selectedPayment = v);
              },
            ),
          ),
          IconButton(icon: const Icon(Icons.search), onPressed: _applyFilters),
        ],
      ),
    );

    Widget listSection;
    if (_loading) {
      listSection = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      listSection = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Erreur: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRestaurants,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    } else {
      listSection = RefreshIndicator(
        onRefresh: _loadRestaurants,
        child: ListView.builder(
          itemCount: _restaurants.length,
          itemBuilder: (context, index) {
            final r = _restaurants[index];
            return ListTile(
              title: Text(r.restaurantName),
              subtitle: Text(r.addressString()),
              trailing: Text(
                r.distanceWithUser >= 1000
                    ? '${(r.distanceWithUser / 1000).toStringAsFixed(1)} km'
                    : '${r.distanceWithUser.toStringAsFixed(0)} m',
              ),
              onTap: () => _openDetail(r),
            );
          },
        ),
      );
    }

    final mapSection = GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _mapCenter,
        zoom: 12,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onCameraMove: _onCameraMove,
      onCameraIdle: _onCameraIdle,
      markers: _markers,
    );

    final useSplitView = !context.isMobile;

    return Scaffold(
      appBar: AppBar(title: const Text('Carte')),
      body: Column(
        children: [
          filterSection,
          Expanded(
            child: useSplitView
                ? Row(
                    children: [
                      Expanded(flex: 3, child: mapSection),
                      const VerticalDivider(width: 1),
                      Expanded(
                        flex: 2,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: listSection,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(flex: 2, child: mapSection),
                      Expanded(flex: 3, child: listSection),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
