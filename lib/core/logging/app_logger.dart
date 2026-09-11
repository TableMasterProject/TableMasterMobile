import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void debug(String message, [Object? error]) {
    if (!kDebugMode) return;
    debugPrint(error == null ? message : "$message (${error.runtimeType})");
  }

  /// Journalise une anomalie, y compris en build de production.
  ///
  /// Contrairement à [debug], ces traces restent visibles en release (logcat /
  /// console Xcode) : indispensable pour diagnostiquer des incidents qui ne se
  /// reproduisent que sur le terrain, comme les coupures du temps réel.
  static void error(String message, [Object? error]) {
    debugPrint(error == null ? message : "$message (${error.runtimeType})");
  }
}
