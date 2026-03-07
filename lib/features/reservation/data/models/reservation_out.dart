import 'package:table_master_mobile/features/restaurant/data/models/restaurant_out.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_out.dart';
import 'package:table_master_mobile/features/user/data/models/user_out.dart';

class ReservationOut {
  int id;
  DateTime createdAt;

  // Fields from ReservationIn
  int userId;
  int tableId;
  int restaurantId;
  DateTime reservationDate;
  int numberOfPeople;
  String? specialRequest;
  bool isValidate;

  // Expanded relations
  UserOut? user;
  TableEntityOut? table;
  RestaurantOut? restaurant;

  ReservationOut({
    required this.id,
    required this.createdAt,
    required this.userId,
    required this.tableId,
    required this.restaurantId,
    required this.reservationDate,
    required this.numberOfPeople,
    this.specialRequest,
    required this.isValidate,
    this.user,
    this.table,
    this.restaurant,
  });

  factory ReservationOut.fromJson(Map<String, dynamic> json) {
    return ReservationOut(
      id: json['id'] ?? 0,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      userId: json['userId'] ?? 0,
      tableId: json['tableId'] ?? 0,
      restaurantId: json['restaurantId'] ?? 0,
      reservationDate:
          json['reservationDate'] != null
              ? DateTime.parse(json['reservationDate'])
              : DateTime.now(),
      numberOfPeople: json['numberOfPeople'] ?? 1,
      specialRequest: json['specialRequest'],
      isValidate: json['isValidate'] ?? false,
      user: json['user'] != null ? UserOut.fromJson(json['user']) : null,
      table:
          json['table'] != null ? TableEntityOut.fromJson(json['table']) : null,
      restaurant : json['restaurant'] != null ? RestaurantOut.fromJson(json['restaurant']) : null,
    );
  }
}
