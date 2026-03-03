import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

enum AlertType { quiet, vibrate, alarm }

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
    return Reminder(
      id: map['id'] as int,
      time: TimeOfDay(hour: map['hour'] as int, minute: map['minute'] as int),
      alertType: AlertType.values.byName(map['alertType'] as String),
      message: map['message'] as String? ?? 'How are you feeling right now?',
      isEnabled: map['isEnabled'] as bool,
    );
  }
}

class ReminderService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static final _audioPlayer = AudioPlayer();

  static Future<void> init() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // App will open automatically on tap due to platform configuration
      },
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
    final androidDetails = _getAndroidDetails(reminder.alertType);
    await _notifications.show(
      999,
      'Test: ${reminder.alertType.name.toUpperCase()}',
      reminder.message,
      NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> scheduleReminder(Reminder reminder) async {
    await _notifications.cancel(reminder.id);
    
    if (!reminder.isEnabled) return;

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      reminder.time.hour,
      reminder.time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final androidDetails = _getAndroidDetails(reminder.alertType);

    await _notifications.zonedSchedule(
      reminder.id,
      'Emotion Tracker',
      reminder.message,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static AndroidNotificationDetails _getAndroidDetails(AlertType type) {
    switch (type) {
      case AlertType.quiet:
        return const AndroidNotificationDetails(
          'reminders_quiet',
          'Quiet Reminders',
          channelDescription: 'Gentle nudges in the notification tray',
          importance: Importance.low,
          priority: Priority.low,
          showWhen: true,
        );
      case AlertType.vibrate:
        return AndroidNotificationDetails(
          'reminders_vibrate',
          'Vibrate Reminders',
          channelDescription: 'Notifications with haptic feedback',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        );
      case AlertType.alarm:
        return AndroidNotificationDetails(
          'reminders_alarm',
          'Alarm Reminders',
          channelDescription: 'High-priority alarms that ring even on silent',
          importance: Importance.max,
          priority: Priority.max,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          sound: const RawResourceAndroidNotificationSound('alarm_sound'),
          playSound: true,
          fullScreenIntent: true,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
        );
    }
  }

  static Future<void> previewAlarmSound() async {
    await _audioPlayer.setVolume(1.0);
    await _audioPlayer.play(AssetSource('audio/alarm_sound.mp3'));
  }

  static Future<void> stopPreview() async {
    await _audioPlayer.stop();
  }
}
