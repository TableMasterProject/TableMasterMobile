import '../../data/models/restaurant_in.dart';
import '../../data/models/restaurant_out.dart';
import '../../data/models/search_restaurant.dart';

abstract class IRestaurantRepository {
  Future<List<RestaurantOut>> getAllRestaurants(SearchRestaurant search);
  Future<RestaurantOut> getRestaurantDetails(int id);
  Future<RestaurantOut> createRestaurant(RestaurantIn restaurant);
  Future<RestaurantOut> updateRestaurant(int id, RestaurantIn restaurant);
  Future<bool> deleteRestaurant(int id);
}
