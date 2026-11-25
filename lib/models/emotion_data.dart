import 'package:flutter/material.dart';
import '../services/settings_service.dart';

/// Represents a matched emotion node in the hierarchy, identifying its category,
/// depth level (Tier 1, 2, or 3), and whether it was user-created.
class EmotionMatch {
  /// The primary (Tier 1) category name.
  final String tier1;

  /// The secondary (Tier 2) subcategory name, if matched at Tier 2 or Tier 3.
  final String? tier2;

  /// The tertiary (Tier 3) specific emotion name, if matched at Tier 3.
  final String? tier3;

  /// Depth level in the emotion hierarchy (1, 2, or 3).
  final int tier;

  /// Whether this match originates from user-defined custom emotions.
  final bool isCustom;

  EmotionMatch({
    required this.tier1,
    this.tier2,
    this.tier3,
    required this.tier,
    this.isCustom = false,
  });
}

/// Static data repository and search utility for the emotion wheel hierarchy
/// (Tier 1 Primary -> Tier 2 Secondary -> Tier 3 Specific).
class EmotionData {
  /// The standard Feeling Wheel taxonomy mapping:
  /// Primary Category -> Secondary Subcategory -> List of Specific Emotions.
  static const Map<String, Map<String, List<String>>> wheel = {
    'Bad': {
      'Bored': ['Indifferent', 'Apathetic'],
      'Busy': ['Pressured', 'Rushed'],
      'Stressed': ['Overwhelmed', 'Out of control'],
      'Tired': ['Sleepy', 'Unfocused'],
    },
    'Fearful': {
      'Scared': ['Helpless', 'Frightened'],
      'Anxious': ['Overwhelmed', 'Worried'],
      'Insecure': ['Inadequate', 'Inferior'],
      'Weak': ['Worthless', 'Insignificant'],
      'Rejected': ['Excluded', 'Persecuted'],
      'Threatened': ['Nervous', 'Exposed'],
    },
    'Angry': {
      'Let down': ['Betrayed', 'Resentful'],
      'Humiliated': ['Disrespected', 'Ridiculed'],
      'Bitter': ['Indignant', 'Violated'],
      'Mad': ['Furious', 'Jealous'],
      'Aggressive': ['Provoked', 'Hostile'],
      'Frustrated': ['Annoyed'],
      'Distant': ['Withdrawn', 'Numb'],
      'Critical': ['Sceptical', 'Dismissive'],
    },
    'Disgusted': {
      'Disapproving': ['Judgmental', 'Embarrassed'],
      'Disappointed': ['Appalled', 'Revolted'],
      'Awful': ['Nauseated', 'Detestable'],
      'Repelled': ['Horrified', 'Hesitant'],
    },
    'Sad': {
      'Lonely': ['Isolated', 'Abandoned'],
      'Vulnerable': ['Victimised', 'Fragile'],
      'Despair': ['Grief', 'Powerless'],
      'Guilty': ['Ashamed', 'Remorseful'],
      'Depressed': ['Empty', 'Inferior'],
      'Hurt': ['Disappointed', 'Embarrassed'],
    },
    'Happy': {
      'Optimistic': ['Hopeful', 'Inspired'],
      'Trusting': ['Intimate', 'Sensitive'],
      'Peaceful': ['Thankful', 'Loving'],
      'Powerful': ['Creative', 'Courageous'],
      'Accepted': ['Valued', 'Respected'],
      'Proud': ['Confident', 'Successful'],
      'Interested': ['Inquisitive', 'Curious', 'Focused'],
      'Content': ['Joyful', 'Free'],
      'Playful': ['Cheeky', 'Aroused'],
    },
    'Surprised': {
      'Excited': ['Energetic', 'Eager'],
      'Amazed': ['Awe', 'Astonished'],
      'Confused': ['Perplexed', 'Disillusioned'],
      'Startled': ['Dismayed', 'Shocked'],
    },
  };

  /// Returns all primary (Tier 1) emotion categories.
  static List<String> get tier1 => wheel.keys.toList();

  /// Returns all secondary (Tier 2) subcategories under [t1].
  static List<String> getTier2(String t1) => wheel[t1]?.keys.toList() ?? [];

  /// Returns a deduplicated list of all tertiary (Tier 3) emotions under [t1].
  static List<String> getAllTier3ForCategory(String t1) {
    final category = wheel[t1];
    if (category == null) return [];
    return category.values.expand((list) => list).toSet().toList();
  }

  /// Returns the specific tertiary (Tier 3) emotions under category [t1] and subcategory [t2].
  static List<String> getTier3Specific(String t1, String t2) => wheel[t1]?[t2] ?? [];

  /// Resolves the display [Color] for a primary [tier1Emotion].
  /// Checks for user-configured custom colors first, then falls back to default palette hues.
  static Color getColor(String tier1Emotion) {
    // Check for user-defined custom color override
    final customColors = SettingsService.getCustomColors();
    if (customColors.containsKey(tier1Emotion)) {
      return Color(customColors[tier1Emotion]!);
    }

    // Default palette fallbacks
    switch (tier1Emotion) {
      case 'Bad': return Colors.brown.shade300;
      case 'Fearful': return Colors.deepPurple.shade300;
      case 'Angry': return Colors.red.shade400;
      case 'Disgusted': return Colors.green.shade400;
      case 'Sad': return Colors.blue.shade400;
      case 'Happy': return Colors.amber.shade400;
      case 'Surprised': return Colors.cyan.shade400;
      default: return Colors.grey;
    }
  }

  /// Searches for a case-insensitive text match in the built-in wheel hierarchy
  /// as well as any provided custom Tier 2 or Tier 3 emotion maps.
  static EmotionMatch? findMatch(
    String text, {
    Map<String, List<String>>? customT2Map,
    Map<String, List<String>>? customT3Map,
  }) {
    final lowerText = text.trim().toLowerCase();
    if (lowerText.isEmpty) return null;

    // 1. Check built-in wheel
    for (var t1 in wheel.keys) {
      if (t1.toLowerCase() == lowerText) return EmotionMatch(tier1: t1, tier: 1);
      
      final t2Map = wheel[t1]!;
      for (var t2 in t2Map.keys) {
        if (t2.toLowerCase() == lowerText) return EmotionMatch(tier1: t1, tier2: t2, tier: 2);
        
        final t3List = t2Map[t2]!;
        for (var t3 in t3List) {
          if (t3.toLowerCase() == lowerText) return EmotionMatch(tier1: t1, tier2: t2, tier3: t3, tier: 3);
        }
      }
    }

    // 2. Check custom emotions (if provided)
    if (customT2Map != null) {
      for (var t1 in customT2Map.keys) {
        for (var t2 in customT2Map[t1]!) {
          if (t2.toLowerCase() == lowerText) {
            return EmotionMatch(tier1: t1, tier2: t2, tier: 2, isCustom: true);
          }
        }
      }
    }

    if (customT3Map != null) {
      for (var t1 in customT3Map.keys) {
        for (var t2 in customT3Map[t1]!) {
          if (t2.toLowerCase() == lowerText) {
            return EmotionMatch(tier1: t1, tier3: t2, tier: 3, isCustom: true);
          }
        }
      }
    }

    return null;
  }
}
