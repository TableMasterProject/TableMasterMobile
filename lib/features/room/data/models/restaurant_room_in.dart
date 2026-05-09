import 'room_point.dart';

class RestaurantRoomIn {
  int restaurantId;
  String name;
  int sortOrder;
  List<RoomPoint> boundaryPoints;

  RestaurantRoomIn({
    required this.restaurantId,
    required this.name,
    required this.sortOrder,
    required this.boundaryPoints,
  });

  factory RestaurantRoomIn.defaultRoom({int restaurantId = 0}) {
    return RestaurantRoomIn(
      restaurantId: restaurantId,
      name: 'Salle principale',
      sortOrder: 0,
      boundaryPoints: [
        RoomPoint(x: 0.05, y: 0.05),
        RoomPoint(x: 0.95, y: 0.05),
        RoomPoint(x: 0.95, y: 0.95),
        RoomPoint(x: 0.05, y: 0.95),
      ],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'RestaurantId': restaurantId,
      'Name': name,
      'SortOrder': sortOrder,
      'BoundaryPoints': boundaryPoints.map((point) => point.toJson()).toList(),
    };
  }

  RestaurantRoomIn copyWith({
    int? restaurantId,
    String? name,
    int? sortOrder,
    List<RoomPoint>? boundaryPoints,
  }) {
    return RestaurantRoomIn(
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      boundaryPoints: boundaryPoints ?? this.boundaryPoints,
    );
  }
}
