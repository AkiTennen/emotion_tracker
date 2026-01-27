import 'package:uuid/uuid.dart';

// Create a single instance of Uuid to generate unique identifiers.
const _uuid = Uuid();

/// Abstract base class for all revisions made to an EmotionEntry.
///
/// Each revision has its own unique ID, a timestamp, and a link
/// back to the original EmotionEntry it belongs to.
abstract class EmotionEntryRevision {
  /// A unique ID for the revision itself.
  final String id;

  /// The ID of the EmotionEntry this revision is for.
  final String emotionEntryId;

  /// The timestamp of when this revision was created.
  final DateTime timestamp;

  EmotionEntryRevision({
    required this.emotionEntryId,
  })  : id = _uuid.v4(),
        timestamp = DateTime.now();
}

/// A 'Correction' revision.
///
/// Use this for simple data fixes (e.g., typos, misclicks).
/// The UI should display the data from this class *instead of* the
/// original EmotionEntry's data.
class EmotionEntryCorrection extends EmotionEntryRevision {
  /// The corrected primary emotion from Tier 1.
  final String tier1Emotion;

  /// The corrected optional secondary emotion from Tier 2.
  final String? tier2Emotion;

  /// The corrected optional tertiary emotion from Tier 3.
  final String? tier3Emotion;

  /// The corrected optional intensity level.
  final int intensity;

  EmotionEntryCorrection({
    required super.emotionEntryId,
    required this.tier1Emotion,
    this.tier2Emotion,
    this.tier3Emotion,
    required this.intensity,
  });
}

/// A 'Reflection' revision.
///
/// Use this for a re-interpretation of a past emotion. It updates the
/// core emotion data and captures the user's reasoning.
class EmotionEntryReflection extends EmotionEntryRevision {
  /// The re-interpreted primary emotion from Tier 1.
  final String tier1Emotion;

  /// The re-interpreted optional secondary emotion from Tier 2.
  final String? tier2Emotion;

  /// The re-interpreted optional tertiary emotion from Tier 3.
  final String? tier3Emotion;

  /// The re-interpreted optional intensity level.
  final int intensity;

  /// Optional text explaining the user's reason for the reflection.
  final String? reflectionText;

  EmotionEntryReflection({
    required super.emotionEntryId,
    required this.tier1Emotion,
    this.tier2Emotion,
    this.tier3Emotion,
    required this.intensity,
    this.reflectionText,
  });
}