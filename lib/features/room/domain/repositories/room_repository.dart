import '../../data/models/restaurant_room_in.dart';
import '../../data/models/restaurant_room_layout.dart';
import '../../data/models/restaurant_room_out.dart';

abstract class IRoomRepository {
  Future<List<RestaurantRoomOut>> getRestaurantRooms(int restaurantId);
  Future<RestaurantRoomOut> addRoom(int restaurantId, RestaurantRoomIn room);
  Future<RestaurantRoomOut> editRoom(int roomId, RestaurantRoomIn room);
  Future<bool> removeRoom(int roomId);
  Future<RestaurantRoomLayoutOut> saveLayout(
    int roomId,
    RestaurantRoomLayoutIn layout,
  );
}
