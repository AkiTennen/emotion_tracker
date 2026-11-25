import 'package:uuid/uuid.dart';

/// Represents a primary recorded emotion entry in the user's log.
class EmotionEntry {
  /// Unique identifier (UUID).
  String id;

  /// The calendar date and time the user experienced the emotion.
  DateTime timestamp;

  /// The real-world timestamp when this entry was created.
  DateTime createdAt;

  /// Primary emotion category (Tier 1).
  String tier1Emotion;

  /// Secondary emotion subcategory (Tier 2), if selected.
  String? tier2Emotion;

  /// Specific emotion (Tier 3), if selected.
  String? tier3Emotion;

  /// Intensity rating of the emotion (typically 1-5, or 0 if unrated).
  int intensity;
  
  /// Stores body map drawing data as a JSON-compatible map.
  Map<String, dynamic>? bodyMapData;

  /// Optional note about what influenced or triggered the emotion.
  String? trigger;

  EmotionEntry({
    required this.id,
    required this.timestamp,
    required this.createdAt,
    required this.tier1Emotion,
    this.tier2Emotion,
    this.tier3Emotion,
    this.intensity = 0,
    this.bodyMapData,
    this.trigger,
  });

  /// Serializes this entry to a map for Hive storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'tier1Emotion': tier1Emotion,
      'tier2Emotion': tier2Emotion,
      'tier3Emotion': tier3Emotion,
      'intensity': intensity,
      'bodyMapData': bodyMapData,
      'trigger': trigger,
    };
  }

  /// Deserializes an entry from storage, falling back to [timestamp] if [createdAt] is missing.
  factory EmotionEntry.fromMap(Map<dynamic, dynamic> map) {
    return EmotionEntry(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String) 
          : DateTime.parse(map['timestamp'] as String),
      tier1Emotion: map['tier1Emotion'] as String,
      tier2Emotion: map['tier2Emotion'] as String?,
      tier3Emotion: map['tier3Emotion'] as String?,
      intensity: map['intensity'] as int,
      bodyMapData: map['bodyMapData'] != null ? Map<String, dynamic>.from(map['bodyMapData'] as Map) : null,
      trigger: map['trigger'] as String?,
    );
  }
}
