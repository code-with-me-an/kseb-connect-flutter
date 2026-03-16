import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Normal notification channel (no sound)
  static const AndroidNotificationChannel normalChannel =
      AndroidNotificationChannel(
    'kseb_notifications',
    'KSEB Notifications',
    description: 'Normal announcements',
    importance: Importance.high,
    playSound: false,
  );

  // Alert notification channel (with alert sound)
  static const AndroidNotificationChannel alertChannel =
      AndroidNotificationChannel(
    'kseb_alert_notifications',
    'KSEB Alerts',
    description: 'Critical alerts',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('alert'),
  );

  static Future<void> initialize(void Function(String? payload) onTap) async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        onTap(response.payload);
      },
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Create BOTH channels
    await androidPlugin?.createNotificationChannel(normalChannel);
    await androidPlugin?.createNotificationChannel(alertChannel);
  }

  static Future<void> requestPermission() async {
    final status = await Permission.notification.status;

    if (status.isDenied || status.isRestricted) {
      await Permission.notification.request();
    }
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    bool isAlert = false,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      isAlert ? 'kseb_alert_notifications' : 'kseb_notifications',
      isAlert ? 'KSEB Alerts' : 'KSEB Notifications',
      channelDescription: 'Notifications for complaints and alerts',
      icon: '@drawable/kseb_notification_icon',

      importance: Importance.max,
      priority: Priority.max,

      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1200]),

      fullScreenIntent: isAlert,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }
}