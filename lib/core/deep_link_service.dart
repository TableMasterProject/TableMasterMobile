import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:table_master_mobile/core/app_constant.dart';
import 'package:table_master_mobile/core/logging/app_logger.dart';
import 'package:table_master_mobile/features/auth/presentation/login/login_screen.dart';
import 'package:table_master_mobile/features/auth/presentation/reset_password_screen.dart';
import 'package:table_master_mobile/features/reservation/presentation/reservation_deep_link_page.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  StreamSubscription<Uri>? _subscription;
  Uri? _pendingUri;

  Future<void> init() async {
    try {
      _pendingUri = await _appLinks.getInitialLink();
    } catch (error) {
      AppLogger.debug("Erreur lecture du lien initial", error);
    }

    _pendingUri ??= _currentBrowserRoute();

    _subscription ??= _appLinks.uriLinkStream.listen(
      (uri) {
        _pendingUri = uri;
        _scheduleNavigation();
      },
      onError: (Object error) {
        AppLogger.debug("Erreur reception deep link", error);
      },
    );
  }

  Future<bool> navigatePendingLink() async {
    final uri = _pendingUri;
    final navigator = navigatorKey.currentState;
    if (uri == null || navigator == null) {
      return false;
    }

    final route = _parseRoute(uri);
    if (route == null) {
      _pendingUri = null;
      return false;
    }

    if (route is _ResetPasswordRoute) {
      _pendingUri = null;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(token: route.token),
        ),
        (route) => false,
      );
      return true;
    }

    if (route is _ReservationRoute) {
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return true;
      }

      _pendingUri = null;
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ReservationDeepLinkPage(reservationId: route.id),
        ),
      );
      return true;
    }

    return false;
  }

  void _scheduleNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(navigatePendingLink());
    });
  }

  _DeepLinkRoute? _parseRoute(Uri uri) {
    final segments = _normalizedSegments(uri);
    if (segments.isEmpty) {
      return null;
    }

    if (segments.first == 'reset-password') {
      final token = uri.queryParameters['token'];
      if (token == null || token.trim().isEmpty) {
        return null;
      }
      return _ResetPasswordRoute(token.trim());
    }

    if (segments.first == 'reservations' && segments.length >= 2) {
      final id = int.tryParse(segments[1]);
      if (id == null) {
        return null;
      }
      return _ReservationRoute(id);
    }

    return null;
  }

  Uri? _currentBrowserRoute() {
    final uri = Uri.base;
    return _parseRoute(uri) == null ? null : uri;
  }

  List<String> _normalizedSegments(Uri uri) {
    final segments = <String>[];
    if (uri.scheme == 'tablemaster' && uri.host.isNotEmpty) {
      segments.add(uri.host);
    }
    segments.addAll(uri.pathSegments);
    return segments.where((segment) => segment.trim().isNotEmpty).toList();
  }
}

sealed class _DeepLinkRoute {
  const _DeepLinkRoute();
}

final class _ResetPasswordRoute extends _DeepLinkRoute {
  final String token;

  const _ResetPasswordRoute(this.token);
}

final class _ReservationRoute extends _DeepLinkRoute {
  final int id;

  const _ReservationRoute(this.id);
}
