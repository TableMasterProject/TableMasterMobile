class ReservationAvailabilityOut {
  final int tableId;
  final DateTime reservationDate;

  const ReservationAvailabilityOut({
    required this.tableId,
    required this.reservationDate,
  });

  factory ReservationAvailabilityOut.fromJson(Map<String, dynamic> json) {
    return ReservationAvailabilityOut(
      tableId: json['tableId'] as int,
      reservationDate: DateTime.parse(json['reservationDate'] as String),
    );
  }
}
