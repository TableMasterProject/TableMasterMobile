import 'package:table_master_mobile/features/table/data/models/table_entity_in.dart';

class TableEntityOut extends TableEntityIn {
  int id;
  DateTime createdAt;

  TableEntityOut({
    required super.restaurantId,
    required super.tableNumber,
    required super.numberOfSeats,
    required this.id,
    required this.createdAt,
  });

  factory TableEntityOut.fromJson(Map<String, dynamic> json) {
    return TableEntityOut(
      id: json['id'] ?? 0,
      restaurantId: json['restaurantId'] ?? 0,
      tableNumber: json['tableNumber'] ?? 0,
      numberOfSeats: json['numberOfSeats'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}