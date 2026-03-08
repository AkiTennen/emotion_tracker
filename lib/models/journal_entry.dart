import 'package:uuid/uuid.dart';

class JournalEntry {
  final String id;
  final DateTime timestamp; // The calendar date/time this journal refers to
  final DateTime createdAt; // Real-world creation time
  final String content;

  JournalEntry({
    required this.id,
    required this.timestamp,
    required this.createdAt,
    required this.content,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'content': content,
    };
  }

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
