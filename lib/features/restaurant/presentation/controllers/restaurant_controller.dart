import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:table_master_mobile/core/logging/app_logger.dart';
import 'package:table_master_mobile/core/signalr_service.dart';
import 'package:table_master_mobile/features/menu/data/models/menu_out.dart';
import 'package:table_master_mobile/features/menu/domain/repositories/menu_repository.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/reservation/data/models/search_reservations.dart';
import 'package:table_master_mobile/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_in.dart';
import 'package:table_master_mobile/features/restaurant/data/models/restaurant_out.dart';
import 'package:table_master_mobile/features/restaurant/domain/repositories/restaurant_repository.dart';
import 'package:table_master_mobile/features/table/data/models/table_changes.dart';
import 'package:table_master_mobile/features/table/domain/repositories/table_repository.dart';
import 'package:table_master_mobile/features/user/data/models/user_out.dart';

class RestaurantController extends ChangeNotifier {
  final IRestaurantRepository restaurantRepository;
  final IReservationRepository reservationRepository;
  final ITableRepository tableRepository;
  final IMenuRepository menuRepository;
  final SignalRService signalRService;
  final AudioPlayer audioPlayer;
  final bool enableRealtime;

  RestaurantController({
    required this.restaurantRepository,
    required this.reservationRepository,
    required this.tableRepository,
    required this.menuRepository,
    required this.signalRService,
    AudioPlayer? audioPlayer,
    this.enableRealtime = true,
  }) : audioPlayer = audioPlayer ?? AudioPlayer();

  RestaurantOut? restaurant;
  bool isLoading = false;
  bool isSaving = false;
  String? error;
  List<ReservationOut> reservations = [];
  List<ReservationOut> summaryReservations = [];
  List<MenuOut> menuItems = [];
  int viewIndex = 0;
  int selectedFilter = 0;
  VoidCallback? onNewReservation;

  StreamSubscription? _subCreated;
  StreamSubscription? _subValidated;
  StreamSubscription? _subDeleted;
  bool _disposed = false;

  Future<void> loadForUser(UserOut user) async {
    final restaurantId = user.restaurantId;
    if (restaurantId == null) return;

    _setLoading(true);
    error = null;
    _notify();

    try {
      restaurant = await restaurantRepository.getRestaurantDetails(restaurantId);
      await refreshAll();
      if (enableRealtime) await initSignalR();
    } catch (e) {
      error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshAll() async {
    final restaurantId = restaurant?.id;
    if (restaurantId == null) return;

    await Future.wait([
      loadSummary(restaurantId),
      loadDailyReservations(restaurantId),
      loadMenu(restaurantId),
    ]);
  }

  Future<void> refreshReservationData() async {
    final restaurantId = restaurant?.id;
    if (restaurantId == null) return;

    await Future.wait([
      loadSummary(restaurantId),
      loadDailyReservations(restaurantId),
    ]);
  }

  Future<void> reloadRestaurantDetails() async {
    final restaurantId = restaurant?.id;
    if (restaurantId == null) return;

    restaurant = await restaurantRepository.getRestaurantDetails(restaurantId);
    _notify();
  }

  Future<void> loadSummary(int restaurantId) async {
    try {
      final search = SearchReservations()
        ..restaurantId = restaurantId
        ..pageSize = 100
        ..statuses = [ReservationStatus.enAttente, ReservationStatus.validee];

      summaryReservations = await reservationRepository.getReservations(search);
      _notify();
    } catch (e) {
      AppLogger.debug("Erreur chargement résumé réservations", e);
    }
  }

  Future<void> loadDailyReservations(int restaurantId) async {
    try {
      final search = SearchReservations()
        ..restaurantId = restaurantId
        ..pageSize = 50;

      if (selectedFilter == 0) {
        search
          ..statuses = [ReservationStatus.validee]
          ..minDate = DateTime.now();
      } else if (selectedFilter == 1) {
        search.statuses = [ReservationStatus.enAttente];
      } else {
        search.statuses = [
          ReservationStatus.finie,
          ReservationStatus.annuleeResto,
          ReservationStatus.annuleeClient,
        ];
      }

      final results = await reservationRepository.getReservations(search);
      results.sort((a, b) => a.reservationDate.compareTo(b.reservationDate));
      reservations = results;
      _notify();
    } catch (e) {
      AppLogger.debug("Erreur chargement réservations restaurant", e);
    }
  }

  Future<void> loadMenu(int restaurantId) async {
    try {
      menuItems = await menuRepository.getByRestaurant(restaurantId);
      _notify();
    } catch (e) {
      AppLogger.debug("Erreur chargement menu restaurant", e);
    }
  }

  Future<void> updateReservationStatus(int id, ReservationStatus status) async {
    await reservationRepository.updateReservationStatus(id, status);
    await refreshReservationData();
  }

  Future<void> saveRestaurantSettings(RestaurantIn restaurantData) async {
    final restaurantId = restaurant?.id;
    if (restaurantId == null) return;

    _setSaving(true);
    try {
      await restaurantRepository.updateRestaurant(restaurantId, restaurantData);
      await reloadRestaurantDetails();
    } finally {
      _setSaving(false);
    }
  }

  Future<void> saveTableSettings(TableChanges changes) async {
    final restaurantId = restaurant?.id;
    if (restaurantId == null) return;

    _setSaving(true);
    try {
      for (final table in changes.toAdd) {
        await tableRepository.addTable(
          restaurantId,
          table.copyWith(restaurantId: restaurantId),
        );
      }

      for (final table in changes.toUpdate) {
        await tableRepository.editTable(
          table.id,
          table.copyWith(restaurantId: restaurantId),
        );
      }

      for (final table in changes.toDelete) {
        await tableRepository.removeTable(table.id);
      }

      await reloadRestaurantDetails();
    } finally {
      _setSaving(false);
    }
  }

  Future<void> attachCreatedRestaurant(UserOut user, RestaurantOut createdRestaurant) async {
    user.restaurantId = createdRestaurant.id;
    restaurant = createdRestaurant;
    _notify();

    await reloadRestaurantDetails();
    await refreshAll();
    if (enableRealtime) await initSignalR();
  }

  void selectView(int index) {
    viewIndex = index;
    _notify();
  }

  void selectReservationFilter(int index) {
    selectedFilter = index;
    _notify();
    final restaurantId = restaurant?.id;
    if (restaurantId != null) {
      loadDailyReservations(restaurantId);
    }
  }

  Future<void> initSignalR() async {
    final restaurantId = restaurant?.id;
    if (restaurantId == null) return;

    await _cancelSignalRSubscriptions();

    _subCreated = signalRService.onReservationCreated.listen((reservation) {
      if (reservation.restaurantId == restaurantId) {
        _playSound();
        refreshReservationData();
        onNewReservation?.call();
      }
    });

    _subValidated = signalRService.onReservationUpdateStatus.listen((reservation) {
      if (reservation.restaurantId == restaurantId) {
        refreshReservationData();
      }
    });

    _subDeleted = signalRService.onReservationDeleted.listen((_) {
      refreshReservationData();
    });

    await signalRService.init();
    await signalRService.joinRestaurantGroup(restaurantId);
  }

  Future<void> _playSound() async {
    try {
      await audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      AppLogger.debug("Erreur lecture son notification", e);
    }
  }

  Future<void> _cancelSignalRSubscriptions() async {
    await _subCreated?.cancel();
    await _subValidated?.cancel();
    await _subDeleted?.cancel();
    _subCreated = null;
    _subValidated = null;
    _subDeleted = null;
  }

  void _setLoading(bool value) {
    isLoading = value;
    _notify();
  }

  void _setSaving(bool value) {
    isSaving = value;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelSignalRSubscriptions();
    final restaurantId = restaurant?.id;
    if (restaurantId != null) {
      signalRService.leaveRestaurantGroup(restaurantId);
    }
    audioPlayer.dispose();
    super.dispose();
  }
}
