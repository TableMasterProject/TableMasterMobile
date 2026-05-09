class DailyActivityIn {
  int restaurantId;
  int dayOfWeek; // 0 = Dimanche, 1 = Lundi, etc.
  String startTime; // Format "HH:mm:ss" pour correspondre au TimeSpan C#
  String endTime;

  DailyActivityIn({
    required this.restaurantId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'RestaurantId': restaurantId,
      'DayOfWeek': dayOfWeek,
      'StartTime': startTime,
      'EndTime': endTime,
    };
  }

  DailyActivityIn copyWith({
    int? restaurantId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
  }) {
    return DailyActivityIn(
      restaurantId: restaurantId ?? this.restaurantId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
