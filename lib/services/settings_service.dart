import 'package:flutter/material.dart';
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
  static const String unlockTier2Key = 'unlock_tier_2';
  static const String unlockTier3Key = 'unlock_tier_3';
  static const String unlockIntensityKey = 'unlock_intensity';
  static const String unlockBodyMapKey = 'unlock_body_map';
  static const String unlockTriggerPromptsKey = 'unlock_trigger_prompts';
  
  static const String remindersKey = 'reminders';
  static const String bodyTypeKey = 'body_type';
  static const String bodyMapIntroShownKey = 'body_map_intro_shown';
  static const String showJournalKey = 'show_journal_feature';
  static const String customColorsKey = 'custom_colors';
  static const String themeModeKey = 'theme_mode';
  static const String firstDayOfWeekKey = 'first_day_of_week';
  static const String dateFormatKey = 'date_format';
  static const String onboardingShownKey = 'onboarding_shown';
  static const String firstEntryHintShownKey = 'first_entry_hint_shown';
  static const String tier2IntroShownKey = 'tier_2_intro_shown';
  static const String tier3IntroShownKey = 'tier_3_intro_shown';
  static const String intensityIntroShownKey = 'intensity_intro_shown';
  static const String triggerIntroShownKey = 'trigger_intro_shown';
  static const String entryTapHintShownKey = 'entry_tap_hint_shown';
  static const String revisionTypesHintShownKey = 'revision_types_hint_shown';
  static const String timelineHintShownKey = 'timeline_hint_shown';
  static const String journalNudgeShownKey = 'journal_nudge_shown';
  static const String journalHighlightPendingKey = 'journal_highlight_pending';
  static const String journalIntroShownKey = 'journal_intro_shown';
  
  static const String remindersIntroShownKey = 'reminders_intro_shown';
  static const String colorsIntroShownKey = 'colors_intro_shown';
  static const String dataIntroShownKey = 'data_intro_shown';

  static Future<void> init() async {
    await Hive.openBox(settingsBoxName);
  }

  // --- Onboarding & Tutorials ---

  static bool isOnboardingShown() {
    final box = Hive.box(settingsBoxName);
    return box.get(onboardingShownKey, defaultValue: false);
  }

  static Future<void> setOnboardingShown(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(onboardingShownKey, value);
  }

  static bool isFirstEntryHintShown() {
    final box = Hive.box(settingsBoxName);
    return box.get(firstEntryHintShownKey, defaultValue: false);
  }

  static Future<void> setFirstEntryHintShown(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(firstEntryHintShownKey, value);
  }

  static bool isTier2IntroShown() {
    final box = Hive.box(settingsBoxName);
    return box.get(tier2IntroShownKey, defaultValue: false);
  }

  static Future<void> setTier2IntroShown(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(tier2IntroShownKey, value);
  }

  static bool isTier3IntroShown() {
    final box = Hive.box(settingsBoxName);
    return box.get(tier3IntroShownKey, defaultValue: false);
  }

  static Future<void> setTier3IntroShown(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(tier3IntroShownKey, value);
  }

  static bool isIntensityIntroShown() {
    final box = Hive.box(settingsBoxName);
    return box.get(intensityIntroShownKey, defaultValue: false);
  }

  static Future<void> setIntensityIntroShown(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(intensityIntroShownKey, value);
  }

  static bool isTriggerIntroShown() {
    final box = Hive.box(settingsBoxName);
    return box.get(triggerIntroShownKey, defaultValue: false);
  }

  static Future<void> setTriggerIntroShown(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(triggerIntroShownKey, value);
  }

  static bool isEntryTapHintShown() {
    final box = Hive.box(settingsBoxName);
    return box.get(entryTapHintShownKey, defaultValue: false);
  }

  static Future<void> setEntryTapHintShown(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(entryTapHintShownKey, value);
  }

  static bool isRevisionTypesHintShown() {
    final box = Hive.box(settingsBoxName);
    return box.get(revisionTypesHintShownKey, defaultValue: false);
  }

  static Future<void> setRevisionTypesHintShown(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(revisionTypesHintShownKey, value);
  }

  static bool isTimelineHintShown() {
    final box = Hive.box(settingsBoxName);
    return box.get(timelineHintShownKey, defaultValue: false);
  }

  static Future<void> setTimelineHintShown(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(timelineHintShownKey, value);
  }

  static bool isJournalNudgeShown() {
    final box = Hive.box(settingsBoxName);
    return box.get(journalNudgeShownKey, defaultValue: false);
  }

  static Future<void> setJournalNudgeShown(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(journalNudgeShownKey, value);
  }

  static bool isJournalHighlightPending() {
    final box = Hive.box(settingsBoxName);
    return box.get(journalHighlightPendingKey, defaultValue: false);
  }

  static Future<void> setJournalHighlightPending(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(journalHighlightPendingKey, value);
  }

  static bool isJournalIntroShown() {
    final box = Hive.box(settingsBoxName);
    return box.get(journalIntroShownKey, defaultValue: false);
  }

  static Future<void> setJournalIntroShown(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(journalIntroShownKey, value);
  }

  static bool isRemindersIntroShown() {
    final box = Hive.box(settingsBoxName);
    return box.get(remindersIntroShownKey, defaultValue: false);
  }

  static Future<void> setRemindersIntroShown(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(remindersIntroShownKey, value);
  }

  static bool isColorsIntroShown() {
    final box = Hive.box(settingsBoxName);
    return box.get(colorsIntroShownKey, defaultValue: false);
  }

  static Future<void> setColorsIntroShown(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(colorsIntroShownKey, value);
  }

  static bool isDataIntroShown() {
    final box = Hive.box(settingsBoxName);
    return box.get(dataIntroShownKey, defaultValue: false);
  }

  static Future<void> setDataIntroShown(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(dataIntroShownKey, value);
  }

  // --- Theme ---

  static ThemeMode getThemeMode() {
    final box = Hive.box(settingsBoxName);
    final String modeName = box.get(themeModeKey, defaultValue: ThemeMode.system.name);
    return ThemeMode.values.byName(modeName);
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    final box = Hive.box(settingsBoxName);
    await box.put(themeModeKey, mode.name);
  }

  // --- Localization & Preferences ---

  static int getFirstDayOfWeek() {
    final box = Hive.box(settingsBoxName);
    return box.get(firstDayOfWeekKey, defaultValue: 1);
  }

  static Future<void> setFirstDayOfWeek(int value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(firstDayOfWeekKey, value);
  }

  static String getDateFormat() {
    final box = Hive.box(settingsBoxName);
    return box.get(dateFormatKey, defaultValue: 'EEEE, MMMM d');
  }

  static Future<void> setDateFormat(String format) async {
    final box = Hive.box(settingsBoxName);
    await box.put(dateFormatKey, format);
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

  static bool isTier2Unlocked() {
    if (shouldSkipUnlocking()) return true;
    final box = Hive.box(settingsBoxName);
    return box.get(unlockTier2Key, defaultValue: false);
  }

  static Future<void> setTier2Unlocked(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(unlockTier2Key, value);
  }

  static bool isTier3Unlocked() {
    if (shouldSkipUnlocking()) return true;
    final box = Hive.box(settingsBoxName);
    return box.get(unlockTier3Key, defaultValue: false);
  }

  static Future<void> setTier3Unlocked(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(unlockTier3Key, value);
  }

  static bool isIntensityUnlocked() {
    if (shouldSkipUnlocking()) return true;
    final box = Hive.box(settingsBoxName);
    return box.get(unlockIntensityKey, defaultValue: false);
  }

  static Future<void> setIntensityUnlocked(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(unlockIntensityKey, value);
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
