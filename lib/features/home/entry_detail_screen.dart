import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/emotion_data.dart';
import '../../models/emotion_entry.dart';
import '../../models/emotion_entry_revision.dart';
import '../../services/database_service.dart';

class EntryDetailScreen extends StatelessWidget {
  final EmotionEntry entry;

  const EntryDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final revisions = DatabaseService.getRevisionsForEntry(entry.id);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry History'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimelineTile(
              context,
              title: 'Original Moment',
              // SHOW: Real-world creation date/time
              timestamp: entry.createdAt, 
              tier1: entry.tier1Emotion,
              tier2: entry.tier2Emotion,
              tier3: entry.tier3Emotion,
              intensity: entry.intensity,
              isOriginal: true,
              // SUBTITLE: The date it refers to on the calendar
              description: 'Refers to ${DateFormat('MMM d, HH:mm').format(entry.timestamp)}',
            ),
            ...revisions.map((rev) => _buildTimelineTile(
              context,
              title: rev.revisionType == RevisionType.correction ? 'Correction' : 'Reflection',
              timestamp: rev.timestamp,
              tier1: rev.tier1Emotion,
              tier2: rev.tier2Emotion,
              tier3: rev.tier3Emotion,
              intensity: rev.intensity,
              note: rev.reflectionText,
              icon: rev.revisionType == RevisionType.correction ? Icons.edit_note : Icons.psychology,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTile(
    BuildContext context, {
    required String title,
    required DateTime timestamp,
    required String tier1,
    String? tier2,
    String? tier3,
    required int intensity,
    String? note,
    String? description,
    bool isOriginal = false,
    IconData? icon,
  }) {
    final color = EmotionData.getColor(tier1);
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                  ],
                ),
                child: icon != null ? Icon(icon, size: 10, color: Colors.white) : null,
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: Colors.grey.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      DateFormat('MMM d, HH:mm').format(timestamp),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (description != null) 
                  Text(description, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey)),
                const SizedBox(height: 4),
                Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  elevation: 0,
                  color: color.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: color.withOpacity(0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$tier1 ${tier2 != null ? "• $tier2" : ""} ${tier3 != null ? "• $tier3" : ""}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text('Intensity: $intensity', style: Theme.of(context).textTheme.bodySmall),
                        if (note != null && note.isNotEmpty) ...[
                          const Divider(),
                          Text(
                            note,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
