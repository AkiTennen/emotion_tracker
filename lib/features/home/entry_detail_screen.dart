import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/emotion_data.dart';
import '../../models/emotion_entry.dart';
import '../../models/emotion_entry_revision.dart';
import '../../services/database_service.dart';
import '../../services/settings_service.dart';
import '../add_emotion/body_map_screen.dart';
import '../add_emotion/add_emotion_screen.dart';

class EntryDetailScreen extends StatefulWidget {
  final EmotionEntry entry;

  const EntryDetailScreen({super.key, required this.entry});

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  bool _showTimelineHint = false;

  @override
  void initState() {
    super.initState();
    _showTimelineHint = !SettingsService.isTimelineHintShown();
  }

  @override
  Widget build(BuildContext context) {
    final revisions = DatabaseService.getRevisionsForEntry(widget.entry.id);
    final dateFormat = SettingsService.getDateFormat();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry History'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showTimelineHint)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history_edu, color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 12),
                        const Text('Your Emotional Timeline', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Every correction and reflection you make is preserved here, so you can see exactly how your perspective has shifted over time.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        await SettingsService.setTimelineHintShown(true);
                        setState(() => _showTimelineHint = false);
                      },
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              ),
            _buildTimelineTile(
              context,
              title: 'Original Moment',
              timestamp: widget.entry.createdAt, 
              tier1: widget.entry.tier1Emotion,
              tier2: widget.entry.tier2Emotion,
              tier3: widget.entry.tier3Emotion,
              intensity: widget.entry.intensity,
              bodyMapData: widget.entry.bodyMapData,
              trigger: widget.entry.trigger,
              isOriginal: true,
              dateFormat: dateFormat,
              description: 'Refers to ${DateFormat(dateFormat).format(widget.entry.timestamp)}, ${DateFormat('HH:mm').format(widget.entry.timestamp)}',
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
              dateFormat: dateFormat,
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
    required String dateFormat,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
                child: icon != null ? Icon(icon, size: 10, color: opacity > 0.6 ? Colors.white : (isDark ? Colors.white : Colors.black87)) : null,
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: Theme.of(context).dividerColor,
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
                      '${DateFormat(dateFormat).format(timestamp)}, ${DateFormat('HH:mm').format(timestamp)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (description != null) 
                  Text(description, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).hintColor)),
                const SizedBox(height: 4),
                Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  elevation: 0,
                  color: color.withOpacity(isDark ? 0.2 : 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: color.withOpacity(isDark ? 0.4 : 0.2)),
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
                                              color: isDark ? Colors.grey[300] : Colors.black87,
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
                                    color: isDark ? Colors.grey[850] : Colors.white,
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

class BodyMapSmallPreviewPainter extends CustomPainter {
  final Map<String, dynamic> data;
  final Color color;

  BodyMapSmallPreviewPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final midX = size.width / 2;
    final front = data['frontPaths'] as List?;
    final back = data['backPaths'] as List?;

    if (front != null) {
      for (var path in front) {
        final screenPath = Path();
        final points = path as List;
        if (points.isEmpty) continue;
        screenPath.moveTo(points[0][0] * midX, points[0][1] * size.height);
        for (var i = 1; i < points.length; i++) {
          screenPath.lineTo(points[i][0] * midX, points[i][1] * size.height);
        }
        canvas.drawPath(screenPath, paint);
      }
    }

    if (back != null) {
      for (var path in back) {
        final screenPath = Path();
        final points = path as List;
        if (points.isEmpty) continue;
        screenPath.moveTo((points[0][0] * midX) + midX, points[0][1] * size.height);
        for (var i = 1; i < points.length; i++) {
          screenPath.lineTo((points[i][0] * midX) + midX, points[i][1] * size.height);
        }
        canvas.drawPath(screenPath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
