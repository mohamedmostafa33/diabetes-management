import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io' show Platform; // أضفنا هذا للتحقق من إصدار Android

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
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
          if (response.payload != null) {
            try {
              Map<String, dynamic> payload = jsonDecode(response.payload!);
              await logNotification(
                payload['id'],
                payload['title'],
                payload['body'],
                DateTime.parse(payload['scheduled_time']),
                reminderType: payload['reminder_type'],
              );
            } catch (e) {
              print('Error parsing notification payload: $e');
            }
          }
        },
      );

      // Create notification channel (important for Android 8.0+)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'daily_reminder_channel',
        'التذكيرات اليومية',
        description: 'قناة لإشعارات التذكيرات اليومية',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Request permissions (for Android 13+)
      if (Platform.isAndroid) {
        // تحقق من إصدار Android
        if (int.parse(Platform.version.split('.')[0]) >= 33) {
          await requestNotificationPermissions();
        }
      }
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  static Future<bool> requestNotificationPermissions() async {
    final result = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return result ?? false;
  }

  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String reminderType,
  }) async {
    try {
      final location = tz.getLocation('Africa/Cairo');
      final now = tz.TZDateTime.now(location);

      // Convert scheduled time to local timezone
      var scheduledDate = tz.TZDateTime.from(
        scheduledTime,
        location,
      );

      // If the scheduled time is in the past, schedule for next day
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'daily_reminder_channel',
        'التذكيرات اليومية',
        channelDescription: 'قناة لإشعارات التذكيرات اليومية',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('notification'),
        colorized: true,
        color: Color(0xFF2196F3),
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      // Create payload with all necessary data
      final payload = jsonEncode({
        'id': id,
        'title': title,
        'body': body,
        'reminder_type': reminderType,
        'scheduled_time': scheduledTime.toIso8601String(),
      });

      // Schedule the notification
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        platformDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );

      print('تم جدولة الإشعار بنجاح: $title في $scheduledDate');
    } catch (e) {
      print('فشل جدولة الإشعار: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      print('تم إلغاء الإشعار رقم $id');
    } catch (e) {
      print('فشل إلغاء الإشعار: $e');
    }
  }

  static Future<void> logNotification(
    int id,
    String title,
    String body,
    DateTime scheduledTime, {
    required String reminderType,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> loggedNotifications =
          prefs.getStringList('logged_notifications') ?? [];

      Map<String, dynamic> notificationData = {
        'id': id,
        'title': title,
        'body': body,
        'reminder_type': reminderType,
        'scheduled_time': scheduledTime.toIso8601String(),
        'received_time': DateTime.now().toIso8601String(),
      };

      loggedNotifications.add(jsonEncode(notificationData));
      await prefs.setStringList('logged_notifications', loggedNotifications);
    } catch (e) {
      print('فشل تسجيل الإشعار: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getLoggedNotifications() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> loggedNotifications =
          prefs.getStringList('logged_notifications') ?? [];
      return loggedNotifications
          .map((notification) => jsonDecode(notification) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('فشل جلب الإشعارات المسجلة: $e');
      return [];
    }
  }

  static Future<void> clearLoggedNotifications() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('logged_notifications');
    } catch (e) {
      print('فشل مسح الإشعارات المسجلة: $e');
    }
  }
}