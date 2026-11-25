import 'emotion_entry_revision.dart';

/// Represents an immutable revision or reflection made to an existing [JournalEntry].
class JournalRevision {
  /// The ID of the parent [JournalEntry] this revision modifies.
  final String journalId;

  /// Timestamp when this revision was recorded.
  final DateTime timestamp;

  /// Nature of the revision (correction, reflection, or addition).
  final RevisionType revisionType;

  /// Updated content of the journal at the time of this revision.
  final String content;

  /// Optional retrospective notes or reasoning for this revision.
  final String? reflectionText;

  JournalRevision({
    required this.journalId,
    required this.revisionType,
    required this.content,
    this.reflectionText,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Serializes this journal revision to a map for Hive storage.
  Map<String, dynamic> toMap() {
    return {
      'journalId': journalId,
      'timestamp': timestamp.toIso8601String(),
      'revisionType': revisionType.name,
      'content': content,
      'reflectionText': reflectionText,
    };
  }

  /// Deserializes a [JournalRevision] from a Hive storage map.
  factory JournalRevision.fromMap(Map<dynamic, dynamic> map) {
    return JournalRevision(
      journalId: map['journalId'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      revisionType: RevisionType.values.byName(map['revisionType'] as String),
      content: map['content'] as String,
      reflectionText: map['reflectionText'] as String?,
    );
  }
}
