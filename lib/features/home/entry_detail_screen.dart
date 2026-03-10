import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/emotion_data.dart';
import '../../models/emotion_entry.dart';
import '../../models/emotion_entry_revision.dart';
import '../../services/database_service.dart';
import '../../services/settings_service.dart';
import '../add_emotion/body_map_screen.dart';
import '../add_emotion/add_emotion_screen.dart';

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
              timestamp: entry.createdAt, 
              tier1: entry.tier1Emotion,
              tier2: entry.tier2Emotion,
              tier3: entry.tier3Emotion,
              intensity: entry.intensity,
              bodyMapData: entry.bodyMapData,
              trigger: entry.trigger,
              isOriginal: true,
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
              bodyMapData: rev.bodyMapData,
              trigger: rev.trigger,
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
    Map<String, dynamic>? bodyMapData,
    String? trigger,
    String? note,
    String? description,
    bool isOriginal = false,
    IconData? icon,
  }) {
    final color = EmotionData.getColor(tier1);
    final double opacity = 0.25 + (intensity * 0.25);
    
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
                  color: color.withOpacity(opacity),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                  ],
                ),
                child: icon != null ? Icon(icon, size: 10, color: opacity > 0.6 ? Colors.white : Colors.black87) : null,
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$tier1 ${tier2 != null ? "• $tier2" : ""} ${tier3 != null ? "• $tier3" : ""}',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Intensity: $intensity', style: Theme.of(context).textTheme.bodySmall),
                                  if (trigger != null && trigger.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.bolt, size: 14, color: Colors.orange),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Trigger: $trigger',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              fontStyle: FontStyle.italic,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (bodyMapData != null)
                              GestureDetector(
                                onTap: () {
                                  final typeStr = bodyMapData['bodyType'] as String?;
                                  final bodyType = typeStr != null 
                                      ? BodyType.values.byName(typeStr) 
                                      : SettingsService.getBodyType();
                                      
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BodyMapScreen(
                                        initialData: bodyMapData,
                                        emotionColor: color,
                                        readOnly: true,
                                        overrideBodyType: bodyType,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: color.withOpacity(0.3)),
                                  ),
                                  child: Stack(
                                    children: [
                                      CustomPaint(
                                        size: const Size(60, 60),
                                        painter: BodyMapSmallPreviewPainter(
                                          data: bodyMapData,
                                          color: color,
                                        ),
                                      ),
                                      const Positioned(
                                        right: 2,
                                        bottom: 2,
                                        child: Icon(Icons.zoom_in, size: 14, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
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
