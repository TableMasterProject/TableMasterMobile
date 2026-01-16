class RestaurantIn {
  int userId;
  String restaurantName;
  String streetNumber;
  String streetName;
  String postalCode;
  String city;
  double? latitude;
  double? longitude;
  String phone;
  String cuisineType;
  String paymentMethods;
  String description;
  bool isAutoValidateReservation;

  RestaurantIn({
    required this.userId,
    required this.restaurantName,
    required this.streetNumber,
    required this.streetName,
    required this.postalCode,
    required this.city,
    this.latitude,
    this.longitude,
    required this.phone,
    required this.cuisineType,
    required this.paymentMethods,
    required this.description,
    required this.isAutoValidateReservation,
  });

  // La méthode magique
  RestaurantIn copyWith({
    int? userId,
    String? restaurantName,
    String? streetNumber,
    String? streetName,
    String? postalCode,
    String? city,
    double? latitude,
    double? longitude,
    String? phone,
    String? cuisineType,
    String? paymentMethods,
    String? description,
    bool? isAutoValidateReservation,
  }) {
    return RestaurantIn(
      userId: userId ?? this.userId,
      restaurantName: restaurantName ?? this.restaurantName,
      streetNumber: streetNumber ?? this.streetNumber,
      streetName: streetName ?? this.streetName,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      cuisineType: cuisineType ?? this.cuisineType,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      description: description ?? this.description,
      isAutoValidateReservation: isAutoValidateReservation ?? this.isAutoValidateReservation,
    );
  }
}