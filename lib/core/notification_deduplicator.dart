import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Reçus durables partagés avec l'isolate Firebase d'arrière-plan.
///
/// Le reçu est écrit APRÈS l'affichage pour permettre une nouvelle tentative si
/// le processus s'arrête avant l'affichage. Dans la fenêtre affichage/écriture,
/// l'identifiant OS déterministe remplace la notification déjà présentée.
class NotificationDeduplicator {
  NotificationDeduplicator({
    FlutterSecureStorage? storage,
    DateTime Function()? clock,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _clock = clock ?? DateTime.now;
  final FlutterSecureStorage _storage;
  final DateTime Function() _clock;
  static final Map<String, Future<void>> _pending = {};
  static const _prefix = 'notification_event_';
  static const _retention = Duration(days: 7);

  Future<void> showOnce(String? eventId, Future<void> Function() show) {
    if (eventId == null || eventId.isEmpty || eventId.length > 256) {
      return show();
    }
    final pending = _pending[eventId];
    if (pending != null) return pending;
    final future = _show(eventId, show);
    final tracked = future.whenComplete(() {
      _pending.remove(eventId);
    });
    _pending[eventId] = tracked;
    return tracked;
  }

  Future<void> _show(String eventId, Future<void> Function() show) async {
    final key = '$_prefix${base64Url.encode(utf8.encode(eventId))}';
    final now = _clock().toUtc();
    final receipt = await _storage.read(key: key);
    final displayed = receipt == null ? null : DateTime.tryParse(receipt);
    if (displayed != null && now.difference(displayed) < _retention) return;
    await show();
    await _storage.write(key: key, value: now.toIso8601String());
    // Ne conserver que les identifiants récents, sans jamais toucher les clés
    // de session ou les données personnelles éventuellement présentes.
    final values = await _storage.readAll();
    for (final entry in values.entries) {
      if (!entry.key.startsWith(_prefix)) continue;
      final date = DateTime.tryParse(entry.value);
      if (date != null && now.difference(date) >= _retention) {
        await _storage.delete(key: entry.key);
      }
    }
  }

  static int notificationId(String eventId) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(eventId)) {
      hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }
}
