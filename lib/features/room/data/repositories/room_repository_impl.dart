import '../../domain/repositories/room_repository.dart';
import '../datasources/room_datasource.dart';
import '../models/restaurant_room_in.dart';
import '../models/restaurant_room_layout.dart';
import '../models/restaurant_room_out.dart';

class RoomRepositoryImpl implements IRoomRepository {
  final RoomDataSource remoteDataSource;

  RoomRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<RestaurantRoomOut>> getRestaurantRooms(int restaurantId) {
    return remoteDataSource.getRoomsByRestaurant(restaurantId);
  }

  @override
  Future<RestaurantRoomOut> addRoom(int restaurantId, RestaurantRoomIn room) {
    return remoteDataSource.createRoom(restaurantId, room);
  }

  @override
  Future<RestaurantRoomOut> editRoom(int roomId, RestaurantRoomIn room) {
    return remoteDataSource.updateRoom(roomId, room);
  }

  @override
  Future<bool> removeRoom(int roomId) {
    return remoteDataSource.deleteRoom(roomId);
  }

  @override
  Future<RestaurantRoomLayoutOut> saveLayout(
    int roomId,
    RestaurantRoomLayoutIn layout,
  ) {
    return remoteDataSource.saveLayout(roomId, layout);
  }
}
