import 'closed_day_exception_in.dart';

class ClosedDayExceptionOut extends ClosedDayExceptionIn {
  int id;
  DateTime createdAt;

  ClosedDayExceptionOut({
    required super.restaurantId,
    required super.exceptionDateBegin,
    required super.exceptionDateEnd,
    required super.reason,
    required this.id,
    required this.createdAt,
  });

  factory ClosedDayExceptionOut.fromJson(Map<String, dynamic> json) {
    return ClosedDayExceptionOut(
      id: json['id'] ?? 0,
      restaurantId: json['restaurantId'] ?? 0,
      exceptionDateBegin:
          json['exceptionDateBegin'] != null
              ? DateTime.parse(json['exceptionDateBegin'])
              : DateTime.now(),
      exceptionDateEnd:
          json['exceptionDateEnd'] != null
              ? DateTime.parse(json['exceptionDateEnd'])
              : DateTime.now(),
      reason: json['reason'] ?? '',
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }
}
