import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../models/emotion_entry.dart';
import '../models/emotion_entry_revision.dart';

/// A service class to manage all interactions with the local Hive database.
class DatabaseService {
  static const String entriesBoxName = 'emotion_entries';
  static const String revisionsBoxName = 'emotion_revisions';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(entriesBoxName);
    await Hive.openBox(revisionsBoxName);
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

  /// Returns the count of entries that have a Tier 1 emotion.
  static int getTier1Count() {
    return getAllEntries().length;
  }

  /// Returns the count of entries that have a Tier 2 emotion.
  static int getTier2Count() {
    return getAllEntries().where((e) => e.tier2Emotion != null).length;
  }

  /// Returns the count of entries that have a Tier 3 emotion.
  static int getTier3Count() {
    return getAllEntries().where((e) => e.tier3Emotion != null).length;
  }

  static Future<void> saveRevision(EmotionEntryRevision revision) async {
    final box = Hive.box(revisionsBoxName);
    await box.add(revision.toMap());
  }
}
