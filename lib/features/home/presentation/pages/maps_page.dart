import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:table_master_mobile/features/restaurant/domain/repositories/restaurant_repository.dart';
import 'package:table_master_mobile/features/restaurant/data/models/search_restaurant.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_out.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'package:table_master_mobile/features/restaurant/presentation/restaurant_client_detail_page.dart';
import 'package:table_master_mobile/core/app_constant.dart';

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

  LatLng _mapCenter = const LatLng(48.8566, 2.3522);
  LatLng? _lastSearchCenter;
  GoogleMapController? _controller;
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
    _determinePosition()
        .then((pos) {
          setState(() {
            _mapCenter = LatLng(pos.latitude, pos.longitude);
            _search.latitude = pos.latitude;
            _search.longitude = pos.longitude;
          });
          _loadRestaurants();
          _controller?.animateCamera(CameraUpdate.newLatLng(_mapCenter));
          _startPositionStream();
        })
        .catchError((_) {
          // ignore failures, keep default center
          _loadRestaurants();
        });
  }

  Future<Position> _determinePosition() async {
    Geolocator.requestPermission();
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services disabled');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions permanently denied');
    }
    return Geolocator.getCurrentPosition();
  }

  void _onCameraMove(CameraPosition pos) {
    _mapCenter = pos.target;
    _userMovedMap = true;
  }

  void _startPositionStream() {
    // subscribe to continuous location updates and recenter/search
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      log('location update: $pos');
      setState(() {
        _mapCenter = LatLng(pos.latitude, pos.longitude);
        _search.latitude = pos.latitude;
        _search.longitude = pos.longitude;
      });
      // only recenter map if user hasn't panned manually
      if (!_userMovedMap) {
        _controller?.animateCamera(CameraUpdate.newLatLng(_mapCenter));
        _maybeSearchNewArea();
      }
    });
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
      list.sort((a, b) => a.distance.compareTo(b.distance));
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
    // filters widget placed above map
    Widget filterSection = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCuisine,
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
              value: _selectedPayment,
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
              trailing: Text('${r.distance.toStringAsFixed(1)} km'),
              onTap: () => _openDetail(r),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Carte')),
      body: Column(
        children: [
          filterSection,
          Expanded(
            flex: 2,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _mapCenter,
                zoom: 12,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (c) => _controller = c,
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              markers: _markers,
            ),
          ),
          Expanded(flex: 3, child: listSection),
        ],
      ),
    );
  }
}
