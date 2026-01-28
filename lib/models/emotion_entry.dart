import 'package:uuid/uuid.dart';

class EmotionEntry {
  // We use a String ID as the primary key for Hive
  String id;
  DateTime timestamp;
  String tier1Emotion;
  String? tier2Emotion;
  String? tier3Emotion;
  int intensity;

  EmotionEntry({
    required this.id,
    required this.timestamp,
    required this.tier1Emotion,
    this.tier2Emotion,
    this.tier3Emotion,
    this.intensity = 0,
  });

  // Helper to create a new entry with a fresh UUID
  static EmotionEntry create({
    required String tier1Emotion,
    String? tier2Emotion,
    String? tier3Emotion,
    int intensity = 0,
  }) {
    return EmotionEntry(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      tier1Emotion: tier1Emotion,
      tier2Emotion: tier2Emotion,
      tier3Emotion: tier3Emotion,
      intensity: intensity,
    );
  }

  // Convert EmotionEntry object to a Map for Hive storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'tier1Emotion': tier1Emotion,
      'tier2Emotion': tier2Emotion,
      'tier3Emotion': tier3Emotion,
      'intensity': intensity,
    };
  }

  // Create an EmotionEntry object from a Hive Map
  factory EmotionEntry.fromMap(Map<dynamic, dynamic> map) {
    return EmotionEntry(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      tier1Emotion: map['tier1Emotion'] as String,
      tier2Emotion: map['tier2Emotion'] as String?,
      tier3Emotion: map['tier3Emotion'] as String?,
      intensity: map['intensity'] as int,
    );
  }
}