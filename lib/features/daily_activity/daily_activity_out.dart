import 'daily_activity_in.dart';

class DailyActivityOut extends DailyActivityIn {
  int id;
  DateTime createdAt;

  DailyActivityOut({
    required super.restaurantId,
    required super.dayOfWeek,
    required super.startTime,
    required super.endTime,
    required this.id,
    required this.createdAt,
  });

  factory DailyActivityOut.fromJson(Map<String, dynamic> json) {
    return DailyActivityOut(
      id: json['id'] ?? 0,
      restaurantId: json['restaurantId'] ?? 0,
      dayOfWeek: json['dayOfWeek'] ?? 0,
      startTime: json['startTime'] ?? "00:00:00",
      endTime: json['endTime'] ?? "00:00:00",
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}