import '../../domain/repositories/restaurant_repository.dart';
import '../datasources/restaurant_datasource.dart';
import '../models/restaurant_in.dart';
import '../models/restaurant_out.dart';
import '../models/search_restaurant.dart';

class RestaurantRepositoryImpl implements IRestaurantRepository {
  final RestaurantDataSource remoteDataSource;

  RestaurantRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<RestaurantOut>> getAllRestaurants(SearchRestaurant search) async {
    return await remoteDataSource.getRestaurants(search);
  }

  @override
  Future<RestaurantOut> getRestaurantDetails(int id) async {
    return await remoteDataSource.getRestaurantById(id);
  }

  @override
  Future<RestaurantOut> createRestaurant(RestaurantIn restaurant) async {
    return await remoteDataSource.postRestaurant(restaurant);
  }

  @override
  Future<RestaurantOut> updateRestaurant(
    int id,
    RestaurantIn restaurant,
  ) async {
    return await remoteDataSource.updateRestaurant(id, restaurant);
  }

  @override
  Future<bool> deleteRestaurant(int id) async {
    return await remoteDataSource.deleteRestaurant(id);
  }
}
