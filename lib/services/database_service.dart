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
    // When deleting an entry, we should also delete its revisions
    await box.delete(id);
    
    final revBox = Hive.box(revisionsBoxName);
    final keysToDelete = revBox.keys.where((key) {
      final rev = EmotionEntryRevision.fromMap(revBox.get(key));
      return rev.emotionEntryId == id;
    }).toList();
    
    for (var key in keysToDelete) {
      await revBox.delete(key);
    }
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

  static int getIntensityCount() {
    return getAllEntries().where((e) => e.intensity > 0).length;
  }

  static int getBodyMapCount() {
    return getAllEntries().where((e) => e.bodyMapData != null).length;
  }

  static Future<void> saveRevision(EmotionEntryRevision revision) async {
    final box = Hive.box(revisionsBoxName);
    await box.add(revision.toMap());
  }

  /// Gets all revisions for a specific entry, sorted by time.
  static List<EmotionEntryRevision> getRevisionsForEntry(String entryId) {
    final box = Hive.box(revisionsBoxName);
    return box.values
        .map((map) => EmotionEntryRevision.fromMap(map))
        .where((rev) => rev.emotionEntryId == entryId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Returns the latest effective state of an entry (original + latest revision).
  static Map<String, dynamic> getLatestState(EmotionEntry entry) {
    final revisions = getRevisionsForEntry(entry.id);
    if (revisions.isEmpty) {
      return {
        'tier1': entry.tier1Emotion,
        'tier2': entry.tier2Emotion,
        'tier3': entry.tier3Emotion,
        'intensity': entry.intensity,
        'bodyMapData': entry.bodyMapData,
        'trigger': entry.trigger,
        'hasRevisions': false,
      };
    }
    
    final latest = revisions.last;
    return {
      'tier1': latest.tier1Emotion,
      'tier2': latest.tier2Emotion,
      'tier3': latest.tier3Emotion,
      'intensity': latest.intensity,
      'bodyMapData': latest.bodyMapData,
      'trigger': latest.trigger,
      'hasRevisions': true,
      'latestType': latest.revisionType,
      'latestTimestamp': latest.timestamp,
    };
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
