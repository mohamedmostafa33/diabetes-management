import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Initialize timezone data
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Log the notification when it is actually received
        if (response.payload != null) {
          Map<String, dynamic> payload = jsonDecode(response.payload!);
          await logNotification(
            payload['id'],
            payload['title'],
            payload['body'],
            DateTime.parse(payload['scheduled_time']),
          );
        }
      },
    );

    // Request permission on Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      channelDescription: 'Channel for daily reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    // Convert DateTime to TZDateTime
    final tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    // Create a payload to pass to onDidReceiveNotificationResponse
    final payload = jsonEncode({
      'id': id,
      'title': title,
      'body': body,
      'scheduled_time': scheduledTime.toIso8601String(),
    });

    // Schedule the notification to repeat daily
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload, // Pass the payload
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // Log the notification in SharedPreferences
  static Future<void> logNotification(
      int id, String title, String body, DateTime scheduledTime) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> loggedNotifications =
        prefs.getStringList('logged_notifications') ?? [];

    // Extract reminder type from title (e.g., "تذكير: Medication" -> "Medication")
    String reminderType = title.replaceFirst('تذكير: ', '');

    Map<String, dynamic> notificationData = {
      'id': id,
      'title': title,
      'body': body,
      'reminder_type': reminderType,
      'scheduled_time': scheduledTime.toIso8601String(),
    };

    loggedNotifications.add(jsonEncode(notificationData));
    await prefs.setStringList('logged_notifications', loggedNotifications);
  }

  // Get logged notifications
  static Future<List<Map<String, dynamic>>> getLoggedNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> loggedNotifications =
        prefs.getStringList('logged_notifications') ?? [];
    return loggedNotifications
        .map((notification) => jsonDecode(notification) as Map<String, dynamic>)
        .toList();
  }

  // Clear logged notifications (optional)
  static Future<void> clearLoggedNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_notifications');
  }
}