import 'dart:async';

import 'package:flutter/widgets.dart';

import 'logging/app_logger.dart';
import 'signalr_service.dart';

/// Rétablit le temps réel au retour de l'application au premier plan.
///
/// En arrière-plan, le système suspend les timers Dart : le ping de maintien
/// (15 s) s'arrête, le serveur atteint son `ClientTimeoutInterval` et ferme la
/// connexion. Sans ce rattrapage, l'utilisateur retrouve une application qui
/// paraît connectée mais ne reçoit plus aucune mise à jour.
class SignalRLifecycleObserver with WidgetsBindingObserver {
  SignalRLifecycleObserver(this._signalRService);

  final SignalRService _signalRService;
  bool _registered = false;

  void register() {
    if (_registered) return;
    WidgetsBinding.instance.addObserver(this);
    _registered = true;
  }

  void unregister() {
    if (!_registered) return;
    WidgetsBinding.instance.removeObserver(this);
    _registered = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    AppLogger.debug(
      'SignalR: retour au premier plan, contrôle de la connexion',
    );
    unawaited(_signalRService.ensureConnected());
  }
}
