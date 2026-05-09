import 'restaurant_room_in.dart';
import 'room_point.dart';

class RestaurantRoomOut extends RestaurantRoomIn {
  int id;
  DateTime createdAt;

  RestaurantRoomOut({
    required super.restaurantId,
    required super.name,
    required super.sortOrder,
    required super.boundaryPoints,
    required this.id,
    required this.createdAt,
  });

  factory RestaurantRoomOut.fromJson(Map<String, dynamic> json) {
    final points = json['boundaryPoints'] ?? json['BoundaryPoints'];
    return RestaurantRoomOut(
      id: json['id'] ?? 0,
      restaurantId: json['restaurantId'] ?? 0,
      name: json['name'] ?? '',
      sortOrder: json['sortOrder'] ?? 0,
      boundaryPoints: points is List
          ? points.map((point) => RoomPoint.fromJson(Map<String, dynamic>.from(point))).toList()
          : RestaurantRoomIn.defaultRoom().boundaryPoints,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
