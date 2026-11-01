import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:table_master_mobile/core/app_constant.dart';
import 'package:table_master_mobile/core/injection.dart';
import 'package:table_master_mobile/core/localisation.dart';
import 'package:table_master_mobile/features/home/data/city_search_service.dart';
import 'package:table_master_mobile/features/home/presentation/city_suggestions_controller.dart';
import 'package:table_master_mobile/features/home/presentation/discovery_controller.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_out.dart';
import 'package:table_master_mobile/features/restaurant/domain/repositories/restaurant_repository.dart';
import 'package:table_master_mobile/features/restaurant/presentation/restaurant_client_detail_page.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  static const _france = CameraPosition(target: LatLng(46.6, 2.2), zoom: 5.4);
  static const _cityStorageKey = 'last_discovery_city';

  final _storage = const FlutterSecureStorage();
  final _cityInput = TextEditingController();
  final _sheetController = DraggableScrollableController();
  final _desktopListController = ScrollController();
  ScrollController? _activeListController;
  late final DiscoveryController _discovery;
  late final CitySuggestionsController _suggestions;
  GoogleMapController? _mapController;
  Timer? _cameraDebounce;
  bool _locationUnavailable = false;
  bool _hasLocationPermission = false;
  bool _cameraMoved = false;
  bool _cameraInitialized = false;
  bool _programmaticCameraMove = false;
  bool _citySelected = false;
  String? _selectedCuisine;
  String? _selectedPayment;
  LatLng _mapCenter = _france.target;

  @override
  void initState() {
    super.initState();
    _discovery = DiscoveryController(
      search: getIt<IRestaurantRepository>().getAllRestaurants,
    )..addListener(_refresh);
    _suggestions = CitySuggestionsController(search: CitySearchService().search)
      ..addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_restoreCity());
      unawaited(_requestLocation());
    });
  }

  @override
  void dispose() {
    _cameraDebounce?.cancel();
    _discovery.removeListener(_refresh);
    _discovery.dispose();
    _suggestions.removeListener(_refresh);
    _suggestions.dispose();
    _cityInput.dispose();
    _sheetController.dispose();
    _desktopListController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _restoreCity() async {
    try {
      final saved = await _storage.read(key: _cityStorageKey);
      if (saved == null || _cameraMoved || _citySelected || !mounted) return;
      final city = CitySuggestion.fromJson(
        jsonDecode(saved) as Map<String, dynamic>,
      );
      await _chooseCity(city, remember: false);
    } catch (_) {
      // Local storage is optional: the map remains usable without it.
    }
  }

  Future<void> _requestLocation() async {
    try {
      final allowed = await Localisation.requestPermission();
      if (!mounted) return;
      if (!allowed) {
        setState(() => _locationUnavailable = true);
        return;
      }
      setState(() => _hasLocationPermission = true);
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 7),
        ),
      );
      if (!mounted) return;
      final userPosition = LatLng(position.latitude, position.longitude);
      _discovery.setUserPosition(userPosition);
      if (!_cameraMoved && !_citySelected) {
        _programmaticCameraMove = true;
        await _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(userPosition, 12),
        );
        _programmaticCameraMove = false;
      } else {
        unawaited(_searchVisibleArea());
      }
    } catch (_) {
      if (mounted) setState(() => _locationUnavailable = true);
    }
  }

  Future<void> _chooseCity(CitySuggestion city, {bool remember = true}) async {
    _suggestions.clear();
    _citySelected = true;
    _cameraMoved = true;
    _mapCenter = city.center;
    if (!mounted) return;
    setState(() {
      _cityInput.text = city.name;
    });
    FocusScope.of(context).unfocus();
    if (remember) {
      try {
        await _storage.write(
          key: _cityStorageKey,
          value: jsonEncode({
            'nom': city.name,
            'code': city.code,
            'codeDepartement': city.department,
            'centre': {
              'coordinates': [city.center.longitude, city.center.latitude],
            },
          }),
        );
      } catch (_) {
        // Saving a city is optional.
      }
    }
    if (!mounted) return;
    _programmaticCameraMove = true;
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(city.center, 12),
    );
    _programmaticCameraMove = false;
    unawaited(_searchVisibleArea());
  }

  Future<void> _searchVisibleArea() async {
    final map = _mapController;
    if (map == null || !mounted) return;
    try {
      final bounds = await map.getVisibleRegion();
      if (!mounted) return;
      await _discovery.searchArea(center: _mapCenter, bounds: bounds);
    } catch (_) {
      if (mounted) await _discovery.searchArea(center: _mapCenter);
    }
  }

  void _onCameraIdle() {
    _cameraDebounce?.cancel();
    _cameraDebounce = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(_searchVisibleArea()),
    );
  }

  void _selectRestaurant(RestaurantOut restaurant) {
    _discovery.selectRestaurant(restaurant.id);
    if (restaurant.latitude != null && restaurant.longitude != null) {
      final map = _mapController;
      if (map != null) {
        unawaited(
          map.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(restaurant.latitude!, restaurant.longitude!),
            ),
          ),
        );
      }
    }
  }

  void _onMarkerTapped(RestaurantOut restaurant) {
    _discovery.selectRestaurant(restaurant.id);
    final index = _discovery.restaurants.indexWhere(
      (r) => r.id == restaurant.id,
    );
    final list = _activeListController;
    if (index >= 0 && list != null && list.hasClients) {
      unawaited(
        list.animateTo(
          (index * 112.0).clamp(0, list.position.maxScrollExtent),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ),
      );
    }
    if (_sheetController.isAttached) {
      unawaited(
        _sheetController.animateTo(
          0.55,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ),
      );
    }
  }

  void _openDetail(RestaurantOut restaurant) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantClientDetailPage(restaurant: restaurant),
      ),
    );
  }

  Set<Marker> get _markers => {
    for (final restaurant in _discovery.restaurants)
      if (restaurant.latitude != null && restaurant.longitude != null)
        Marker(
          markerId: MarkerId('${restaurant.id}'),
          position: LatLng(restaurant.latitude!, restaurant.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _discovery.selectedRestaurantId == restaurant.id
                ? BitmapDescriptor.hueAzure
                : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: restaurant.restaurantName,
            onTap: () => _openDetail(restaurant),
          ),
          onTap: () => _onMarkerTapped(restaurant),
        ),
  };

  Widget _searchAndFilters() {
    final colors = Theme.of(context).colorScheme;
    return Material(
      elevation: 3,
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityInput,
                    onChanged: _suggestions.updateQuery,
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Ville ou code postal',
                      border: const OutlineInputBorder(),
                      suffixIcon:
                          _suggestions.loading
                              ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                              : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Me localiser',
                  onPressed: () => unawaited(_requestLocation()),
                  icon: const Icon(Icons.my_location),
                ),
              ],
            ),
            if (_suggestions.cities.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _suggestions.cities.length,
                  itemBuilder:
                      (_, index) => ListTile(
                        dense: true,
                        title: Text(_suggestions.cities[index].label),
                        onTap:
                            () => unawaited(
                              _chooseCity(_suggestions.cities[index]),
                            ),
                      ),
                ),
              ),
            if (_suggestions.hasError)
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Recherche de ville indisponible. Déplacez la carte.',
                  ),
                ),
              ),
            if (_locationUnavailable && !_discovery.hasUserPosition)
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Sans GPS : choisissez une ville ou déplacez la carte.',
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCuisine,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Cuisine',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Toutes')),
                      for (final cuisine in AppConstants.cuisineOptions)
                        DropdownMenuItem(value: cuisine, child: Text(cuisine)),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedCuisine = value);
                      unawaited(
                        _discovery.setFilters(
                          cuisine: value == '' ? null : value,
                          payment:
                              _selectedPayment == '' ? null : _selectedPayment,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedPayment,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Paiement',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Tous')),
                      for (final payment in AppConstants.paymentOptions)
                        DropdownMenuItem(value: payment, child: Text(payment)),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedPayment = value);
                      unawaited(
                        _discovery.setFilters(
                          cuisine:
                              _selectedCuisine == '' ? null : _selectedCuisine,
                          payment: value == '' ? null : value,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _results(ScrollController scrollController, {bool showHandle = true}) {
    _activeListController = scrollController;
    final items = _discovery.restaurants;
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              if (showHandle) ...[
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Restaurants',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text('${items.length} affichés'),
                  ],
                ),
              ),
              if (_discovery.loading) const LinearProgressIndicator(),
              if (_discovery.error != null)
                ListTile(
                  title: Text(_discovery.error!),
                  trailing: TextButton(
                    onPressed: () => unawaited(_searchVisibleArea()),
                    child: const Text('Réessayer'),
                  ),
                ),
              if (!_discovery.loading &&
                  _discovery.error == null &&
                  items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aucun restaurant dans cette zone. Déplacez la carte ou choisissez une autre ville.',
                  ),
                ),
            ],
          ),
        ),
        SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final restaurant = items[index];
            final selected = _discovery.selectedRestaurantId == restaurant.id;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              color:
                  selected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _selectRestaurant(restaurant),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.restaurantName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(restaurant.addressString()),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (_discovery.hasUserPosition) ...[
                            const Icon(Icons.route, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              restaurant.distanceWithUser >= 1000
                                  ? '${(restaurant.distanceWithUser / 1000).toStringAsFixed(1)} km'
                                  : '${restaurant.distanceWithUser.toStringAsFixed(0)} m',
                            ),
                          ],
                          const Spacer(),
                          TextButton(
                            onPressed: () => _openDetail(restaurant),
                            child: const Text('Voir la fiche'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (_discovery.hasMore)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child:
                    _discovery.loadingMore
                        ? const CircularProgressIndicator()
                        : TextButton(
                          onPressed: () => unawaited(_discovery.loadMore()),
                          child: const Text('Voir plus de restaurants'),
                        ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final map = GoogleMap(
      initialCameraPosition: _france,
      myLocationEnabled: _hasLocationPermission,
      myLocationButtonEnabled: false,
      markers: _markers,
      onMapCreated: (controller) {
        _mapController = controller;
        _cameraInitialized = false;
        if (_citySelected || _discovery.hasUserPosition) {
          final target = _citySelected ? _mapCenter : _discovery.userPosition!;
          _programmaticCameraMove = true;
          unawaited(
            controller
                .animateCamera(CameraUpdate.newLatLngZoom(target, 12))
                .catchError((Object _) {})
                .whenComplete(() => _programmaticCameraMove = false),
          );
        }
        unawaited(_searchVisibleArea());
      },
      onCameraMoveStarted: () {
        if (_cameraInitialized && !_programmaticCameraMove) {
          _cameraMoved = true;
        }
      },
      onCameraMove: (position) => _mapCenter = position.target,
      onCameraIdle: () {
        _cameraInitialized = true;
        _programmaticCameraMove = false;
        _onCameraIdle();
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;
        if (compact) {
          return Stack(
            children: [
              Positioned.fill(child: map),
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _searchAndFilters(),
                  ),
                ),
              ),
              DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: 0.28,
                minChildSize: 0.16,
                maxChildSize: 0.88,
                builder:
                    (context, scrollController) => Material(
                      elevation: 12,
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _results(scrollController),
                    ),
              ),
            ],
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: _searchAndFilters(),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(flex: 3, child: map),
                  const VerticalDivider(width: 1),
                  Expanded(
                    flex: 2,
                    child: _results(_desktopListController, showHandle: false),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
