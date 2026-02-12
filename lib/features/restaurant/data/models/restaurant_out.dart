import 'package:table_master_mobile/features/restaurant/data/models/restaurant_in.dart';

import '../../../closed_day_exception/data/models/closed_day_exception_out.dart';
import '../../../daily_activity/data/models/daily_activity_out.dart';
import '../../../menu/data/models/menu_out.dart';
import '../../../review/data/models/review_out.dart';
import '../../../table/data/models/table_entity_out.dart';

class RestaurantOut extends RestaurantIn {
  int id;
  DateTime createdAt;
  double distance;
  double averageRating;
  int numberOfReviews;

  // Listes d'objets liés (Assure-toi d'avoir créé les modèles correspondants)
  List<TableEntityOut>? tables;
  List<DailyActivityOut>? dailyActivitys;
  List<ClosedDayExceptionOut>? closedDayExceptions;
  List<ReviewOut>? reviews;
  List<MenuOut>? menu;

  RestaurantOut({
    required super.userId,
    required super.restaurantName,
    required super.streetNumber,
    required super.streetName,
    required super.postalCode,
    required super.city,
    super.latitude,
    super.longitude,
    required super.phone,
    required super.cuisineType,
    required super.paymentMethods,
    required super.description,
    required super.isAutoValidateReservation,
    required this.id,
    required this.createdAt,
    required this.distance,
    required this.averageRating,
    required this.numberOfReviews,
    this.tables,
    this.dailyActivitys,
    this.closedDayExceptions,
    this.reviews,
    this.menu,
  });

  factory RestaurantOut.fromJson(Map<String, dynamic> json) {
    return RestaurantOut(
      // Champs hérités de RestaurantIn
      userId: json['userId'] ?? 0,
      restaurantName: json['restaurantName'] ?? '',
      streetNumber: json['streetNumber'] ?? '',
      streetName: json['streetName'] ?? '',
      postalCode: json['postalCode'] ?? '',
      city: json['city'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phone: json['phone'] ?? '',
      cuisineType: json['cuisineType'] ?? '',
      paymentMethods: json['paymentMethods'] ?? '',
      description: json['description'] ?? '',
      isAutoValidateReservation: json['isAutoValidateReservation'] ?? false,

      // Champs spécifiques à RestaurantOut
      id: json['id'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      numberOfReviews: json['numberOfReviews'] ?? 0,

      // Mapping des listes
      tables: json['tables'] != null
          ? List<TableEntityOut>.from(json['tables'].map((x) => TableEntityOut.fromJson(x)))
          : null,
      dailyActivitys: json['dailyActivitys'] != null
          ? List<DailyActivityOut>.from(json['dailyActivitys'].map((x) => DailyActivityOut.fromJson(x)))
          : null,
      closedDayExceptions: json['closedDayExceptions'] != null
          ? List<ClosedDayExceptionOut>.from(json['closedDayExceptions'].map((x) => ClosedDayExceptionOut.fromJson(x)))
          : null,
      reviews: json['reviews'] != null
          ? List<ReviewOut>.from(json['reviews'].map((x) => ReviewOut.fromJson(x)))
          : null,
      menu: json['menu'] != null
          ? List<MenuOut>.from(json['menu'].map((x) => MenuOut.fromJson(x)))
          : null,
    );
  }
}