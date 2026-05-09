enum TableShape {
  square,
  rectangle,
  circle;

  int get apiValue => switch (this) {
        TableShape.square => 0,
        TableShape.rectangle => 1,
        TableShape.circle => 2,
      };

  static TableShape fromJson(dynamic value) {
    if (value is String) {
      return TableShape.values.firstWhere(
        (shape) => shape.name.toLowerCase() == value.toLowerCase(),
        orElse: () => TableShape.rectangle,
      );
    }

    return switch ((value as num?)?.toInt()) {
      0 => TableShape.square,
      2 => TableShape.circle,
      _ => TableShape.rectangle,
    };
  }
}

class TableEntityIn {
  int restaurantId;
  int? roomId;
  int tableNumber;
  int numberOfSeats;
  TableShape shape;
  double positionX;
  double positionY;
  double width;
  double height;
  double rotationDegrees;

  TableEntityIn({
    required this.restaurantId,
    this.roomId,
    required this.tableNumber,
    required this.numberOfSeats,
    this.shape = TableShape.rectangle,
    this.positionX = 0.1,
    this.positionY = 0.1,
    this.width = 0.16,
    this.height = 0.12,
    this.rotationDegrees = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'RestaurantId': restaurantId,
      'RoomId': roomId,
      'TableNumber': tableNumber,
      'NumberOfSeats': numberOfSeats,
      'Shape': shape.apiValue,
      'PositionX': positionX,
      'PositionY': positionY,
      'Width': width,
      'Height': height,
      'RotationDegrees': rotationDegrees,
    };
  }

  TableEntityIn copyWith({
    int? restaurantId,
    int? roomId,
    int? tableNumber,
    int? numberOfSeats,
    TableShape? shape,
    double? positionX,
    double? positionY,
    double? width,
    double? height,
    double? rotationDegrees,
  }) {
    return TableEntityIn(
      restaurantId: restaurantId ?? this.restaurantId,
      roomId: roomId ?? this.roomId,
      tableNumber: tableNumber ?? this.tableNumber,
      numberOfSeats: numberOfSeats ?? this.numberOfSeats,
      shape: shape ?? this.shape,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      width: width ?? this.width,
      height: height ?? this.height,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
    );
  }
}
