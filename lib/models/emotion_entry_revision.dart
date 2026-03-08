/// Defines the type of revision being made.
enum RevisionType {
  /// A simple data fix for a typo or misclick.
  correction,

  /// A profound re-interpretation of a past emotion, with reasoning.
  reflection,
}

class EmotionEntryRevision {
  final String emotionEntryId;
  final DateTime timestamp;
  final RevisionType revisionType;
  final String tier1Emotion;
  final String? tier2Emotion;
  final String? tier3Emotion;
  final int intensity;
  final String? reflectionText;
  
  /// Stores the state of the body map at the time of this revision.
  final Map<String, dynamic>? bodyMapData;

  /// Optional note about what influenced or triggered the emotion.
  final String? trigger;

  EmotionEntryRevision({
    required this.emotionEntryId,
    required this.revisionType,
    required this.tier1Emotion,
    this.tier2Emotion,
    this.tier3Emotion,
    required this.intensity,
    this.reflectionText,
    this.bodyMapData,
    this.trigger,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Convert EmotionEntryRevision object to a Map for Hive storage
  Map<String, dynamic> toMap() {
    return {
      'emotionEntryId': emotionEntryId,
      'timestamp': timestamp.toIso8601String(),
      'revisionType': revisionType.name,
      'tier1Emotion': tier1Emotion,
      'tier2Emotion': tier2Emotion,
      'tier3Emotion': tier3Emotion,
      'intensity': intensity,
      'reflectionText': reflectionText,
      'bodyMapData': bodyMapData,
      'trigger': trigger,
    };
  }

  // Create an EmotionEntryRevision object from a Hive Map
  factory EmotionEntryRevision.fromMap(Map<dynamic, dynamic> map) {
    return EmotionEntryRevision(
      emotionEntryId: map['emotionEntryId'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      revisionType: RevisionType.values.byName(map['revisionType'] as String),
      tier1Emotion: map['tier1Emotion'] as String,
      tier2Emotion: map['tier2Emotion'] as String?,
      tier3Emotion: map['tier3Emotion'] as String?,
      intensity: map['intensity'] as int,
      reflectionText: map['reflectionText'] as String?,
      bodyMapData: map['bodyMapData'] != null ? Map<String, dynamic>.from(map['bodyMapData'] as Map) : null,
      trigger: map['trigger'] as String?,
    );
  }
}
