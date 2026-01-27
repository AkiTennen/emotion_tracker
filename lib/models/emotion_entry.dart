import 'package:uuid/uuid.dart';

// Create a single instance of Uuid to generate unique identifiers.
const _uuid = Uuid();

/// Represents a single emotional snapshot recorded by the user.
/// This is the core data model for an entry before revisions are considered.
class EmotionEntry {
  /// A unique, universally unique identifier (UUID v4) for this specific entry.
  final String id;

  /// The date and time when the emotion was originally recorded.
  final DateTime timestamp;

  /// The primary emotion selected from Tier 1. This is mandatory.
  final String tier1Emotion;

  /// An optional secondary emotion from Tier 2.
  final String? tier2Emotion;

  /// An optional tertiary emotion from Tier 3.
  final String? tier3Emotion;

  /// An optional intensity level for the overall emotional state.
  /// Defaults to 0 if not provided.
  final int intensity;

  /// Private constructor for internal use, ensuring data consistency.
  EmotionEntry._({
    required this.id,
    required this.timestamp,
    required this.tier1Emotion,
    this.tier2Emotion,
    this.tier3Emotion,
    this.intensity = 0,
  });

  /// Factory constructor to create a new, timestamped emotion entry.
  ///
  /// This is the primary way to create a new entry. It automatically
  /// generates a unique ID using UUID v4 and sets the current timestamp.
  factory EmotionEntry.create({
    required String tier1Emotion,
    String? tier2Emotion,
    String? tier3Emotion,
    int intensity = 0,
  }) {
    return EmotionEntry._(
      id: _uuid.v4(), // Generate a new, unique ID
      timestamp: DateTime.now(),
      tier1Emotion: tier1Emotion,
      tier2Emotion: tier2Emotion,
      tier3Emotion: tier3Emotion,
      intensity: intensity,
    );
  }
}