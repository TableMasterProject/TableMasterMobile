import 'package:flutter/foundation.dart';
import '../../data/models/reservation_availability_out.dart';
import '../../data/models/search_reservations.dart';
import '../../domain/repositories/reservation_repository.dart';

class DayAvailabilityController extends ChangeNotifier {
  DayAvailabilityController(this._repository, this.restaurantId);

  final IReservationRepository _repository;
  final int restaurantId;
  DateTime? day;
  List<ReservationAvailabilityOut> reservations = [];
  bool isLoading = false;
  bool isReady = false;
  String? error;
  int _generation = 0;
  bool _disposed = false;

  Future<void> reload() async {
    final selected = day;
    if (selected != null) await load(selected);
  }

  Future<void> load(DateTime selectedDay) async {
    if (_disposed) return;
    final generation = ++_generation;
    day = selectedDay;
    isLoading = true;
    isReady = false;
    error = null;
    reservations = [];
    notifyListeners();
    try {
      final result = await _repository.getAvailability(
        SearchReservations(
          restaurantId: restaurantId,
          minDate: selectedDay,
          maxDate: selectedDay,
          pageSize: null,
          offset: null,
        ),
      );
      if (_disposed || generation != _generation) return;
      reservations = result;
      isReady = true;
    } catch (exception) {
      if (_disposed || generation != _generation) return;
      error = exception.toString();
    }
    if (_disposed || generation != _generation) return;
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
