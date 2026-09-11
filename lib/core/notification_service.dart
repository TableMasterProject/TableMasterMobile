import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';
import 'logging/app_logger.dart';
import 'notification_deduplicator.dart';

const String _notificationChannelId = 'table_master_channel';
const String _notificationChannelName = 'Table Master';
const String _notificationChannelDescription = 'Notifications de Table Master';

final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Background message handler. Must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _initializeLocalNotifications();
  // Les messages avec bloc notification sont déjà affichés par Firebase en
  // arrière-plan. Les événements outbox sont des messages data-only.
  if (message.notification != null) return;
  await _showLocalNotification(message);
}

Future<void> _initializeLocalNotifications() async {
  if (kIsWeb) {
    return;
  }

  const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosInitializationSettings =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: androidInitializationSettings,
    iOS: iosInitializationSettings,
  );

  await _localNotificationsPlugin.initialize(settings: initializationSettings);

  if (defaultTargetPlatform == TargetPlatform.android) {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _notificationChannelId,
      _notificationChannelName,
      description: _notificationChannelDescription,
      importance: Importance.high,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }
}

Future<void> _showLocalNotification(RemoteMessage message) =>
    NotificationDeduplicator().showOnce(
      message.data['eventId']?.toString(),
      () => _displayLocalNotification(message),
    );

Future<void> _displayLocalNotification(RemoteMessage message) async {
  if (kIsWeb) {
    return;
  }

  final notification = message.notification;
  if (notification == null && message.data.isEmpty) {
    return;
  }

  final title =
      notification?.title ??
      message.data['title']?.toString() ??
      'Table Master';
  final body = notification?.body ?? message.data['body']?.toString() ?? '';
  final payload = jsonEncode(message.data);

  final NotificationDetails notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _notificationChannelId,
      _notificationChannelName,
      channelDescription: _notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Table Master',
    ),
    iOS: const DarwinNotificationDetails(),
  );

  await _localNotificationsPlugin.show(
    id: NotificationDeduplicator.notificationId(
      message.data['eventId']?.toString() ??
          message.messageId ??
          message.hashCode.toString(),
    ),
    title: title,
    body: body,
    notificationDetails: notificationDetails,
    payload: payload,
  );
}

class NotificationService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  NotificationService(this._apiClient, [FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  Future<void> init() async {
    await _initializeLocalNotifications();
    await _requestPermission();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
    await _handleInitialMessage();

    FirebaseMessaging.instance.onTokenRefresh.listen(
      _registerTokenIfUserLoggedIn,
    );

    final token = await _getMessagingToken();
    if (token != null) {
      await _registerTokenIfUserLoggedIn(token);
    }
  }

  Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    AppLogger.debug(
      'Notification authorization status: ${settings.authorizationStatus}',
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showLocalNotification(message);
  }

  Future<void> _handleOpenedMessage(RemoteMessage message) async {
    AppLogger.debug('Notification ouverte par l’utilisateur');
  }

  Future<void> _handleInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      AppLogger.debug('L’application a été ouverte depuis une notification');
    }
  }

  Future<void> registerTokenForCurrentUser() async {
    final token = await _getMessagingToken();
    if (token != null) {
      await _registerTokenIfUserLoggedIn(token);
    }
  }

  Future<String?> _getMessagingToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (error) {
      AppLogger.debug('Erreur récupération token FCM', error);
      return null;
    }
  }

  Future<void> _registerTokenIfUserLoggedIn(String token) async {
    final epoch = _apiClient.session.generation;
    final accessToken = await _apiClient.session.accessToken;
    if (accessToken == null || epoch != _apiClient.session.generation) return;
    final savedToken = await _storage.read(key: 'fcm_token');
    if (savedToken == token) return;
    try {
      await _apiClient.dio.post(
        '/DeviceToken',
        data: {'deviceToken': token, 'devicePlatform': _devicePlatform},
      );
      await _apiClient.session.storeDeviceToken(
        token,
        expectedGeneration: epoch,
      );
    } catch (error) {
      AppLogger.debug('Erreur enregistrement des notifications', error);
    }
  }

  Future<void> unregisterDeviceToken({
    String? deviceToken,
    String? accessToken,
  }) async {
    final token = deviceToken;
    if (token == null || accessToken == null) return;
    try {
      await _apiClient.dio.delete(
        '/DeviceToken',
        queryParameters: {'deviceToken': token},
        options: Options(
          extra: {ApiClient.skipSession: true},
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
    } catch (error) {
      AppLogger.debug('Erreur suppression des notifications', error);
    }
  }

  String get _devicePlatform {
    if (kIsWeb) {
      return 'web';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.linux => 'linux',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.fuchsia => 'unknown',
    };
  }
}
