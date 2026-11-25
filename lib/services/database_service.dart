import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../models/emotion_entry.dart';
import '../models/emotion_entry_revision.dart';
import '../models/journal_entry.dart';
import '../models/journal_revision.dart';

/// A service class to manage all interactions with the local Hive database,
/// including emotion logs, journal entries, revisions, and custom emotions.
class DatabaseService {
  /// Box name for primary emotion entries.
  static const String entriesBoxName = 'emotion_entries';
  /// Box name for emotion entry revisions.
  static const String revisionsBoxName = 'emotion_revisions';
  /// Box name for user-defined custom emotions.
  static const String customEmotionsBoxName = 'custom_emotions';
  /// Box name for primary journal entries.
  static const String journalsBoxName = 'journals';
  /// Box name for journal entry revisions.
  static const String journalRevisionsBoxName = 'journal_revisions';

  /// Initializes Flutter Hive storage and opens all required boxes.
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(entriesBoxName);
    await Hive.openBox(revisionsBoxName);
    await Hive.openBox(customEmotionsBoxName);
    await Hive.openBox(journalsBoxName);
    await Hive.openBox(journalRevisionsBoxName);
  }

  /// Saves or updates an [EmotionEntry] in the entries box.
  static Future<void> saveEntry(EmotionEntry entry) async {
    final box = Hive.box(entriesBoxName);
    await box.put(entry.id, entry.toMap());
  }

  /// Deletes an [EmotionEntry] and cascades deletion to all associated revisions.
  static Future<void> deleteEntry(String id) async {
    final box = Hive.box(entriesBoxName);
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

  /// Retrieves all stored [EmotionEntry] records.
  static List<EmotionEntry> getAllEntries() {
    final box = Hive.box(entriesBoxName);
    return box.values.map((map) => EmotionEntry.fromMap(map)).toList();
  }

  // ==========================================
  // Progression & Unlock Tracking
  // ==========================================

  /// Total count of Tier 1 emotion entries logged.
  static int getTier1Count() {
    return getAllEntries().length;
  }

  /// Total count of entries that have a Tier 2 emotion specified.
  static int getTier2Count() {
    return getAllEntries().where((e) => e.tier2Emotion != null).length;
  }

  /// Total count of entries that have a Tier 3 emotion specified.
  static int getTier3Count() {
    return getAllEntries().where((e) => e.tier3Emotion != null).length;
  }

  /// Total count of entries where an intensity (> 0) was recorded.
  static int getIntensityCount() {
    return getAllEntries().where((e) => e.intensity > 0).length;
  }

  /// Total count of entries with body map drawing data attached.
  static int getBodyMapCount() {
    return getAllEntries().where((e) => e.bodyMapData != null).length;
  }

  /// Total count of entries with a non-empty trigger/influence note.
  static int getTriggerCount() {
    return getAllEntries().where((e) => e.trigger != null && e.trigger!.isNotEmpty).length;
  }

  // ==========================================
  // Emotion Revisions
  // ==========================================

  /// Appends a new revision for an emotion entry.
  /// Appends a new revision for an emotion entry.
  static Future<void> saveRevision(EmotionEntryRevision revision) async {
    final box = Hive.box(revisionsBoxName);
    await box.add(revision.toMap());
  }

  /// Returns all revisions for a specific [entryId], sorted chronologically.
  static List<EmotionEntryRevision> getRevisionsForEntry(String entryId) {
    final box = Hive.box(revisionsBoxName);
    return box.values
        .map((map) => EmotionEntryRevision.fromMap(map))
        .where((rev) => rev.emotionEntryId == entryId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Computes the effective latest state of an entry by overlaying its latest revision,
  /// or returns the original entry values if no revisions exist.
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

  // ==========================================
  // Journal Database Logic
  // ==========================================

  /// Saves or updates a [JournalEntry] in the journals box.
  static Future<void> saveJournal(JournalEntry journal) async {
    final box = Hive.box(journalsBoxName);
    await box.put(journal.id, journal.toMap());
  }

  /// Deletes a [JournalEntry] and cascades deletion to all associated revisions.
  static Future<void> deleteJournal(String id) async {
    final box = Hive.box(journalsBoxName);
    await box.delete(id);
    
    final revBox = Hive.box(journalRevisionsBoxName);
    final keysToDelete = revBox.keys.where((key) {
      final rev = JournalRevision.fromMap(revBox.get(key));
      return rev.journalId == id;
    }).toList();
    
    for (var key in keysToDelete) {
      await revBox.delete(key);
    }
  }

  /// Retrieves all stored [JournalEntry] records.
  static List<JournalEntry> getAllJournals() {
    final box = Hive.box(journalsBoxName);
    return box.values.map((map) => JournalEntry.fromMap(map)).toList();
  }

  /// Returns all journal entries created on the given calendar [day].
  static List<JournalEntry> getJournalsForDay(DateTime day) {
    return getAllJournals().where((j) => 
      j.timestamp.year == day.year && 
      j.timestamp.month == day.month && 
      j.timestamp.day == day.day
    ).toList();
  }

  /// Appends a new revision for a journal entry.
  static Future<void> saveJournalRevision(JournalRevision revision) async {
    final box = Hive.box(journalRevisionsBoxName);
    await box.add(revision.toMap());
  }

  /// Returns all revisions for a specific [journalId], sorted chronologically.
  static List<JournalRevision> getRevisionsForJournal(String journalId) {
    final box = Hive.box(journalRevisionsBoxName);
    return box.values
        .map((map) => JournalRevision.fromMap(map))
        .where((rev) => rev.journalId == journalId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Computes the effective latest state of a journal entry by overlaying its latest revision.
  static Map<String, dynamic> getLatestJournalState(JournalEntry journal) {
    final revisions = getRevisionsForJournal(journal.id);
    if (revisions.isEmpty) {
      return {
        'content': journal.content,
        'hasRevisions': false,
      };
    }
    final latest = revisions.last;
    return {
      'content': latest.content,
      'hasRevisions': true,
      'latestType': latest.revisionType,
      'latestTimestamp': latest.timestamp,
    };
  }

  // ==========================================
  // Custom Emotions Storage
  // ==========================================

  /// Retrieves user-created Tier 2 emotions associated with the given [tier1] emotion.
  static List<String> getCustomTier2Emotions(String tier1) {
    final box = Hive.box(customEmotionsBoxName);
    return List<String>.from(box.get('tier2_$tier1', defaultValue: []));
  }

  /// Adds a custom Tier 2 [emotion] under the given [tier1] category if not already present.
  static Future<void> addCustomTier2Emotion(String tier1, String emotion) async {
    final box = Hive.box(customEmotionsBoxName);
    final key = 'tier2_$tier1';
    final existing = getCustomTier2Emotions(tier1);
    if (!existing.contains(emotion)) {
      existing.add(emotion);
      await box.put(key, existing);
    }
  }

  /// Removes a custom Tier 2 [emotion] under the given [tier1] category.
  static Future<void> removeCustomTier2Emotion(String tier1, String emotion) async {
    final box = Hive.box(customEmotionsBoxName);
    final key = 'tier2_$tier1';
    final existing = getCustomTier2Emotions(tier1);
    if (existing.remove(emotion)) {
      await box.put(key, existing);
    }
  }

  /// Retrieves user-created Tier 3 emotions associated with the given [tier1] emotion.
  static List<String> getCustomTier3Emotions(String tier1) {
    final box = Hive.box(customEmotionsBoxName);
    return List<String>.from(box.get('tier3_$tier1', defaultValue: []));
  }

  /// Adds a custom Tier 3 [emotion] under the given [tier1] category if not already present.
  static Future<void> addCustomTier3Emotion(String tier1, String emotion) async {
    final box = Hive.box(customEmotionsBoxName);
    final key = 'tier3_$tier1';
    final existing = getCustomTier3Emotions(tier1);
    if (!existing.contains(emotion)) {
      existing.add(emotion);
      await box.put(key, existing);
    }
  }

  /// Removes a custom Tier 3 [emotion] under the given [tier1] category.
  static Future<void> removeCustomTier3Emotion(String tier1, String emotion) async {
    final box = Hive.box(customEmotionsBoxName);
    final key = 'tier3_$tier1';
    final existing = getCustomTier3Emotions(tier1);
    if (existing.remove(emotion)) {
      await box.put(key, existing);
    }
  }
}
