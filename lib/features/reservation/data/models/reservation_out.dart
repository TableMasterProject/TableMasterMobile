import 'package:table_master_mobile/core/time/paris_time.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_out.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_out.dart';
import 'package:table_master_mobile/features/user/data/models/user_out.dart';

class ReservationOut {
  int id;
  DateTime createdAt;

  // Champs de base
  int userId;
  int tableId;
  int restaurantId;
  DateTime reservationDate;
  int numberOfPeople;
  String? specialRequest;
  String? guestName;
  String? guestPhone;

  // Remplacement du bool par l'enum
  ReservationStatus status;

  // Relations étendues (établies par ton API via des Includes)
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
    required this.status,
    this.specialRequest,
    this.guestName,
    this.guestPhone,
    this.user,
    this.table,
    this.restaurant,
  });

  factory ReservationOut.fromJson(Map<String, dynamic> json) {
    // Normalisation des clés pour gérer le PascalCase venant du C#
    final id = json['id'] ?? json['Id'] ?? 0;
    final createdAtStr = json['createdAt'] ?? json['CreatedAt'];
    final userId = json['userId'] ?? json['UserId'] ?? 0;
    final tableId = json['tableId'] ?? json['TableId'] ?? 0;
    final restaurantId = json['restaurantId'] ?? json['RestaurantId'] ?? 0;
    final reservationDateStr =
        json['reservationDate'] ?? json['ReservationDate'];
    final numberOfPeople =
        json['numberOfPeople'] ?? json['NumberOfPeople'] ?? 1;
    final statusInt = json['status'] ?? json['Status'] ?? 0;
    final specialRequest = json['specialRequest'] ?? json['SpecialRequest'];
    final guestName = json['guestName'] ?? json['GuestName'];
    final guestPhone = json['guestPhone'] ?? json['GuestPhone'];

    final userJson = json['user'] ?? json['User'];
    final tableJson = json['table'] ?? json['Table'];
    final restaurantJson = json['restaurant'] ?? json['Restaurant'];

    return ReservationOut(
      id: id,
      createdAt:
          createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now(),
      userId: userId,
      tableId: tableId,
      restaurantId: restaurantId,
      reservationDate:
          reservationDateStr != null
              ? ParisTime.parse(reservationDateStr)
              : DateTime.now(),
      numberOfPeople: numberOfPeople,
      status: ReservationStatus.values[statusInt],
      specialRequest: specialRequest,
      guestName: guestName,
      guestPhone: guestPhone,
      user: userJson != null ? UserOut.fromJson(userJson) : null,
      table: tableJson != null ? TableEntityOut.fromJson(tableJson) : null,
      restaurant:
          restaurantJson != null
              ? RestaurantOut.fromJson(restaurantJson)
              : null,
    );
  }
}
