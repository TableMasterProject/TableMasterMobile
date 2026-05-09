class ClosedDayExceptionIn {
  int restaurantId;
  DateTime exceptionDateBegin;
  DateTime exceptionDateEnd;
  String reason;

  ClosedDayExceptionIn({
    required this.restaurantId,
    required this.exceptionDateBegin,
    required this.exceptionDateEnd,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'RestaurantId': restaurantId,
      'ExceptionDateBegin': exceptionDateBegin.toIso8601String(),
      'ExceptionDateEnd': exceptionDateEnd.toIso8601String(),
      'Reason': reason,
    };
  }

  ClosedDayExceptionIn copyWith({
    int? restaurantId,
    DateTime? exceptionDateBegin,
    DateTime? exceptionDateEnd,
    String? reason,
  }) {
    return ClosedDayExceptionIn(
      restaurantId: restaurantId ?? this.restaurantId,
      exceptionDateBegin: exceptionDateBegin ?? this.exceptionDateBegin,
      exceptionDateEnd: exceptionDateEnd ?? this.exceptionDateEnd,
      reason: reason ?? this.reason,
    );
  }
}
