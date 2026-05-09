import 'package:table_master_mobile/features/table/data/models/table_entity_in.dart';

class TableEntityOut extends TableEntityIn {
  int id;
  DateTime createdAt;

  TableEntityOut({
    required super.restaurantId,
    super.roomId,
    required super.tableNumber,
    required super.numberOfSeats,
    super.shape = TableShape.rectangle,
    super.positionX = 0.1,
    super.positionY = 0.1,
    super.width = 0.16,
    super.height = 0.12,
    super.rotationDegrees = 0,
    required this.id,
    required this.createdAt,
  });

  factory TableEntityOut.fromJson(Map<String, dynamic> json) {
    return TableEntityOut(
      id: json['id'] ?? 0,
      restaurantId: json['restaurantId'] ?? 0,
      roomId: json['roomId'],
      tableNumber: json['tableNumber'] ?? 0,
      numberOfSeats: json['numberOfSeats'] ?? 0,
      shape: TableShape.fromJson(json['shape']),
      positionX: (json['positionX'] as num?)?.toDouble() ?? 0.1,
      positionY: (json['positionY'] as num?)?.toDouble() ?? 0.1,
      width: (json['width'] as num?)?.toDouble() ?? 0.16,
      height: (json['height'] as num?)?.toDouble() ?? 0.12,
      rotationDegrees: (json['rotationDegrees'] as num?)?.toDouble() ?? 0,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['Id'] = id;
    json['CreatedAt'] = createdAt.toIso8601String();
    return json;
  }
}
