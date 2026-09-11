import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/app_config.dart';
import 'core/app_constant.dart';
import 'core/deep_link_service.dart';
import 'core/injection.dart';
import 'core/notification_service.dart';
import 'core/signalr_lifecycle_observer.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';

void main() async {
  Future<void> appRunner() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (AppConfig.isProd && Uri.tryParse(AppConfig.apiUrl)?.scheme != 'https') {
      throw StateError("L'API de production doit utiliser HTTPS/WSS.");
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await initializeDateFormatting('fr_FR', null);

    setupDependencies();
    getIt<SignalRLifecycleObserver>().register();
    await getIt<DeepLinkService>().init();
    await _captureSentryStartupTestEvent();

    runApp(const MyApp());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeNotifications());
      unawaited(getIt<DeepLinkService>().navigatePendingLink());
    });
  }

  if (AppConfig.sentryDsn.isEmpty) {
    await appRunner();
    return;
  }

  await SentryFlutter.init((options) {
    options.dsn = AppConfig.sentryDsn;
    options.environment = AppConfig.isProd ? 'production' : 'development';
    options.release = AppConfig.sentryRelease;
    options.tracesSampleRate = AppConfig.sentryTracesSampleRate;
    options.sendDefaultPii = false;
    options.beforeSend = (event, _) {
      final request = event.request;
      if (request != null) {
        request.url = _redactAccessToken(request.url);
        request.queryString = _redactAccessToken(request.queryString);
      }
      return event;
    };
    options.beforeBreadcrumb = (breadcrumb, _) {
      if (breadcrumb == null) return null;
      breadcrumb.message = _redactAccessToken(breadcrumb.message);
      final data = breadcrumb.data;
      if (data != null) {
        breadcrumb.data = data.map(
          (key, value) => MapEntry(
            key,
            value is String ? _redactAccessToken(value) : value,
          ),
        );
      }
      return breadcrumb;
    };
  }, appRunner: appRunner);
}

String? _redactAccessToken(String? value) => value?.replaceAll(
  RegExp(r'([?&]|^)access_token=[^&#\s]*', caseSensitive: false),
  r'$1access_token=[Filtered]',
);

Future<void> _initializeNotifications() async {
  try {
    await getIt<NotificationService>().init();
  } catch (error, stackTrace) {
    debugPrint('Erreur initialisation notifications: $error');
    await Sentry.captureException(error, stackTrace: stackTrace);
  }
}

Future<void> _captureSentryStartupTestEvent() async {
  var shouldCapture = false;

  assert(() {
    shouldCapture = AppConfig.sentryEnableStartupTestEvent;
    return true;
  }());

  if (shouldCapture && AppConfig.sentryDsn.isNotEmpty) {
    await Sentry.captureMessage('Hello Sentry from TableMasterMobile');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      scrollBehavior: const _AppScrollBehavior(),
      navigatorKey: navigatorKey,
      navigatorObservers:
          AppConfig.sentryDsn.isEmpty
              ? const <NavigatorObserver>[]
              : [SentryNavigatorObserver()],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR')],
      locale: const Locale('fr', 'FR'),

      home: const SplashScreen(),
    );
  }
}

/// Active la prise en charge des gestes molette + drag souris (utile sur web/desktop)
/// tout en gardant les gestes tactiles natifs.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
