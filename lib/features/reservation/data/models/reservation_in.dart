class ReservationIn {
  int userId;
  int tableId;
  int restaurantId;
  DateTime reservationDate;
  int numberOfPeople;
  String? specialRequest;
  bool isValidate;

  ReservationIn({
    required this.userId,
    required this.tableId,
    required this.restaurantId,
    required this.reservationDate,
    required this.numberOfPeople,
    this.specialRequest,
    this.isValidate = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'UserId': userId,
      'TableId': tableId,
      'RestaurantId': restaurantId,
      'ReservationDate': reservationDate.toIso8601String(),
      'NumberOfPeople': numberOfPeople,
      'SpecialRequest': specialRequest,
      'IsValidate': isValidate,
    };
  }
}
