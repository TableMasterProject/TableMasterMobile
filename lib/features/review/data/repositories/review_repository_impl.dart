import 'package:table_master_mobile/features/review/data/models/search_reviews.dart';
import '../../domain/repositories/review_repository.dart';
import '../models/review_in.dart';
import '../models/review_out.dart';
import '../datasources/review_datasource.dart';

class ReviewRepositoryImpl implements IReviewRepository {
  final ReviewDataSource dataSource;

  ReviewRepositoryImpl(this.dataSource);

  @override
  Future<List<ReviewOut>> getByRestaurant(int restaurantId, SearchReviews search) {
    return dataSource.getByRestaurant(restaurantId, search);
  }

  @override
  Future<List<ReviewOut>> getMyReviews(SearchReviews search) {
    return dataSource.getMy(search);
  }

  @override
  Future<ReviewOut> addReview(ReviewIn review) {
    return dataSource.create(review);
  }

  @override
  Future<ReviewOut> updateReview(int id, ReviewIn review) {
    return dataSource.update(id, review);
  }

  @override
  Future<bool> deleteReview(int id) {
    return dataSource.delete(id);
  }
}
