class SearchRestaurant {
  int? offset;
  int? pageSize;
  double? latitude;
  double? longitude;
  double? currentUserLongitude;
  double? currentUserLatitude;
  String? cuisineType;
  String? paymentMethods;

  SearchRestaurant({
    this.offset,
    this.pageSize = 20,
    this.latitude,
    this.longitude,
    this.currentUserLongitude,
    this.currentUserLatitude,
    this.cuisineType,
    this.paymentMethods,
  });

  Map<String, dynamic> toJson() {
    // On ne garde que les valeurs non nulles pour ne pas polluer l'URL
    final Map<String, dynamic> data = {};
    if (offset != null) data['Offset'] = offset;
    if (pageSize != null) data['PageSize'] = pageSize;
    if (latitude != null) data['Latitude'] = latitude;
    if (longitude != null) data['Longitude'] = longitude;
    if (currentUserLongitude != null) data['CurrentUserLongitude'] = currentUserLongitude;
    if (currentUserLatitude != null) data['CurrentUserLatitude'] = currentUserLatitude;
    if (cuisineType != null) data['CuisineType'] = cuisineType;
    if (paymentMethods != null) data['PaymentMethods'] = paymentMethods;
    return data;
  }
}