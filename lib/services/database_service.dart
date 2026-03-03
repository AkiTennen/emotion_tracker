import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../models/emotion_entry.dart';
import '../models/emotion_entry_revision.dart';

/// A service class to manage all interactions with the local Hive database.
class DatabaseService {
  static const String entriesBoxName = 'emotion_entries';
  static const String revisionsBoxName = 'emotion_revisions';
  static const String customEmotionsBoxName = 'custom_emotions';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(entriesBoxName);
    await Hive.openBox(revisionsBoxName);
    await Hive.openBox(customEmotionsBoxName);
  }

  static Future<void> saveEntry(EmotionEntry entry) async {
    final box = Hive.box(entriesBoxName);
    await box.put(entry.id, entry.toMap());
  }

  static Future<void> deleteEntry(String id) async {
    final box = Hive.box(entriesBoxName);
    await box.delete(id);
  }

  static List<EmotionEntry> getAllEntries() {
    final box = Hive.box(entriesBoxName);
    return box.values.map((map) => EmotionEntry.fromMap(map)).toList();
  }

  // --- Logic for Unlocking Tiers ---

  static int getTier1Count() {
    return getAllEntries().length;
  }

  static int getTier2Count() {
    return getAllEntries().where((e) => e.tier2Emotion != null).length;
  }

  static int getTier3Count() {
    return getAllEntries().where((e) => e.tier3Emotion != null).length;
  }

  static Future<void> saveRevision(EmotionEntryRevision revision) async {
    final box = Hive.box(revisionsBoxName);
    await box.add(revision.toMap());
  }

  // --- Custom Emotions Storage ---

  static List<String> getCustomTier2Emotions(String tier1) {
    final box = Hive.box(customEmotionsBoxName);
    return List<String>.from(box.get('tier2_$tier1', defaultValue: []));
  }

  static Future<void> addCustomTier2Emotion(String tier1, String emotion) async {
    final box = Hive.box(customEmotionsBoxName);
    final key = 'tier2_$tier1';
    final existing = getCustomTier2Emotions(tier1);
    if (!existing.contains(emotion)) {
      existing.add(emotion);
      await box.put(key, existing);
    }
  }

  static Future<void> removeCustomTier2Emotion(String tier1, String emotion) async {
    final box = Hive.box(customEmotionsBoxName);
    final key = 'tier2_$tier1';
    final existing = getCustomTier2Emotions(tier1);
    if (existing.remove(emotion)) {
      await box.put(key, existing);
    }
  }

  static List<String> getCustomTier3Emotions(String tier1) {
    final box = Hive.box(customEmotionsBoxName);
    return List<String>.from(box.get('tier3_$tier1', defaultValue: []));
  }

  static Future<void> addCustomTier3Emotion(String tier1, String emotion) async {
    final box = Hive.box(customEmotionsBoxName);
    final key = 'tier3_$tier1';
    final existing = getCustomTier3Emotions(tier1);
    if (!existing.contains(emotion)) {
      existing.add(emotion);
      await box.put(key, existing);
    }
  }

  static Future<void> removeCustomTier3Emotion(String tier1, String emotion) async {
    final box = Hive.box(customEmotionsBoxName);
    final key = 'tier3_$tier1';
    final existing = getCustomTier3Emotions(tier1);
    if (existing.remove(emotion)) {
      await box.put(key, existing);
    }
  }
}
