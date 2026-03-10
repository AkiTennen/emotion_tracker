import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'reminder_service.dart';

enum BodyType {
  neutral,
  female,
  male,
}

class SettingsService {
  static const String settingsBoxName = 'settings';
  
  // Keys
  static const String skipUnlockingKey = 'skip_unlocking';
  static const String unlockEmotionsKey = 'unlock_emotions';
  static const String unlockBodyMapKey = 'unlock_body_map';
  static const String unlockTriggerPromptsKey = 'unlock_trigger_prompts';
  
  static const String remindersKey = 'reminders';
  static const String bodyTypeKey = 'body_type';
  static const String bodyMapIntroShownKey = 'body_map_intro_shown';
  static const String showJournalKey = 'show_journal_feature';
  static const String customColorsKey = 'custom_colors';

  static Future<void> init() async {
    await Hive.openBox(settingsBoxName);
  }

  // --- Progression ---

  static bool shouldSkipUnlocking() {
    final box = Hive.box(settingsBoxName);
    return box.get(skipUnlockingKey, defaultValue: false);
  }

  static Future<void> setSkipUnlocking(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(skipUnlockingKey, value);
  }

  static bool isEmotionsUnlocked() {
    if (shouldSkipUnlocking()) return true;
    final box = Hive.box(settingsBoxName);
    return box.get(unlockEmotionsKey, defaultValue: false);
  }

  static Future<void> setEmotionsUnlocked(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(unlockEmotionsKey, value);
  }

  static bool isBodyMapUnlocked() {
    if (shouldSkipUnlocking()) return true;
    final box = Hive.box(settingsBoxName);
    return box.get(unlockBodyMapKey, defaultValue: false);
  }

  static Future<void> setBodyMapUnlocked(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(unlockBodyMapKey, value);
  }

  static bool isTriggerPromptsUnlocked() {
    if (shouldSkipUnlocking()) return true;
    final box = Hive.box(settingsBoxName);
    return box.get(unlockTriggerPromptsKey, defaultValue: false);
  }

  static Future<void> setTriggerPromptsUnlocked(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(unlockTriggerPromptsKey, value);
  }

  // --- General ---

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

  static bool isJournalEnabled() {
    final box = Hive.box(settingsBoxName);
    return box.get(showJournalKey, defaultValue: false);
  }

  static Future<void> setJournalEnabled(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(showJournalKey, value);
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

  // --- Custom Colors ---

  static Map<String, int> getCustomColors() {
    final box = Hive.box(settingsBoxName);
    final Map<dynamic, dynamic>? rawMap = box.get(customColorsKey);
    if (rawMap == null) return {};
    return Map<String, int>.from(rawMap);
  }

  static Future<void> setCustomColor(String emotion, int colorValue) async {
    final box = Hive.box(settingsBoxName);
    final Map<String, int> current = getCustomColors();
    current[emotion] = colorValue;
    await box.put(customColorsKey, current);
  }

  static Future<void> resetCustomColors() async {
    final box = Hive.box(settingsBoxName);
    await box.delete(customColorsKey);
  }
}
