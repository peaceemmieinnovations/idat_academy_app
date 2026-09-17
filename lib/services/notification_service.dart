import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../screens/student/student_assignments_screen.dart';
import '../screens/student/student_certificates_screen.dart';
import '../screens/student/student_courses_screen.dart';
import '../screens/student/student_notifications_screen.dart';
import '../screens/student/student_results_screen.dart';
import '../screens/student/gamification_hub_screen.dart';
import '../screens/tutor/tutor_assignments_screen.dart';
import '../screens/tutor/tutor_screens.dart';
import 'api_service.dart';

/// Receives Firebase alerts and presents a visible, audible Android notification
/// while the app is open. Delivery is performed by the protected server API.
/// Also surfaces local in-app activity (submissions, uploads, quiz results, …)
/// as a tappable notification that deep-links to the relevant screen.
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
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'idat_academy_alerts',
      'IDAT Academy alerts',
      channelDescription: 'Assignments, results, announcements and account alerts.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    ),
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
      _details,
      payload: jsonEncode(message.data),
    );
  }

  /// Shows a tappable local notification for an action the user just performed
  /// in the app. Tapping it deep-links to the screen named by [screen]
  /// (see [_openNotification] for the recognised values).
  static Future<void> showActivityNotification({
    required String title,
    required String body,
    String screen = 'notification',
  }) async {
    await _local.show(
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title,
      body,
      _details,
      payload: jsonEncode({'type': 'activity', 'screen': screen}),
    );
  }

  static Future<void> _openNotification(String? payload) async {
    Map<String, dynamic> data = const {};
    if (payload != null) {
      try {
        data = jsonDecode(payload) as Map<String, dynamic>;
      } catch (_) {
        return;
      }
    }
    final screen = (data['screen']?.toString() ?? '').toLowerCase();
    final type = (data['type']?.toString() ?? '').toLowerCase();
    final role = await ApiService.getRole();
    final isTutor = role == 'tutor' || role == 'staff';

    Widget? destination;
    switch (screen.isEmpty ? type : screen) {
      case 'assignment':
      case 'submission':
        destination = isTutor
            ? const TutorAssignmentsScreen()
            : const StudentAssignmentsScreen();
      case 'result':
      case 'results':
      case 'grade':
        destination = isTutor
            ? const TutorAssignmentsScreen()
            : const StudentResultsScreen();
      case 'certificate':
      case 'certificates':
        destination = const StudentCertificatesScreen();
      case 'gamification':
      case 'quiz':
      case 'crossmatch':
      case 'badge':
      case 'level_up':
        destination = const GamificationHubScreen();
      case 'lesson':
      case 'lessons':
        destination = isTutor
            ? const TutorLessonsScreen()
            : const StudentCoursesScreen();
      case 'course':
      case 'courses':
      case 'enrollment':
        destination = const StudentCoursesScreen();
      case 'announcement':
      case 'notification':
      case 'notifications':
        destination = null;
      default:
        if (screen.isEmpty && type.isEmpty) return;
        destination = null;
    }

    final target = destination ?? const StudentNotificationsScreen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context == null) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => target));
    });
  }
}
