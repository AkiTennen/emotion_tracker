import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'reminder_service.dart';

enum BodyType {
  neutral,
  female,
  male,
}

class SettingsService {
  static const String settingsBoxName = 'settings';
  static const String skipUnlockingKey = 'skip_unlocking';
  static const String remindersKey = 'reminders';
  static const String bodyTypeKey = 'body_type';
  static const String bodyMapIntroShownKey = 'body_map_intro_shown';

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

  static BodyType getBodyType() {
    final box = Hive.box(settingsBoxName);
    final String typeName = box.get(bodyTypeKey, defaultValue: BodyType.neutral.name);
    return BodyType.values.byName(typeName);
  }

  static Future<void> setBodyType(BodyType type) async {
    final box = Hive.box(settingsBoxName);
    await box.put(bodyTypeKey, type.name);
  }

  static bool isBodyMapIntroShown() {
    final box = Hive.box(settingsBoxName);
    return box.get(bodyMapIntroShownKey, defaultValue: false);
  }

  static Future<void> setBodyMapIntroShown(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(bodyMapIntroShownKey, value);
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
