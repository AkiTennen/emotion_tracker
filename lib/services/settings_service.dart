import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'reminder_service.dart';

class SettingsService {
  static const String settingsBoxName = 'settings';
  static const String skipUnlockingKey = 'skip_unlocking';
  static const String remindersKey = 'reminders';

  static Future<void> init() async {
    await Hive.openBox(settingsBoxName);
  }

  static bool shouldSkipUnlocking() {
    final box = Hive.box(settingsBoxName);
    return box.get(skipUnlockingKey, defaultValue: false);
  }

  static Future<void> setSkipUnlocking(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(skipUnlockingKey, value);
  }

  // --- Reminders ---

  static List<Reminder> getReminders() {
    final box = Hive.box(settingsBoxName);
    final List<dynamic>? rawList = box.get(remindersKey);
    if (rawList == null) return [];
    return rawList.map((map) => Reminder.fromMap(map)).toList();
  }

  static Future<void> saveReminders(List<Reminder> reminders) async {
    final box = Hive.box(settingsBoxName);
    final rawList = reminders.map((r) => r.toMap()).toList();
    await box.put(remindersKey, rawList);
    
    // Reschedule all in the service
    for (var r in reminders) {
      await ReminderService.scheduleReminder(r);
    }
  }
}
