import 'package:table_master_mobile/features/room/data/models/restaurant_room_in.dart';
import 'package:table_master_mobile/features/room/data/models/restaurant_room_layout.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_in.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_out.dart';

class RoomLayoutDraft {
  final int? roomId;
  final RestaurantRoomIn room;
  final RestaurantRoomLayoutIn layout;

  RoomLayoutDraft({
    required this.roomId,
    required this.room,
    required this.layout,
  });
}

class TableChanges {
  final List<TableEntityIn> toAdd;
  final List<TableEntityOut> toUpdate;
  final List<TableEntityOut> toDelete;
  final List<RoomLayoutDraft> layouts;
  final List<int> roomIdsToDelete;

  TableChanges({
    required this.toAdd,
    required this.toUpdate,
    required this.toDelete,
    this.layouts = const [],
    this.roomIdsToDelete = const [],
  });
}
