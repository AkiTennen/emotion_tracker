import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:math' as math;
import '../../models/emotion_data.dart';
import '../../models/emotion_entry.dart';
import '../../models/emotion_entry_revision.dart';
import '../../services/database_service.dart';
import '../add_emotion/add_emotion_screen.dart';
import '../settings/settings_screen.dart';
import 'entry_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  List<EmotionEntry> _allEntries = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _allEntries = DatabaseService.getAllEntries();
    });
  }

  List<EmotionEntry> _getEntriesForDay(DateTime day) {
    return _allEntries.where((entry) => isSameDay(entry.timestamp, day)).toList();
  }

  void _showRevisionDialog(EmotionEntry entry) {
    final latest = DatabaseService.getLatestState(entry);
    final currentEntryState = EmotionEntry(
      id: entry.id,
      timestamp: entry.timestamp,
      createdAt: entry.createdAt,
      tier1Emotion: latest['tier1'],
      tier2Emotion: latest['tier2'],
      tier3Emotion: latest['tier3'],
      intensity: latest['intensity'],
    );

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('View history'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EntryDetailScreen(entry: entry)),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('I made a mistake (Correction)'),
              subtitle: const Text('Fix a typo or a mis-tap.'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEmotionScreen(
                      selectedDate: entry.timestamp,
                      existingEntry: currentEntryState,
                      revisionType: RevisionType.correction,
                    ),
                  ),
                ).then((_) => _refreshData());
              },
            ),
            ListTile(
              leading: const Icon(Icons.psychology),
              title: const Text('I see this differently now (Reflection)'),
              subtitle: const Text('Re-interpret this moment with fresh eyes.'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEmotionScreen(
                      selectedDate: entry.timestamp,
                      existingEntry: currentEntryState,
                      revisionType: RevisionType.reflection,
                    ),
                  ),
                ).then((_) => _refreshData());
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _onAddButtonPressed() async {
    if (_selectedDay == null) return;

    // Mindful Check: Prompt user if adding an entry for any day that is NOT today.
    final bool isToday = isSameDay(_selectedDay, DateTime.now());

    if (!isToday) {
      final bool? proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reflecting on the past?'),
          content: const Text(
            'You are adding a new entry for a past date. Is this a new emotional moment you remembered?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, add entry'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEmotionScreen(selectedDate: _selectedDay!),
      ),
    );
    _refreshData();
  }

  Widget _buildDayCell(DateTime day, {bool isSelected = false, bool isToday = false, bool isOutside = false}) {
    final dayEntries = _getEntriesForDay(day);
    dayEntries.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (dayEntries.isNotEmpty)
            CustomPaint(
              size: const Size(42, 42),
              painter: EmotionPiePainter(
                segments: dayEntries.map((e) {
                  final latest = DatabaseService.getLatestState(e);
                  return PieSegment(
                    color: EmotionData.getColor(latest['tier1']),
                    intensity: latest['intensity'],
                  );
                }).toList(),
              ),
            ),
          Container(
            decoration: isSelected 
                ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black54, width: 2))
                : null,
            padding: const EdgeInsets.all(6),
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: isOutside ? Colors.grey : (dayEntries.isNotEmpty ? Colors.black : (isToday ? Colors.blue : Colors.black87)),
                fontWeight: isToday || isSelected || dayEntries.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDayEntries = _selectedDay != null ? _getEntriesForDay(_selectedDay!) : <EmotionEntry>[];
    selectedDayEntries.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Emotions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              _refreshData();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(DateTime.now().year - 2, 1, 1),
            lastDay: DateTime.now(),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) => _buildDayCell(day),
              todayBuilder: (context, day, focusedDay) => _buildDayCell(day, isToday: true),
              selectedBuilder: (context, day, focusedDay) => _buildDayCell(day, isSelected: true),
              outsideBuilder: (context, day, focusedDay) => _buildDayCell(day, isOutside: true),
            ),
          ),
          const Divider(),
          if (_selectedDay != null)
            Expanded(
              child: selectedDayEntries.isEmpty
                  ? const Center(child: Text('No entries for this day.'))
                  : ListView.builder(
                itemCount: selectedDayEntries.length,
                itemBuilder: (context, index) {
                  final entry = selectedDayEntries[index];
                  final latest = DatabaseService.getLatestState(entry);
                  final color = EmotionData.getColor(latest['tier1']);
                  
                  return Dismissible(
                    key: Key(entry.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) async {
                      await DatabaseService.deleteEntry(entry.id);
                      _refreshData();
                    },
                    child: ListTile(
                      onTap: () => _showRevisionDialog(entry),
                      leading: CircleAvatar(
                        backgroundColor: color,
                        child: Text(
                          latest['intensity'].toString(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(latest['tier1']),
                          if (latest['hasRevisions']) ...[
                            const SizedBox(width: 8),
                            Icon(
                              latest['latestType'] == RevisionType.correction ? Icons.edit_note : Icons.psychology,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text('${latest['tier2'] ?? ""} ${latest['tier3'] != null ? "• ${latest['tier3']}" : ""}'),
                      trailing: Text(
                        '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: _selectedDay != null
          ? FloatingActionButton(
        onPressed: _onAddButtonPressed,
        tooltip: 'Add Emotion',
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}

class PieSegment {
  final Color color;
  final int intensity;
  PieSegment({required this.color, required this.intensity});
}

class EmotionPiePainter extends CustomPainter {
  final List<PieSegment> segments;

  EmotionPiePainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    if (segments.isEmpty) return;

    final sweepAngle = (2 * math.pi) / segments.length;
    double startAngle = -math.pi / 2;

    for (final segment in segments) {
      final double opacity = 0.25 + (segment.intensity * 0.25);
      paint.color = segment.color.withOpacity(opacity);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }

    if (segments.length > 1) {
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
