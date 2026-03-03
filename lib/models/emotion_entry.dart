import 'package:uuid/uuid.dart';

class EmotionEntry {
  String id;
  DateTime timestamp; // The date/time the emotion happened (Calendar date)
  DateTime createdAt; // The real-world time the log was created
  String tier1Emotion;
  String? tier2Emotion;
  String? tier3Emotion;
  int intensity;
  
  // Body Map Coordinates (Normalized 0.0 to 1.0)
  double? bodyX;
  double? bodyY;

  EmotionEntry({
    required this.id,
    required this.timestamp,
    required this.createdAt,
    required this.tier1Emotion,
    this.tier2Emotion,
    this.tier3Emotion,
    this.intensity = 0,
    this.bodyX,
    this.bodyY,
  });

  static EmotionEntry create({
    required String tier1Emotion,
    String? tier2Emotion,
    String? tier3Emotion,
    int intensity = 0,
    double? bodyX,
    double? bodyY,
  }) {
    final now = DateTime.now();
    return EmotionEntry(
      id: const Uuid().v4(),
      timestamp: now,
      createdAt: now,
      tier1Emotion: tier1Emotion,
      tier2Emotion: tier2Emotion,
      tier3Emotion: tier3Emotion,
      intensity: intensity,
      bodyX: bodyX,
      bodyY: bodyY,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'tier1Emotion': tier1Emotion,
      'tier2Emotion': tier2Emotion,
      'tier3Emotion': tier3Emotion,
      'intensity': intensity,
      'bodyX': bodyX,
      'bodyY': bodyY,
    };
  }

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
      bodyX: map['bodyX'] as double?,
      bodyY: map['bodyY'] as double?,
    );
  }
}
