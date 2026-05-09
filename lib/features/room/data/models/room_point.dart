class RoomPoint {
  double x;
  double y;

  RoomPoint({required this.x, required this.y});

  factory RoomPoint.fromJson(Map<String, dynamic> json) {
    return RoomPoint(
      x: (json['x'] ?? json['X'] ?? 0).toDouble(),
      y: (json['y'] ?? json['Y'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'X': x, 'Y': y};
  }
}
