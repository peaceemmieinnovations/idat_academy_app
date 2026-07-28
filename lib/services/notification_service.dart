import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../screens/student/student_notifications_screen.dart';
import 'api_service.dart';

/// Receives Firebase alerts and presents a visible, audible Android notification
/// while the app is open. Delivery is performed by the protected server API.
class NotificationService {
  NotificationService._();

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final _messaging = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();
  static const _channel = AndroidNotificationChannel(
    'idat_academy_alerts',
    'IDAT Academy alerts',
    description: 'Assignments, results, announcements and account alerts.',
    importance: Importance.high,
    playSound: true,
  );

  static Future<void> initialize() async {
    await Firebase.initializeApp();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (response) =>
          _openNotification(response.payload),
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((message) =>
        _openNotification(jsonEncode(message.data)));
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _openNotification(jsonEncode(initialMessage.data));
  }

  static Future<void> registerCurrentDevice() async {
    final token = await _messaging.getToken();
    if (token != null) await ApiService.registerDeviceToken(token);
    _messaging.onTokenRefresh.listen(ApiService.registerDeviceToken);
  }

  static Future<void> unregisterCurrentDevice() async {
    final token = await _messaging.getToken();
    if (token != null) await ApiService.unregisterDeviceToken(token);
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString() ?? 'IDAT Academy';
    final body = notification?.body ?? message.data['body']?.toString() ?? 'You have a new update.';
    await _local.show(
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'idat_academy_alerts',
          'IDAT Academy alerts',
          channelDescription: 'Assignments, results, announcements and account alerts.',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static void _openNotification(String? payload) {
    // All mobile alerts lead to the notification centre. The related item id
    // remains in the payload for the API/screen to resolve when routes are added.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context == null) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const StudentNotificationsScreen(),
      ));
    });
  }
}
