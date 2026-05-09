import '../../data/models/review_in.dart';
import '../../data/models/review_out.dart';
import '../../data/models/search_reviews.dart';

abstract class IReviewRepository {
  Future<List<ReviewOut>> getByRestaurant(
    int restaurantId,
    SearchReviews search,
  );
  Future<List<ReviewOut>> getMyReviews(SearchReviews search);
  Future<ReviewOut> addReview(ReviewIn review);
  Future<ReviewOut> updateReview(int id, ReviewIn review);
  Future<bool> deleteReview(int id);
}
