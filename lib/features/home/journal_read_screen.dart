import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/journal_entry.dart';
import '../../models/emotion_entry.dart';
import '../../models/emotion_data.dart';
import '../../services/database_service.dart';
import '../../services/settings_service.dart';

class JournalReadScreen extends StatelessWidget {
  final JournalEntry journal;

  const JournalReadScreen({super.key, required this.journal});

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final latest = DatabaseService.getLatestJournalState(journal);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = SettingsService.getDateFormat();
    
    final dayEntries = DatabaseService.getAllEntries()
        .where((e) => isSameDay(e.timestamp, journal.timestamp))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat(dateFormat).format(journal.timestamp)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Theme.of(context).hintColor),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('HH:mm').format(journal.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (latest['hasRevisions']) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Edited',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  if (dayEntries.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: dayEntries.map((e) {
                        final eLatest = DatabaseService.getLatestState(e);
                        final emotionColor = EmotionData.getColor(eLatest['tier1']);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: emotionColor.withOpacity(isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: emotionColor.withOpacity(isDark ? 0.5 : 0.4),
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            eLatest['tier1'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? emotionColor.withOpacity(0.95) : emotionColor.withOpacity(0.9),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 32),
                  Text(
                    latest['content'],
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                child: const Text('Back to Home'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
