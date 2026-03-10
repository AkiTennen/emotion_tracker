import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../../models/emotion_data.dart';
import '../../models/emotion_entry.dart';
import '../../models/emotion_entry_revision.dart';
import '../../models/journal_entry.dart';
import '../../models/journal_revision.dart';
import '../../services/database_service.dart';
import '../../services/settings_service.dart';
import '../add_emotion/add_emotion_screen.dart';
import '../settings/settings_screen.dart';
import 'entry_detail_screen.dart';
import 'journal_editor_screen.dart';
import 'journal_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  List<EmotionEntry> _allEntries = [];
  List<JournalEntry> _allJournals = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _allEntries = DatabaseService.getAllEntries();
      _allJournals = DatabaseService.getAllJournals();
    });
  }

  List<EmotionEntry> _getEntriesForDay(DateTime day) {
    return _allEntries.where((entry) => isSameDay(entry.timestamp, day)).toList();
  }

  List<JournalEntry> _getJournalsForDay(DateTime day) {
    return _allJournals.where((journal) => isSameDay(journal.timestamp, day)).toList();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
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
      bodyMapData: latest['bodyMapData'],
      trigger: latest['trigger'],
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

  void _showJournalRevisionDialog(JournalEntry journal) {
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
                  MaterialPageRoute(builder: (context) => JournalDetailScreen(journal: journal)),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add information'),
              subtitle: const Text('Keep the original and add something new.'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JournalEditorScreen(
                      selectedDate: journal.timestamp,
                      existingJournal: journal,
                      revisionType: RevisionType.addition,
                    ),
                  ),
                ).then((_) => _refreshData());
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('I made a mistake (Correction)'),
              subtitle: const Text('Fix a typo.'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JournalEditorScreen(
                      selectedDate: journal.timestamp,
                      existingJournal: journal,
                      revisionType: RevisionType.correction,
                    ),
                  ),
                ).then((_) => _refreshData());
              },
            ),
            ListTile(
              leading: const Icon(Icons.psychology),
              title: const Text('I see this differently now (Reflection)'),
              subtitle: const Text('Re-interpret your day.'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JournalEditorScreen(
                      selectedDate: journal.timestamp,
                      existingJournal: journal,
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

    if (SettingsService.isJournalEnabled()) {
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.face),
                title: const Text('Log Emotion'),
                onTap: () {
                  Navigator.pop(context);
                  _openAddEmotionScreen();
                },
              ),
              ListTile(
                leading: const Icon(Icons.book),
                title: const Text('Write Journal'),
                onTap: () {
                  Navigator.pop(context);
                  _openJournalEditor();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    } else {
      _openAddEmotionScreen();
    }
  }

  Future<void> _openAddEmotionScreen() async {
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

  Future<void> _openJournalEditor() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalEditorScreen(selectedDate: _selectedDay!),
      ),
    );
    _refreshData();
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day, {bool isSelected = false, bool isToday = false, bool isOutside = false}) {
    final dayEntries = _getEntriesForDay(day);
    dayEntries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final dayJournals = _getJournalsForDay(day);

    bool hasTrigger = false;
    for (var e in dayEntries) {
      final latest = DatabaseService.getLatestState(e);
      if (latest['trigger'] != null && (latest['trigger'] as String).isNotEmpty) {
        hasTrigger = true;
        break;
      }
    }

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (dayEntries.isNotEmpty)
            CustomPaint(
              size: const Size(36, 36),
              painter: EmotionPiePainter(
                segments: dayEntries.map((e) {
                  final latest = DatabaseService.getLatestState(e);
                  return PieSegment(
                    color: EmotionData.getColor(latest['tier1']),
                    intensity: latest['intensity'],
                  );
                }).toList(),
                hasTrigger: hasTrigger,
              ),
            ),
          Container(
            decoration: isSelected 
                ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black54, width: 2))
                : null,
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isOutside ? Colors.grey : (dayEntries.isNotEmpty ? Colors.black : (isToday ? Colors.blue : Colors.black87)),
                    fontWeight: isToday || isSelected || dayEntries.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
                if (dayJournals.isNotEmpty)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.blueGrey,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDayEntries = _selectedDay != null ? _getEntriesForDay(_selectedDay!) : <EmotionEntry>[];
    final selectedDayJournals = _selectedDay != null ? _getJournalsForDay(_selectedDay!) : <JournalEntry>[];
    
    // Combined list for display
    final List<dynamic> combinedItems = [...selectedDayEntries, ...selectedDayJournals];
    combinedItems.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final bool isTodaySelected = _selectedDay != null && isSameDay(_selectedDay, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emotion Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Right Now" Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isTodaySelected 
                    ? "How are you feeling right now?" 
                    : "Reviewing ${DateFormat('MMMM d').format(_selectedDay!)}",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        icon: Icons.add_reaction_outlined,
                        label: "Log Emotion",
                        color: Colors.indigo,
                        onTap: () => _openAddEmotionScreen(),
                      ),
                    ),
                    if (SettingsService.isJournalEnabled()) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          icon: Icons.edit_note_outlined,
                          label: "Write Journal",
                          color: Colors.blueGrey,
                          onTap: () => _openJournalEditor(),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Timeline Header (Month Toggle)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Calendar",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _calendarFormat = _calendarFormat == CalendarFormat.week
                          ? CalendarFormat.month
                          : CalendarFormat.week;
                    });
                  },
                  icon: Icon(
                    _calendarFormat == CalendarFormat.week
                        ? Icons.calendar_month_outlined
                        : Icons.keyboard_arrow_up,
                    size: 16,
                  ),
                  label: Text(
                    _calendarFormat == CalendarFormat.week ? "Show Month" : "Show Week",
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          TableCalendar(
            firstDay: DateTime.utc(DateTime.now().year - 2, 1, 1),
            lastDay: DateTime.now(),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              headerPadding: const EdgeInsets.symmetric(vertical: 4.0),
              titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.grey[400], size: 20),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) => _buildDayCell(day),
              todayBuilder: (context, day, focusedDay) => _buildDayCell(day, isToday: true),
              selectedBuilder: (context, day, focusedDay) => _buildDayCell(day, isSelected: true),
              outsideBuilder: (context, day, focusedDay) => _buildDayCell(day, isOutside: true),
            ),
            daysOfWeekHeight: 20,
            rowHeight: 48,
          ),
          
          const SizedBox(height: 24),
          
          // Timeline Detail Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              isTodaySelected ? "Today so far" : "Your journey on ${DateFormat('MMM d').format(_selectedDay!)}",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          if (_selectedDay != null)
            Expanded(
              child: combinedItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wb_sunny_outlined, size: 48, color: Colors.grey[200]),
                          const SizedBox(height: 16),
                          Text(
                            'No entries yet.',
                            style: TextStyle(color: Colors.grey[400], fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                itemCount: combinedItems.length,
                itemBuilder: (context, index) {
                  final item = combinedItems[index];
                  
                  if (item is EmotionEntry) {
                    final latest = DatabaseService.getLatestState(item);
                    final color = EmotionData.getColor(latest['tier1']);
                    final intensity = latest['intensity'] as int;
                    final double opacity = 0.25 + (intensity * 0.25);
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) async {
                          await DatabaseService.deleteEntry(item.id);
                          _refreshData();
                        },
                        child: Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.withOpacity(0.1)),
                          ),
                          child: ListTile(
                            onTap: () => _showRevisionDialog(item),
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(opacity),
                              child: Text(
                                intensity.toString(),
                                style: TextStyle(
                                  color: opacity > 0.6 ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  latest['tier1'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (latest['hasRevisions']) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    latest['latestType'] == RevisionType.correction ? Icons.edit_note : Icons.psychology,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ],
                                if (latest['trigger'] != null && (latest['trigger'] as String).isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.bolt, size: 14, color: Colors.orange),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              '${latest['tier2'] ?? ""} ${latest['tier3'] != null ? "• ${latest['tier3']}" : ""}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: Text(
                              DateFormat('HH:mm').format(item.timestamp),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                      ),
                    );
                  } else if (item is JournalEntry) {
                    final latest = DatabaseService.getLatestJournalState(item);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) async {
                          await DatabaseService.deleteJournal(item.id);
                          _refreshData();
                        },
                        child: Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.withOpacity(0.1)),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blueGrey,
                              child: Icon(Icons.book, color: Colors.white, size: 18),
                            ),
                            title: Row(
                              children: [
                                const Text(
                                  'Journal Entry',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (latest['hasRevisions']) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    latest['latestType'] == RevisionType.correction ? Icons.edit_note : (latest['latestType'] == RevisionType.reflection ? Icons.psychology : Icons.add),
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              latest['content'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: Text(
                              DateFormat('HH:mm').format(item.timestamp),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            onTap: () => _showJournalRevisionDialog(item),
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
        ],
      ),
      floatingActionButton: _selectedDay != null
          ? FloatingActionButton(
        onPressed: _onAddButtonPressed,
        tooltip: 'Add',
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
  final bool hasTrigger;

  EmotionPiePainter({required this.segments, this.hasTrigger = false});

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

    if (hasTrigger) {
      final triggerPaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, radius + 2, triggerPaint);
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
  bool shouldRepaint(covariant EmotionPiePainter oldDelegate) => true;
}
