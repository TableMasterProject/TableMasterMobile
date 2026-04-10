import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';

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
  await _showLocalNotification(message);
}

Future<void> _initializeLocalNotifications() async {
  const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosInitializationSettings =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: androidInitializationSettings,
    iOS: iosInitializationSettings,
  );

  await _localNotificationsPlugin.initialize(settings: initializationSettings);

  if (Platform.isAndroid) {
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

Future<void> _showLocalNotification(RemoteMessage message) async {
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
    id: message.hashCode,
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

    final token = await FirebaseMessaging.instance.getToken();
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
    print('Notification authorization status: ${settings.authorizationStatus}');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showLocalNotification(message);
  }

  Future<void> _handleOpenedMessage(RemoteMessage message) async {
    print('Notification ouverte par l’utilisateur: ${message.data}');
  }

  Future<void> _handleInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      print(
        'L’application a été ouverte depuis une notification terminée: ${message.data}',
      );
    }
  }

  Future<void> registerTokenForCurrentUser() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _registerTokenIfUserLoggedIn(token);
    }
  }

  Future<void> _registerTokenIfUserLoggedIn(String token) async {
    final userId = await _storage.read(key: 'user_id');
    final accessToken = await _storage.read(key: 'access_token');

    if (userId == null || accessToken == null) {
      await _storage.write(key: 'fcm_token', value: token);
      return;
    }

    final savedToken = await _storage.read(key: 'fcm_token');
    if (savedToken == token) {
      return;
    }

    await _storage.write(key: 'fcm_token', value: token);
    await _registerDeviceToken(token);
  }

  Future<void> _registerDeviceToken(String token) async {
    try {
      final platform =
          Platform.isAndroid
              ? 'android'
              : Platform.isIOS
              ? 'ios'
              : 'unknown';

      await _apiClient.dio.post(
        '/DeviceToken',
        data: {'deviceToken': token, 'devicePlatform': platform},
      );
    } on DioError catch (error) {
      print(
        'Erreur enregistrement token FCM: ${error.response?.data ?? error.message}',
      );
    } catch (error) {
      print('Erreur enregistrement token FCM: $error');
    }
  }

  Future<void> unregisterDeviceToken() async {
    final token = await _storage.read(key: 'fcm_token');
    if (token == null) return;

    try {
      await _apiClient.dio.delete('/DeviceToken', queryParameters: {'deviceToken': token});
      await _storage.delete(key: 'fcm_token');
    } catch (error) {
      print('Erreur suppression token FCM: $error');
    }
  }
}
