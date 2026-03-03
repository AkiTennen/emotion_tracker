import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../models/emotion_entry.dart';
import '../models/emotion_entry_revision.dart';

/// A service class to manage all interactions with the local Hive database.
class DatabaseService {
  // Box names act like table names in a traditional database
  static const String entriesBoxName = 'emotion_entries';
  static const String revisionsBoxName = 'emotion_revisions';

  /// Initializes the Hive database.
  /// This must be called once in main.dart.
  static Future<void> init() async {
    // 1. Initialize Hive for Flutter (handles path_provider internally)
    await Hive.initFlutter();

    // 2. Open the boxes so they are ready to use
    // We open them now so we don't have to 'await' every time we save/load
    await Hive.openBox(entriesBoxName);
    await Hive.openBox(revisionsBoxName);
  }

  // --- Data Access Methods ---

  /// Saves or updates an EmotionEntry
  static Future<void> saveEntry(EmotionEntry entry) async {
    final box = Hive.box(entriesBoxName);
    // We use the entry.id as the key so it's easy to find/update later
    await box.put(entry.id, entry.toMap());
  }

  /// Deletes an EmotionEntry by its ID
  static Future<void> deleteEntry(String id) async {
    final box = Hive.box(entriesBoxName);
    await box.delete(id);
  }

  /// Retrieves all EmotionEntries from the database
  static List<EmotionEntry> getAllEntries() {
    final box = Hive.box(entriesBoxName);
    // Convert the raw Maps back into EmotionEntry objects
    return box.values.map((map) => EmotionEntry.fromMap(map)).toList();
  }

  /// Saves a revision
  static Future<void> saveRevision(EmotionEntryRevision revision) async {
    final box = Hive.box(revisionsBoxName);
    // For revisions, we can just use an auto-incrementing key
    await box.add(revision.toMap());
  }
}
