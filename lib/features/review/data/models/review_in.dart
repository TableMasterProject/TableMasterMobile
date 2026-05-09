class ReviewIn {
  int userId;
  int restaurantId;
  int rating;
  String? comment;

  ReviewIn({
    required this.userId,
    required this.restaurantId,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'UserId': userId,
      'RestaurantId': restaurantId,
      'Rating': rating,
      'Comment': comment,
    };
  }

  ReviewIn copyWith({
    int? userId,
    int? restaurantId,
    int? rating,
    String? comment,
  }) {
    return ReviewIn(
      userId: userId ?? this.userId,
      restaurantId: restaurantId ?? this.restaurantId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
    );
  }
}
