import 'package:flutter/material.dart';

class EmotionData {
  static const Map<String, Map<String, List<String>>> wheel = {
    'Bad': {
      'Bored': ['Indifferent', 'Apathetic'],
      'Busy': ['Pressured', 'Rushed'],
      'Stressed': ['Overwhelmed', 'Out of control'],
      'Tired': ['Sleepy', 'Unfocussed'],
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
      'Frustrated': ['Infuriated', 'Annoyed'],
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
      'Interested': ['Inquisitive', 'Curious'],
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

  static List<String> get tier1 => wheel.keys.toList();

  static List<String> getTier2(String t1) => wheel[t1]?.keys.toList() ?? [];

  static List<String> getAllTier3ForCategory(String t1) {
    final category = wheel[t1];
    if (category == null) return [];
    return category.values.expand((list) => list).toSet().toList(); // toSet to remove duplicates like 'Embarrassed'
  }

  static List<String> getTier3Specific(String t1, String t2) => wheel[t1]?[t2] ?? [];

  static Color getColor(String tier1Emotion) {
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
}
