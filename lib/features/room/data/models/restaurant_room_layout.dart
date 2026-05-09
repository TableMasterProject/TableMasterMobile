import 'package:table_master_mobile/features/table/data/models/table_entity_in.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_out.dart';

import 'restaurant_room_in.dart';
import 'restaurant_room_out.dart';

class RestaurantRoomLayoutIn {
  final RestaurantRoomIn room;
  final List<TableEntityIn> tablesToAdd;
  final List<TableEntityOut> tablesToUpdate;
  final List<int> tableIdsToDelete;

  RestaurantRoomLayoutIn({
    required this.room,
    required this.tablesToAdd,
    required this.tablesToUpdate,
    required this.tableIdsToDelete,
  });

  Map<String, dynamic> toJson() {
    return {
      'Room': room.toJson(),
      'TablesToAdd': tablesToAdd.map((table) => table.toJson()).toList(),
      'TablesToUpdate': tablesToUpdate.map((table) => table.toJson()).toList(),
      'TableIdsToDelete': tableIdsToDelete,
    };
  }
}

class RestaurantRoomLayoutOut {
  final RestaurantRoomOut room;
  final List<TableEntityOut> tables;

  RestaurantRoomLayoutOut({required this.room, required this.tables});

  factory RestaurantRoomLayoutOut.fromJson(Map<String, dynamic> json) {
    return RestaurantRoomLayoutOut(
      room: RestaurantRoomOut.fromJson(json['room'] ?? json['Room']),
      tables:
          (json['tables'] as List? ?? [])
              .map((table) => TableEntityOut.fromJson(table))
              .toList(),
    );
  }
}
