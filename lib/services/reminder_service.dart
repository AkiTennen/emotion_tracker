import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

enum AlertType { quiet, alarm }

class Reminder {
  final int id;
  final TimeOfDay time;
  final AlertType alertType;
  final String message;
  final bool isEnabled;

  Reminder({
    required this.id,
    required this.time,
    required this.alertType,
    required this.message,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'alertType': alertType.name,
      'message': message,
      'isEnabled': isEnabled,
    };
  }

  factory Reminder.fromMap(Map<dynamic, dynamic> map) {
    String alertTypeName = map['alertType'] as String? ?? 'quiet';
    if (alertTypeName == 'vibrate') {
      alertTypeName = 'quiet';
    }
    try {
      AlertType.values.byName(alertTypeName);
    } catch (_) {
      alertTypeName = 'quiet';
    }

    return Reminder(
      id: map['id'] as int,
      time: TimeOfDay(hour: map['hour'] as int, minute: map['minute'] as int),
      alertType: AlertType.values.byName(alertTypeName),
      message: map['message'] as String? ?? 'How are you feeling right now?',
      isEnabled: map['isEnabled'] as bool? ?? true,
    );
  }
}

class ReminderService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static final _audioPlayer = AudioPlayer();

  static Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint("Timezone error: $e");
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {},
    );
  }

  static Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }
  }

  static Future<void> sendImmediateTest(Reminder reminder) async {
    try {
      final androidDetails = _getAndroidDetails(reminder.alertType);
      await _notifications.show(
        999,
        'Test Notification',
        reminder.message,
        NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      debugPrint("Test failed: $e");
    }
  }

  static Future<void> scheduleReminder(Reminder reminder) async {
    await _notifications.cancel(reminder.id);
    if (!reminder.isEnabled) return;

    final tz.TZDateTime scheduledDate = _nextInstanceOfTime(reminder.time);

    final androidDetails = _getAndroidDetails(reminder.alertType);

    await _notifications.zonedSchedule(
      reminder.id,
      'Sentic',
      reminder.message,
      scheduledDate,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
  }

  static tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static AndroidNotificationDetails _getAndroidDetails(AlertType type) {
    const String channelId = 'sentic_reminders_final_alarm';
    const String channelName = 'Sentic Reminders';

    switch (type) {
      case AlertType.quiet:
        return const AndroidNotificationDetails(
          channelId, channelName,
          importance: Importance.low,
          priority: Priority.low,
        );
      case AlertType.alarm:
        return const AndroidNotificationDetails(
          channelId, channelName,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('alarm_sound'),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          category: AndroidNotificationCategory.alarm,
          enableVibration: true,
          fullScreenIntent: true,
        );
    }
  }

  static Future<void> previewAlarmSound() async {
    try {
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('audio/alarm_sound.mp3'));
    } catch (e) {
      debugPrint("Preview failed: $e");
    }
  }

  static Future<void> stopPreview() async {
    await _audioPlayer.stop();
  }
}
