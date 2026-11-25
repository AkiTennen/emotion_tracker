import 'package:uuid/uuid.dart';

/// Represents a freeform journal text entry linked to a specific calendar date.
class JournalEntry {
  /// Unique identifier (UUID).
  final String id;

  /// The calendar date and time this journal refers to.
  final DateTime timestamp;

  /// Real-world creation timestamp.
  final DateTime createdAt;

  /// The markdown or plain text content of the journal.
  final String content;

  JournalEntry({
    required this.id,
    required this.timestamp,
    required this.createdAt,
    required this.content,
  });

  /// Serializes this journal entry to a map for Hive storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'content': content,
    };
  }

  /// Deserializes a journal entry from storage, falling back to [timestamp] if [createdAt] is missing.
  factory JournalEntry.fromMap(Map<dynamic, dynamic> map) {
    return JournalEntry(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String) 
          : DateTime.parse(map['timestamp'] as String),
      content: map['content'] as String,
    );
  }
}
