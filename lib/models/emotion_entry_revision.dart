/// Defines the type of revision being made.
enum RevisionType {
  /// A simple data fix for a typo or misclick.
  correction,

  /// A profound re-interpretation of a past emotion, with reasoning.
  reflection,

  /// Adding new information without changing the previous record.
  addition,
}

/// Represents an immutable revision or retrospective reflection on an existing [EmotionEntry].
class EmotionEntryRevision {
  /// The ID of the parent [EmotionEntry] this revision modifies.
  final String emotionEntryId;

  /// Timestamp when this revision was logged.
  final DateTime timestamp;

  /// Nature of the revision (correction, reflection, or addition).
  final RevisionType revisionType;

  /// Revised primary emotion category (Tier 1).
  final String tier1Emotion;

  /// Revised secondary emotion subcategory (Tier 2), if specified.
  final String? tier2Emotion;

  /// Revised specific emotion (Tier 3), if specified.
  final String? tier3Emotion;

  /// Revised intensity rating.
  final int intensity;

  /// Optional retrospective notes or reasoning for this revision.
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

  /// Serializes this revision to a map for Hive storage.
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

  /// Deserializes an [EmotionEntryRevision] from a Hive storage map.
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
