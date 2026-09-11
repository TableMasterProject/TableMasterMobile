import 'dart:async';

/// Regroupe les rafales temps réel ; une invalidation pendant un chargement
/// provoque un dernier chargement lorsque celui-ci se termine.
class RefreshScheduler {
  RefreshScheduler(this._refresh);
  final Future<void> Function() _refresh;
  Timer? _timer;
  bool _running = false;
  bool _pending = false;
  bool _disposed = false;

  void schedule() {
    if (_disposed) return;
    _pending = true;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 150), _run);
  }

  Future<void> _run() async {
    if (_disposed || _running || !_pending) return;
    _running = true;
    _pending = false;
    try {
      await _refresh();
    } finally {
      _running = false;
      if (_pending && !_disposed) schedule();
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
  }
}
