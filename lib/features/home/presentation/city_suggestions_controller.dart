import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:table_master_mobile/features/home/data/city_search_service.dart';

class CitySuggestionsController extends ChangeNotifier {
  CitySuggestionsController({
    required this.search,
    this.debounce = const Duration(milliseconds: 300),
  });

  final Future<List<CitySuggestion>> Function(String query) search;
  final Duration debounce;
  Timer? _timer;
  int _version = 0;
  bool _disposed = false;
  List<CitySuggestion> cities = [];
  bool loading = false;
  bool hasError = false;

  void updateQuery(String input) {
    _timer?.cancel();
    final version = ++_version;
    cities = [];
    hasError = false;
    loading = input.trim().length >= 2;
    notifyListeners();
    if (!loading) return;
    _timer = Timer(debounce, () async {
      try {
        final result = await search(input);
        if (_disposed || version != _version) return;
        cities = result;
      } catch (_) {
        if (_disposed || version != _version) return;
        hasError = true;
      } finally {
        if (!_disposed && version == _version) {
          loading = false;
          notifyListeners();
        }
      }
    });
  }

  void clear() {
    _timer?.cancel();
    _version++;
    cities = [];
    hasError = false;
    loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _version++;
    super.dispose();
  }
}
