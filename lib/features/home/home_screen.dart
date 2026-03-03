import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:math' as math;
import '../../models/emotion_data.dart';
import '../../models/emotion_entry.dart';
import '../../services/database_service.dart';
import '../add_emotion/add_emotion_screen.dart';

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
                segments: dayEntries.map((e) => PieSegment(
                  color: EmotionData.getColor(e.tier1Emotion),
                  intensity: e.intensity,
                )).toList(),
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
                  final color = EmotionData.getColor(entry.tier1Emotion);
                  
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
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Entry deleted')),
                        );
                      }
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color,
                        child: Text(
                          entry.intensity.toString(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(entry.tier1Emotion),
                      subtitle: Text('${entry.tier2Emotion ?? ""} ${entry.tier3Emotion != null ? "• ${entry.tier3Emotion}" : ""}'),
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
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEmotionScreen(selectedDate: _selectedDay!),
            ),
          );
          _refreshData();
        },
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
