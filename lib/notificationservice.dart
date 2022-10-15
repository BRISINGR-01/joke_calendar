import 'dart:convert';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> initNotification() async {
    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('drawable/launcher_icon');

    // ios initialization
    const IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);
    // the initialization settings are initialized after they are setted
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(
      int id, String title, String body, String time, String? imagePath) async {
    AndroidBitmap<Object>? androidBitmap;
    if (imagePath != null) {
      File image = File(imagePath);
      androidBitmap = ByteArrayAndroidBitmap.fromBase64String(
          base64.encode(image.readAsBytesSync()));
    }
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.parse(
          tz.local, time), //schedule the notification to show after 2 seconds.

      NotificationDetails(
        // Android details
        android: AndroidNotificationDetails(
          'main_channel',
          'Main Channel',
          channelDescription: "ashwin",
          largeIcon: (androidBitmap != null) ? androidBitmap : null,
          priority: Priority.max,
        ),
        // iOS details
        iOS: const IOSNotificationDetails(
          sound: 'default.wav',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      // Type of time interpretation
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle:
          true, // To show notification even when the app is closed
    );
    try {} catch (_) {
      // in case the icon is too large
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.parse(tz.local,
            time), //schedule the notification to show after 2 seconds.

        const NotificationDetails(
          // Android details
          android: AndroidNotificationDetails(
            'main_channel',
            'Main Channel',
            channelDescription: "ashwin",
            priority: Priority.max,
          ),
          // iOS details
          iOS: IOSNotificationDetails(
            sound: 'default.wav',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        // Type of time interpretation
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle:
            true, // To show notification even when the app is closed
      );
    }
  }

  cancel(int id) {
    flutterLocalNotificationsPlugin.cancel(id);
  }
}
