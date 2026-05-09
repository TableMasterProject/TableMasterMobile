import 'package:table_master_mobile/features/review/data/models/review_in.dart';

class ReviewOut extends ReviewIn {
  int id;
  DateTime createdAt;

  ReviewOut({
    required super.userId,
    required super.restaurantId,
    required super.rating,
    super.comment,
    required this.id,
    required this.createdAt,
  });

  factory ReviewOut.fromJson(Map<String, dynamic> json) {
    return ReviewOut(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      restaurantId: json['restaurantId'] ?? 0,
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }
}
