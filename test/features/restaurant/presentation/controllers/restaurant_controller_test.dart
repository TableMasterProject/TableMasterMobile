import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_master_mobile/core/signalr_service.dart';
import 'package:table_master_mobile/features/menu/data/models/menu_in.dart';
import 'package:table_master_mobile/features/menu/data/models/menu_out.dart';
import 'package:table_master_mobile/features/menu/domain/repositories/menu_repository.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/reservation/data/models/search_reservations.dart';
import 'package:table_master_mobile/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_in.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_out.dart';
import 'package:table_master_mobile/features/restaurant/data/models/search_restaurant.dart';
import 'package:table_master_mobile/features/restaurant/domain/repositories/restaurant_repository.dart';
import 'package:table_master_mobile/features/restaurant/presentation/controllers/restaurant_controller.dart';
import 'package:table_master_mobile/features/room/data/models/restaurant_room_in.dart';
import 'package:table_master_mobile/features/room/data/models/restaurant_room_layout.dart';
import 'package:table_master_mobile/features/room/data/models/restaurant_room_out.dart';
import 'package:table_master_mobile/features/room/domain/repositories/room_repository.dart';
import 'package:table_master_mobile/features/table/data/models/table_changes.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_in.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_out.dart';
import 'package:table_master_mobile/features/table/domain/repositories/table_repository.dart';
import 'package:table_master_mobile/features/user/data/models/user_out.dart';

void main() {
  // RestaurantController instancie un AudioPlayer dans son constructeur (sons de notif).
  // En environnement de test, le plugin natif `audioplayers` n'est pas disponible :
  // 1. on initialise le binding pour exposer `defaultBinaryMessenger`,
  // 2. on enregistre des handlers no-op sur les channels du plugin pour intercepter
  //    les appels init/listen et éviter `MissingPluginException`.
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final channelName in const [
    'xyz.luan/audioplayers.global',
    'xyz.luan/audioplayers.global/events',
    'xyz.luan/audioplayers',
    'xyz.luan/audioplayers/events',
  ]) {
    messenger.setMockMethodCallHandler(
      MethodChannel(channelName),
      (_) async => null,
    );
  }

  test(
    'saveRestaurantSettings met à jour le restaurant via le repository',
    () async {
      final restaurantRepo = _FakeRestaurantRepository();
      final controller = _buildController(restaurantRepo: restaurantRepo)
        ..restaurant = _restaurant(id: 10);

      final updated = _restaurantIn(name: 'Nouveau nom');
      await controller.saveRestaurantSettings(updated);

      expect(restaurantRepo.updatedRestaurantId, 10);
      expect(restaurantRepo.updatedRestaurant?.restaurantName, 'Nouveau nom');
      expect(controller.restaurant?.restaurantName, 'Restaurant 10');
    },
  );

  test(
    'saveTableSettings applique les ajouts modifications suppressions',
    () async {
      final tableRepo = _FakeTableRepository();
      final controller = _buildController(tableRepo: tableRepo)
        ..restaurant = _restaurant(id: 7);

      await controller.saveTableSettings(
        TableChanges(
          toAdd: [
            TableEntityIn(restaurantId: 0, tableNumber: 3, numberOfSeats: 2),
          ],
          toUpdate: [
            TableEntityOut(
              id: 22,
              restaurantId: 7,
              tableNumber: 4,
              numberOfSeats: 6,
              createdAt: DateTime(2024),
            ),
          ],
          toDelete: [
            TableEntityOut(
              id: 23,
              restaurantId: 7,
              tableNumber: 5,
              numberOfSeats: 2,
              createdAt: DateTime(2024),
            ),
          ],
        ),
      );

      expect(tableRepo.added.single.restaurantId, 7);
      expect(tableRepo.updatedIds.single, 22);
      expect(tableRepo.removedIds.single, 23);
    },
  );

  test(
    'attachCreatedRestaurant met à jour UserOut.restaurantId et recharge les données',
    () async {
      final user = UserOut(
        id: 5,
        email: 'resto@test.fr',
        password: '',
        firstName: 'Resto',
        lastName: 'Owner',
        accountType: 1,
        createdAt: DateTime(2024),
      );
      final controller = _buildController();

      await controller.attachCreatedRestaurant(user, _restaurant(id: 42));

      expect(user.restaurantId, 42);
      expect(controller.restaurant?.id, 42);
      expect(controller.menuItems, isEmpty);
    },
  );
}

RestaurantController _buildController({
  _FakeRestaurantRepository? restaurantRepo,
  _FakeReservationRepository? reservationRepo,
  _FakeTableRepository? tableRepo,
  _FakeMenuRepository? menuRepo,
  _FakeRoomRepository? roomRepo,
}) {
  return RestaurantController(
    restaurantRepository: restaurantRepo ?? _FakeRestaurantRepository(),
    reservationRepository: reservationRepo ?? _FakeReservationRepository(),
    tableRepository: tableRepo ?? _FakeTableRepository(),
    menuRepository: menuRepo ?? _FakeMenuRepository(),
    roomRepository: roomRepo ?? _FakeRoomRepository(),
    signalRService: SignalRService(),
    enableRealtime: false,
  );
}

class _FakeRoomRepository implements IRoomRepository {
  final List<int> savedLayoutRoomIds = [];

  @override
  Future<RestaurantRoomOut> addRoom(
    int restaurantId,
    RestaurantRoomIn room,
  ) async {
    return RestaurantRoomOut(
      id: 1,
      restaurantId: restaurantId,
      name: room.name,
      sortOrder: room.sortOrder,
      boundaryPoints: room.boundaryPoints,
      createdAt: DateTime(2024),
    );
  }

  @override
  Future<RestaurantRoomOut> editRoom(int roomId, RestaurantRoomIn room) async {
    return RestaurantRoomOut(
      id: roomId,
      restaurantId: room.restaurantId,
      name: room.name,
      sortOrder: room.sortOrder,
      boundaryPoints: room.boundaryPoints,
      createdAt: DateTime(2024),
    );
  }

  @override
  Future<List<RestaurantRoomOut>> getRestaurantRooms(int restaurantId) async =>
      [];

  @override
  Future<bool> removeRoom(int roomId) async => true;

  @override
  Future<RestaurantRoomLayoutOut> saveLayout(
    int roomId,
    RestaurantRoomLayoutIn layout,
  ) async {
    savedLayoutRoomIds.add(roomId);
    return RestaurantRoomLayoutOut(
      room: RestaurantRoomOut(
        id: roomId,
        restaurantId: layout.room.restaurantId,
        name: layout.room.name,
        sortOrder: layout.room.sortOrder,
        boundaryPoints: layout.room.boundaryPoints,
        createdAt: DateTime(2024),
      ),
      tables: [],
    );
  }
}

RestaurantIn _restaurantIn({String name = 'Restaurant'}) {
  return RestaurantIn(
    userId: 1,
    restaurantName: name,
    streetNumber: '1',
    streetName: 'Rue Test',
    postalCode: '75000',
    city: 'Paris',
    phone: '0102030405',
    cuisineType: 'Française',
    paymentMethods: 'CB',
    description: 'Description',
    isAutoValidateReservation: false,
  );
}

RestaurantOut _restaurant({required int id}) {
  final input = _restaurantIn(name: 'Restaurant $id');
  return RestaurantOut(
    userId: input.userId,
    restaurantName: input.restaurantName,
    streetNumber: input.streetNumber,
    streetName: input.streetName,
    postalCode: input.postalCode,
    city: input.city,
    phone: input.phone,
    cuisineType: input.cuisineType,
    paymentMethods: input.paymentMethods,
    description: input.description,
    isAutoValidateReservation: input.isAutoValidateReservation,
    id: id,
    createdAt: DateTime(2024),
    distanceForSearch: 0,
    distanceWithUser: 0,
    averageRating: 0,
    numberOfReviews: 0,
    tables: [],
  );
}

class _FakeRestaurantRepository implements IRestaurantRepository {
  int? updatedRestaurantId;
  RestaurantIn? updatedRestaurant;

  @override
  Future<RestaurantOut> createRestaurant(RestaurantIn restaurant) async {
    return _restaurant(id: 42);
  }

  @override
  Future<bool> deleteRestaurant(int id) async => true;

  @override
  Future<List<RestaurantOut>> getAllRestaurants(
    SearchRestaurant search,
  ) async => [];

  @override
  Future<RestaurantOut> getRestaurantDetails(int id) async =>
      _restaurant(id: id);

  @override
  Future<RestaurantOut> updateRestaurant(
    int id,
    RestaurantIn restaurant,
  ) async {
    updatedRestaurantId = id;
    updatedRestaurant = restaurant;
    return _restaurant(id: id);
  }
}

class _FakeReservationRepository implements IReservationRepository {
  @override
  Future<ReservationOut> createReservation(Map<String, dynamic> data) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteReservation(int id) async => true;

  @override
  Future<List<ReservationOut>> getMyReservations(
    SearchReservations search,
  ) async => [];

  @override
  Future<List<ReservationOut>> getReservations(
    SearchReservations search,
  ) async => [];

  @override
  Future<ReservationOut> updateReservationStatus(
    int id,
    ReservationStatus reservationStatus,
  ) async {
    return ReservationOut(
      id: id,
      createdAt: DateTime(2024),
      userId: 1,
      tableId: 1,
      restaurantId: 1,
      reservationDate: DateTime(2024),
      numberOfPeople: 2,
      status: reservationStatus,
    );
  }
}

class _FakeTableRepository implements ITableRepository {
  final List<TableEntityIn> added = [];
  final List<int> updatedIds = [];
  final List<int> removedIds = [];

  @override
  Future<TableEntityOut> addTable(int restaurantId, TableEntityIn table) async {
    added.add(table);
    return TableEntityOut(
      id: 1,
      restaurantId: restaurantId,
      tableNumber: table.tableNumber,
      numberOfSeats: table.numberOfSeats,
      createdAt: DateTime(2024),
    );
  }

  @override
  Future<TableEntityOut> editTable(int id, TableEntityIn table) async {
    updatedIds.add(id);
    return TableEntityOut(
      id: id,
      restaurantId: table.restaurantId,
      tableNumber: table.tableNumber,
      numberOfSeats: table.numberOfSeats,
      createdAt: DateTime(2024),
    );
  }

  @override
  Future<List<TableEntityOut>> getRestaurantTables(int restaurantId) async =>
      [];

  @override
  Future<bool> removeTable(int id) async {
    removedIds.add(id);
    return true;
  }

  @override
  Future<List<TableEntityOut>> replaceTables(
    int restaurantId,
    List<TableEntityIn> tables,
  ) async {
    added.addAll(tables);
    return [];
  }
}

class _FakeMenuRepository implements IMenuRepository {
  @override
  Future<MenuOut> create(MenuIn menu) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> delete(int id) async => true;

  @override
  Future<List<MenuOut>> getByRestaurant(int restaurantId) async => [];
}
