import 'package:table_master_mobile/core/refresh_scheduler.dart';
import 'package:table_master_mobile/core/time/paris_time.dart';
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
import 'package:table_master_mobile/features/room/domain/repositories/room_repository.dart';
import 'package:table_master_mobile/features/table/data/models/table_changes.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_out.dart';
import 'package:table_master_mobile/features/table/domain/repositories/table_repository.dart';
import 'package:table_master_mobile/features/user/data/models/user_out.dart';

class RestaurantController extends ChangeNotifier {
  final IRestaurantRepository restaurantRepository;
  final IReservationRepository reservationRepository;
  final ITableRepository tableRepository;
  final IMenuRepository menuRepository;
  final IRoomRepository roomRepository;
  final SignalRService signalRService;
  final AudioPlayer audioPlayer;
  final bool enableRealtime;

  RestaurantController({
    required this.restaurantRepository,
    required this.reservationRepository,
    required this.tableRepository,
    required this.menuRepository,
    required this.roomRepository,
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
  List<ReservationOut> pendingReservations = [];
  List<ReservationOut> confirmedReservations = [];
  List<ReservationOut> serviceHistoryReservations = [];
  DateTime selectedServiceDate = DateTime(
    ParisTime.now().year,
    ParisTime.now().month,
    ParisTime.now().day,
  );
  bool serviceLoading = false;
  String? serviceError;
  bool pendingHasMore = false;
  bool confirmedHasMore = false;
  bool serviceHistoryHasMore = false;
  bool pendingLoadingMore = false;
  bool confirmedLoadingMore = false;
  TableEntityOut? selectedTable;
  List<ReservationOut> tablePendingReservations = [];
  List<ReservationOut> tableConfirmedReservations = [];
  List<ReservationOut> tableHistoryReservations = [];
  bool tablePendingHasMore = false;
  bool tableConfirmedHasMore = false;
  bool tableHistoryHasMore = false;
  bool tableLoading = false;
  String? tableError;
  List<MenuOut> menuItems = [];
  int viewIndex = 1;
  int selectedFilter = 1;
  VoidCallback? onNewReservation;

  late final RefreshScheduler _refreshScheduler = RefreshScheduler(refreshAll);
  StreamSubscription? _subResynchronized;
  int _dailyVersion = 0;
  int _serviceVersion = 0;
  int _tableVersion = 0;
  int _summaryVersion = 0;
  int _menuVersion = 0;
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
      restaurant = await restaurantRepository.getRestaurantDetails(
        restaurantId,
      );
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
      loadServiceReservations(restaurantId),
      loadMenu(restaurantId),
    ]);
  }

  Future<void> refreshReservationData() async {
    final restaurantId = restaurant?.id;
    if (restaurantId == null) return;

    await Future.wait([
      loadSummary(restaurantId),
      loadDailyReservations(restaurantId),
      loadServiceReservations(restaurantId),
      loadSelectedTableReservations(),
    ]);
  }

  Future<void> selectServiceDate(DateTime date) async {
    selectedServiceDate = DateTime(date.year, date.month, date.day);
    _notify();
    final restaurantId = restaurant?.id;
    if (restaurantId != null) {
      await Future.wait([
        loadServiceReservations(restaurantId),
        loadSelectedTableReservations(),
      ]);
    }
  }

  Future<void> selectTable(TableEntityOut table) async {
    selectedTable = table;
    _notify();
    await loadSelectedTableReservations();
  }

  void closeTable() {
    selectedTable = null;
    _tableVersion++;
    _notify();
  }

  Future<void> loadSelectedTableReservations() async {
    final restaurantId = restaurant?.id;
    final table = selectedTable;
    if (restaurantId == null || table == null) return;
    final version = ++_tableVersion;
    tableLoading = true;
    tableError = null;
    _notify();
    try {
      final result = await Future.wait([
        reservationRepository.getReservations(
          SearchReservations(
            restaurantId: restaurantId,
            tableId: table.id,
            pageSize: 50,
            statuses: [ReservationStatus.enAttente],
          ),
        ),
        reservationRepository.getReservations(
          SearchReservations(
            restaurantId: restaurantId,
            tableId: table.id,
            pageSize: 50,
            statuses: [ReservationStatus.validee],
            minDate: selectedServiceDate,
            maxDate: selectedServiceDate,
          ),
        ),
        reservationRepository.getReservations(
          SearchReservations(
            restaurantId: restaurantId,
            tableId: table.id,
            pageSize: 50,
            statuses: [
              ReservationStatus.finie,
              ReservationStatus.annuleeResto,
              ReservationStatus.annuleeClient,
            ],
            minDate: selectedServiceDate,
            maxDate: selectedServiceDate,
            sortDescending: true,
          ),
        ),
      ]);
      if (_disposed || version != _tableVersion) return;
      tablePendingReservations = result[0];
      tableConfirmedReservations = result[1];
      tableHistoryReservations = result[2];
      tablePendingHasMore = result[0].length == 50;
      tableConfirmedHasMore = result[1].length == 50;
      tableHistoryHasMore = result[2].length == 50;
    } catch (_) {
      if (!_disposed && version == _tableVersion) {
        tableError = 'Impossible de charger cette table.';
      }
    } finally {
      if (!_disposed && version == _tableVersion) {
        tableLoading = false;
        _notify();
      }
    }
  }

  Future<void> loadServiceReservations(int restaurantId) async {
    final version = ++_serviceVersion;
    serviceLoading = true;
    serviceError = null;
    _notify();
    try {
      final searches = [
        SearchReservations(
          restaurantId: restaurantId,
          pageSize: 50,
          statuses: [ReservationStatus.enAttente],
        ),
        SearchReservations(
          restaurantId: restaurantId,
          pageSize: 50,
          statuses: [ReservationStatus.validee],
          minDate: selectedServiceDate,
          maxDate: selectedServiceDate,
        ),
        SearchReservations(
          restaurantId: restaurantId,
          pageSize: 50,
          statuses: [
            ReservationStatus.finie,
            ReservationStatus.annuleeResto,
            ReservationStatus.annuleeClient,
          ],
          minDate: selectedServiceDate,
          maxDate: selectedServiceDate,
          sortDescending: true,
        ),
      ];
      final result = await Future.wait(
        searches.map(reservationRepository.getReservations),
      );
      if (_disposed ||
          version != _serviceVersion ||
          restaurant?.id != restaurantId) {
        return;
      }
      pendingReservations = result[0];
      confirmedReservations = result[1];
      serviceHistoryReservations = result[2];
      pendingHasMore = result[0].length == 50;
      confirmedHasMore = result[1].length == 50;
      serviceHistoryHasMore = result[2].length == 50;
    } catch (e) {
      if (!_disposed && version == _serviceVersion) {
        serviceError = 'Impossible de charger les réservations.';
      }
    } finally {
      if (!_disposed && version == _serviceVersion) {
        serviceLoading = false;
        _notify();
      }
    }
  }

  Future<void> loadMorePending() => _loadMoreService(pending: true);

  Future<void> loadMoreConfirmed() => _loadMoreService(pending: false);

  Future<void> loadMoreServiceHistory() async {
    final restaurantId = restaurant?.id;
    if (restaurantId == null || serviceLoading || !serviceHistoryHasMore) {
      return;
    }
    final version = _serviceVersion;
    final current = serviceHistoryReservations;
    try {
      final next = await reservationRepository.getReservations(
        SearchReservations(
          restaurantId: restaurantId,
          offset: current.length,
          pageSize: 50,
          statuses: [
            ReservationStatus.finie,
            ReservationStatus.annuleeResto,
            ReservationStatus.annuleeClient,
          ],
          minDate: selectedServiceDate,
          maxDate: selectedServiceDate,
          sortDescending: true,
        ),
      );
      if (_disposed || version != _serviceVersion) return;
      final ids = current.map((item) => item.id).toSet();
      serviceHistoryReservations = [
        ...current,
        ...next.where((item) => ids.add(item.id)),
      ];
      serviceHistoryHasMore = next.length == 50;
      _notify();
    } catch (_) {
      if (!_disposed && version == _serviceVersion) {
        serviceError = 'Impossible de charger la suite de l’historique.';
        _notify();
      }
    }
  }

  Future<void> loadMoreTableReservations(ReservationStatus status) async {
    final restaurantId = restaurant?.id;
    final table = selectedTable;
    if (restaurantId == null || table == null || tableLoading) return;
    final current =
        status == ReservationStatus.enAttente
            ? tablePendingReservations
            : status == ReservationStatus.validee
            ? tableConfirmedReservations
            : tableHistoryReservations;
    final hasMore =
        status == ReservationStatus.enAttente
            ? tablePendingHasMore
            : status == ReservationStatus.validee
            ? tableConfirmedHasMore
            : tableHistoryHasMore;
    if (!hasMore) return;
    final version = _tableVersion;
    try {
      final next = await reservationRepository.getReservations(
        SearchReservations(
          restaurantId: restaurantId,
          tableId: table.id,
          offset: current.length,
          pageSize: 50,
          statuses:
              status == ReservationStatus.finie
                  ? [
                    ReservationStatus.finie,
                    ReservationStatus.annuleeResto,
                    ReservationStatus.annuleeClient,
                  ]
                  : [status],
          minDate:
              status == ReservationStatus.enAttente
                  ? null
                  : selectedServiceDate,
          maxDate:
              status == ReservationStatus.enAttente
                  ? null
                  : selectedServiceDate,
          sortDescending: status == ReservationStatus.finie,
        ),
      );
      if (_disposed || version != _tableVersion) return;
      final ids = current.map((item) => item.id).toSet();
      final combined = [...current, ...next.where((item) => ids.add(item.id))];
      if (status == ReservationStatus.enAttente) {
        tablePendingReservations = combined;
        tablePendingHasMore = next.length == 50;
      } else if (status == ReservationStatus.validee) {
        tableConfirmedReservations = combined;
        tableConfirmedHasMore = next.length == 50;
      } else {
        tableHistoryReservations = combined;
        tableHistoryHasMore = next.length == 50;
      }
      _notify();
    } catch (_) {
      if (!_disposed && version == _tableVersion) {
        tableError = 'Impossible de charger la suite.';
        _notify();
      }
    }
  }

  Future<void> _loadMoreService({required bool pending}) async {
    final restaurantId = restaurant?.id;
    if (restaurantId == null || serviceLoading) return;
    if (pending
        ? (!pendingHasMore || pendingLoadingMore)
        : (!confirmedHasMore || confirmedLoadingMore)) {
      return;
    }
    final version = _serviceVersion;
    if (pending) {
      pendingLoadingMore = true;
    } else {
      confirmedLoadingMore = true;
    }
    _notify();
    try {
      final current = pending ? pendingReservations : confirmedReservations;
      final search = SearchReservations(
        restaurantId: restaurantId,
        offset: current.length,
        pageSize: 50,
        statuses: [
          pending ? ReservationStatus.enAttente : ReservationStatus.validee,
        ],
        minDate: pending ? null : selectedServiceDate,
        maxDate: pending ? null : selectedServiceDate,
      );
      final next = await reservationRepository.getReservations(search);
      if (_disposed || version != _serviceVersion) return;
      final ids = current.map((reservation) => reservation.id).toSet();
      final combined = [
        ...current,
        ...next.where((reservation) => ids.add(reservation.id)),
      ];
      if (pending) {
        pendingReservations = combined;
        pendingHasMore = next.length == 50;
      } else {
        confirmedReservations = combined;
        confirmedHasMore = next.length == 50;
      }
    } catch (_) {
      if (!_disposed && version == _serviceVersion) {
        serviceError = 'Impossible de charger plus de réservations.';
      }
    } finally {
      if (!_disposed && version == _serviceVersion) {
        if (pending) {
          pendingLoadingMore = false;
        } else {
          confirmedLoadingMore = false;
        }
        _notify();
      }
    }
  }

  Future<void> reloadRestaurantDetails() async {
    final restaurantId = restaurant?.id;
    if (restaurantId == null) return;

    restaurant = await restaurantRepository.getRestaurantDetails(restaurantId);
    _notify();
  }

  Future<void> loadSummary(int restaurantId) async {
    final version = ++_summaryVersion;
    try {
      final search =
          SearchReservations()
            ..restaurantId = restaurantId
            ..pageSize = 100
            ..statuses = [
              ReservationStatus.enAttente,
              ReservationStatus.validee,
            ];

      final results = await reservationRepository.getReservations(search);
      if (_disposed ||
          version != _summaryVersion ||
          restaurant?.id != restaurantId) {
        return;
      }
      summaryReservations = results;
      _notify();
    } catch (e) {
      AppLogger.debug("Erreur chargement résumé réservations", e);
    }
  }

  Future<void> loadDailyReservations(int restaurantId) async {
    final version = ++_dailyVersion;
    try {
      final search =
          SearchReservations()
            ..restaurantId = restaurantId
            ..pageSize = 50;

      if (selectedFilter == 0) {
        search
          ..statuses = [ReservationStatus.validee]
          ..minDate = ParisTime.now();
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
      results.sort(
        selectedFilter == 2
            ? (a, b) => b.reservationDate.compareTo(a.reservationDate)
            : (a, b) => a.reservationDate.compareTo(b.reservationDate),
      );
      if (_disposed ||
          version != _dailyVersion ||
          restaurant?.id != restaurantId) {
        return;
      }
      reservations = results;
      _notify();
    } catch (e) {
      AppLogger.debug("Erreur chargement réservations restaurant", e);
    }
  }

  Future<void> loadMenu(int restaurantId) async {
    final version = ++_menuVersion;
    try {
      final results = await menuRepository.getByRestaurant(restaurantId);
      if (_disposed ||
          version != _menuVersion ||
          restaurant?.id != restaurantId) {
        return;
      }
      menuItems = results;
      _notify();
    } catch (e) {
      AppLogger.debug("Erreur chargement menu restaurant", e);
    }
  }

  Future<void> updateReservationStatus(int id, ReservationStatus status) async {
    await reservationRepository.updateReservationStatus(id, status);
    await refreshReservationData();
  }

  Future<void> createQuickReservation(QuickReservationIn reservation) async {
    final restaurantId = restaurant?.id;
    if (restaurantId == null) return;

    _setSaving(true);
    try {
      await reservationRepository.createQuickReservation(
        restaurantId,
        reservation,
      );
      await refreshReservationData();
    } finally {
      _setSaving(false);
    }
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
      if (changes.layouts.isNotEmpty) {
        for (final draft in changes.layouts) {
          var roomId = draft.roomId;
          if (roomId == null) {
            final createdRoom = await roomRepository.addRoom(
              restaurantId,
              draft.room.copyWith(restaurantId: restaurantId),
            );
            roomId = createdRoom.id;
          }

          draft.layout.room.restaurantId = restaurantId;
          await roomRepository.saveLayout(roomId, draft.layout);
        }

        for (final roomId in changes.roomIdsToDelete) {
          await roomRepository.removeRoom(roomId);
        }
      } else {
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
      }

      await reloadRestaurantDetails();
    } finally {
      _setSaving(false);
    }
  }

  Future<void> attachCreatedRestaurant(
    UserOut user,
    RestaurantOut createdRestaurant,
  ) async {
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

    _subResynchronized = signalRService.onResynchronized.listen(
      (_) => _refreshScheduler.schedule(),
    );
    _subCreated = signalRService.onReservationCreated.listen((reservation) {
      if (reservation.restaurantId == restaurantId) {
        _playSound();
        _refreshScheduler.schedule();
        onNewReservation?.call();
      }
    });

    _subValidated = signalRService.onReservationUpdateStatus.listen((
      reservation,
    ) {
      if (reservation.restaurantId == restaurantId) {
        _refreshScheduler.schedule();
      }
    });

    _subDeleted = signalRService.onReservationDeleted.listen((_) {
      _refreshScheduler.schedule();
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
    await _subResynchronized?.cancel();
    _subResynchronized = null;
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
    _refreshScheduler.dispose();
    _dailyVersion++;
    _serviceVersion++;
    _tableVersion++;
    _summaryVersion++;
    _menuVersion++;
    _cancelSignalRSubscriptions();
    final restaurantId = restaurant?.id;
    if (restaurantId != null) {
      signalRService.leaveRestaurantGroup(restaurantId);
    }
    audioPlayer.dispose();
    super.dispose();
  }
}
