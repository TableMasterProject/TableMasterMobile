import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_out.dart';
import 'package:table_master_mobile/features/restaurant/data/models/search_restaurant.dart';

typedef RestaurantSearch =
    Future<List<RestaurantOut>> Function(SearchRestaurant query);

class DiscoveryController extends ChangeNotifier {
  DiscoveryController({required this.search});

  final RestaurantSearch search;
  static const pageSize = 50;

  LatLng center = const LatLng(46.6, 2.2);
  LatLngBounds? bounds;
  LatLng? userPosition;
  String? cuisineType;
  String? paymentMethods;
  int? selectedRestaurantId;
  List<RestaurantOut> restaurants = [];
  String? error;
  bool loading = false;
  bool loadingMore = false;
  bool hasMore = false;
  int _requestVersion = 0;
  bool _disposed = false;

  bool get hasUserPosition => userPosition != null;

  void setUserPosition(LatLng? position) {
    userPosition = position;
    notifyListeners();
  }

  void selectRestaurant(int? id) {
    selectedRestaurantId = id;
    notifyListeners();
  }

  Future<void> setFilters({String? cuisine, String? payment}) {
    cuisineType = cuisine;
    paymentMethods = payment;
    return searchArea(center: center, bounds: bounds);
  }

  SearchRestaurant _query(int offset) => SearchRestaurant(
    offset: offset,
    pageSize: pageSize,
    latitude: center.latitude,
    longitude: center.longitude,
    currentUserLatitude: userPosition?.latitude,
    currentUserLongitude: userPosition?.longitude,
    southLatitude: bounds?.southwest.latitude,
    northLatitude: bounds?.northeast.latitude,
    westLongitude: bounds?.southwest.longitude,
    eastLongitude: bounds?.northeast.longitude,
    cuisineType: cuisineType,
    paymentMethods: paymentMethods,
  );

  Future<void> searchArea({
    required LatLng center,
    LatLngBounds? bounds,
  }) async {
    this.center = center;
    this.bounds = bounds;
    final version = ++_requestVersion;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final found = await search(_query(0));
      if (_disposed || version != _requestVersion) return;
      restaurants = found;
      hasMore = found.length == pageSize;
      selectedRestaurantId = null;
    } catch (_) {
      if (_disposed || version != _requestVersion) return;
      error = 'Impossible de charger les restaurants. Réessayez.';
    } finally {
      if (!_disposed && version == _requestVersion) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (loading || loadingMore || !hasMore) return;
    final version = _requestVersion;
    loadingMore = true;
    notifyListeners();
    try {
      final found = await search(_query(restaurants.length));
      if (_disposed || version != _requestVersion) return;
      restaurants = [...restaurants, ...found];
      hasMore = found.length == pageSize;
    } catch (_) {
      if (_disposed || version != _requestVersion) return;
      error = 'Impossible de charger plus de restaurants.';
    } finally {
      if (!_disposed && version == _requestVersion) {
        loadingMore = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
