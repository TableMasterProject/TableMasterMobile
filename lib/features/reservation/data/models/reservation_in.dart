import 'package:table_master_mobile/core/time/paris_time.dart';

enum ReservationStatus {
  enAttente, // 0
  validee, // 1
  finie, // 2
  annuleeResto, // 3
  annuleeClient, // 4
}

class ReservationIn {
  int userId;
  int tableId;
  int restaurantId;
  DateTime reservationDate;
  int numberOfPeople;
  ReservationStatus status;
  String? specialRequest;

  ReservationIn({
    required this.userId,
    required this.tableId,
    required this.restaurantId,
    required this.reservationDate,
    required this.numberOfPeople,
    required this.status,
    this.specialRequest,
  });

  Map<String, dynamic> toJson() {
    return {
      'UserId': userId,
      'TableId': tableId,
      'RestaurantId': restaurantId,
      'ReservationDate': ParisTime.serialize(reservationDate),
      'NumberOfPeople': numberOfPeople,
      'Status': status.index,
      'SpecialRequest': specialRequest,
    };
  }
}

class QuickReservationIn {
  int tableId;
  DateTime reservationDate;
  int numberOfPeople;
  String guestName;
  String? guestPhone;
  String? specialRequest;

  QuickReservationIn({
    required this.tableId,
    required this.reservationDate,
    required this.numberOfPeople,
    required this.guestName,
    this.guestPhone,
    this.specialRequest,
  });

  Map<String, dynamic> toJson() {
    return {
      'TableId': tableId,
      'ReservationDate': ParisTime.serialize(reservationDate),
      'NumberOfPeople': numberOfPeople,
      'GuestName': guestName,
      'GuestPhone': guestPhone,
      'SpecialRequest': specialRequest,
    };
  }
}
