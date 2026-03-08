import 'emotion_entry_revision.dart';

class JournalRevision {
  final String journalId;
  final DateTime timestamp;
  final RevisionType revisionType;
  final String content;
  final String? reflectionText;

  JournalRevision({
    required this.journalId,
    required this.revisionType,
    required this.content,
    this.reflectionText,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'journalId': journalId,
      'timestamp': timestamp.toIso8601String(),
      'revisionType': revisionType.name,
      'content': content,
      'reflectionText': reflectionText,
    };
  }

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
