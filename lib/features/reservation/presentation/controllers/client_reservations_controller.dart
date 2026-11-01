import 'package:flutter/foundation.dart';
import 'package:table_master_mobile/core/time/paris_time.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';
import 'package:table_master_mobile/features/reservation/data/models/reservation_out.dart';
import 'package:table_master_mobile/features/reservation/data/models/search_reservations.dart';
import 'package:table_master_mobile/features/reservation/domain/repositories/reservation_repository.dart';

class ClientReservationsController extends ChangeNotifier {
  ClientReservationsController({required this.repository, DateTime? today})
    : today = _dateOnly(today ?? ParisTime.now());

  final IReservationRepository repository;
  final DateTime today;
  static const pageSize = 50;
  List<ReservationOut> upcoming = [];
  List<ReservationOut> history = [];
  bool upcomingLoading = false;
  bool historyLoading = false;
  bool upcomingHasMore = false;
  bool historyHasMore = false;
  String? upcomingError;
  String? historyError;
  int _upcomingVersion = 0;
  int _historyVersion = 0;
  int _pastOffset = 0;
  int _terminalOffset = 0;
  bool _pastHasMore = true;
  bool _terminalHasMore = true;
  bool _disposed = false;

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  SearchReservations _upcomingSearch(int offset) => SearchReservations(
    offset: offset,
    pageSize: pageSize,
    minDate: today,
    statuses: [ReservationStatus.enAttente, ReservationStatus.validee],
  );

  SearchReservations _pastSearch(int offset) => SearchReservations(
    offset: offset,
    pageSize: pageSize,
    maxDate: today.subtract(const Duration(days: 1)),
    sortDescending: true,
  );

  SearchReservations _terminalSearch(int offset) => SearchReservations(
    offset: offset,
    pageSize: pageSize,
    minDate: today,
    statuses: [
      ReservationStatus.finie,
      ReservationStatus.annuleeResto,
      ReservationStatus.annuleeClient,
    ],
    sortDescending: true,
  );

  Future<void> loadUpcoming() async {
    final version = ++_upcomingVersion;
    upcomingLoading = true;
    upcomingError = null;
    notifyListeners();
    try {
      final result = await repository.getMyReservations(_upcomingSearch(0));
      if (_disposed || version != _upcomingVersion) return;
      upcoming = result..sort(_ascending);
      upcomingHasMore = result.length == pageSize;
    } catch (_) {
      if (!_disposed && version == _upcomingVersion) {
        upcomingError = 'Impossible de charger vos réservations.';
      }
    } finally {
      if (!_disposed && version == _upcomingVersion) {
        upcomingLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMoreUpcoming() async {
    if (upcomingLoading || !upcomingHasMore) return;
    final version = _upcomingVersion;
    upcomingLoading = true;
    notifyListeners();
    try {
      final result = await repository.getMyReservations(
        _upcomingSearch(upcoming.length),
      );
      if (_disposed || version != _upcomingVersion) return;
      final ids = upcoming.map((item) => item.id).toSet();
      upcoming = [...upcoming, ...result.where((item) => ids.add(item.id))]
        ..sort(_ascending);
      upcomingHasMore = result.length == pageSize;
    } catch (_) {
      if (!_disposed) upcomingError = 'Impossible de charger la suite.';
    } finally {
      if (!_disposed && version == _upcomingVersion) {
        upcomingLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadHistory() async {
    final version = ++_historyVersion;
    historyLoading = true;
    historyError = null;
    notifyListeners();
    try {
      final result = await Future.wait([
        repository.getMyReservations(_pastSearch(0)),
        repository.getMyReservations(_terminalSearch(0)),
      ]);
      if (_disposed || version != _historyVersion) return;
      _pastOffset = result[0].length;
      _terminalOffset = result[1].length;
      _pastHasMore = result[0].length == pageSize;
      _terminalHasMore = result[1].length == pageSize;
      historyHasMore = _pastHasMore || _terminalHasMore;
      history = _mergedHistory(result[0], result[1]);
    } catch (_) {
      if (!_disposed && version == _historyVersion) {
        historyError = 'Impossible de charger votre historique.';
      }
    } finally {
      if (!_disposed && version == _historyVersion) {
        historyLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMoreHistory() async {
    if (historyLoading || !historyHasMore) return;
    final version = _historyVersion;
    historyLoading = true;
    notifyListeners();
    try {
      final past =
          _pastHasMore
              ? await repository.getMyReservations(_pastSearch(_pastOffset))
              : <ReservationOut>[];
      final terminal =
          _terminalHasMore
              ? await repository.getMyReservations(
                _terminalSearch(_terminalOffset),
              )
              : <ReservationOut>[];
      if (_disposed || version != _historyVersion) return;
      _pastOffset += past.length;
      _terminalOffset += terminal.length;
      _pastHasMore = _pastHasMore && past.length == pageSize;
      _terminalHasMore = _terminalHasMore && terminal.length == pageSize;
      historyHasMore = _pastHasMore || _terminalHasMore;
      history = _mergedHistory(history, [...past, ...terminal]);
    } catch (_) {
      if (!_disposed) historyError = 'Impossible de charger la suite.';
    } finally {
      if (!_disposed && version == _historyVersion) {
        historyLoading = false;
        notifyListeners();
      }
    }
  }

  static int _ascending(ReservationOut a, ReservationOut b) {
    final date = a.reservationDate.compareTo(b.reservationDate);
    return date != 0 ? date : a.id.compareTo(b.id);
  }

  static List<ReservationOut> _mergedHistory(
    List<ReservationOut> first,
    List<ReservationOut> second,
  ) {
    final byId = {
      for (final item in [...first, ...second]) item.id: item,
    };
    return byId.values.toList()..sort((a, b) => -_ascending(a, b));
  }

  @override
  void dispose() {
    _disposed = true;
    _upcomingVersion++;
    _historyVersion++;
    super.dispose();
  }
}
