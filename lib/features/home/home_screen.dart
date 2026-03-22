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
import '../../main.dart';
import 'entry_detail_screen.dart';
import 'journal_editor_screen.dart';
import 'journal_detail_screen.dart';
import 'journal_read_screen.dart';

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
  bool _showFirstEntryHint = false;
  bool _showEntryTapHint = false;
  bool _showJournalHighlight = false;

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
      _showFirstEntryHint = !SettingsService.isFirstEntryHintShown() && _allEntries.isEmpty;
      _showEntryTapHint = !SettingsService.isEntryTapHintShown() && _allEntries.length == 1 && !_showFirstEntryHint;
      _showJournalHighlight = SettingsService.isJournalHighlightPending() && SettingsService.isJournalEnabled();
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

    if (!SettingsService.isEntryTapHintShown()) {
      SettingsService.setEntryTapHintShown(true);
      setState(() => _showEntryTapHint = false);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!SettingsService.isRevisionTypesHintShown())
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_stories_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Refining your story', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _RevisionInfoRow(
                      icon: Icons.edit_note,
                      title: 'Correction ("I made a mistake")',
                      description: 'Use this for input errors like typos or the wrong emotion. It\'s for fixing the past.',
                    ),
                    _RevisionInfoRow(
                      icon: Icons.psychology,
                      title: 'Reflection ("I see this differently")',
                      description: 'Use this for emotional growth. Look back with new eyes and add a new layer without erasing the original.',
                    ),
                    _RevisionInfoRow(
                      icon: Icons.history,
                      title: 'Preservation (History)',
                      description: 'Your safety net. Nothing is ever overwritten; we just add new chapters to this moment\'s story.',
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () async {
                          await SettingsService.setRevisionTypesHintShown(true);
                          if (mounted) Navigator.pop(context);
                          _showRevisionDialog(entry);
                        },
                        child: const Text('Got it'),
                      ),
                    ),
                  ],
                ),
              ),
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
              leading: const Icon(Icons.menu_book),
              title: const Text('Read entry'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => JournalReadScreen(journal: journal)),
                );
              },
            ),
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
    final bool isFirstEver = _allEntries.isEmpty && !SettingsService.isFirstEntryHintShown();

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
    
    if (isFirstEver && _allEntries.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Well done! You\'ve taken the first step in your journey.'),
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
    bool highlight = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(highlight ? 0.2 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(highlight ? 0.8 : 0.2), width: highlight ? 2 : 1),
          boxShadow: highlight ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)] : null,
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                ? BoxDecoration(
                    shape: BoxShape.circle, 
                    border: Border.all(color: isDark ? Colors.white54 : Colors.black54, width: 2)
                  )
                : null,
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isOutside 
                        ? Theme.of(context).disabledColor 
                        : (dayEntries.isNotEmpty 
                            ? (isDark ? Colors.white : Colors.black) 
                            : (isToday ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyLarge?.color)),
                    fontWeight: isToday || isSelected || dayEntries.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
                if (dayJournals.isNotEmpty)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
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
    
    final List<dynamic> combinedItems = [...selectedDayEntries, ...selectedDayJournals];
    combinedItems.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final bool isTodaySelected = _selectedDay != null && isSameDay(_selectedDay, DateTime.now());
    final String dateFormatString = SettingsService.getDateFormat();
    final int firstDayOfWeekValue = SettingsService.getFirstDayOfWeek();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emotion Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    onThemeChanged: () {
                      EmotionTrackerApp.of(context).updateThemeMode();
                    },
                  ),
                ),
              );
              _refreshData();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTodaySelected 
                        ? "How are you feeling right now?" 
                        : "Reviewing ${DateFormat(dateFormatString).format(_selectedDay!)}",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).hintColor,
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
                            color: Theme.of(context).colorScheme.primary,
                            onTap: () => _openAddEmotionScreen(),
                            highlight: _showFirstEntryHint,
                          ),
                        ),
                        if (SettingsService.isJournalEnabled()) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionCard(
                              context,
                              icon: Icons.edit_note_outlined,
                              label: "Write Journal",
                              color: Theme.of(context).colorScheme.secondary,
                              onTap: () => _openJournalEditor(),
                              highlight: _showJournalHighlight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Calendar",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).hintColor,
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
                startingDayOfWeek: firstDayOfWeekValue == 1 ? StartingDayOfWeek.monday : StartingDayOfWeek.sunday,
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
                  leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).hintColor, size: 20),
                  rightChevronIcon: Icon(Icons.chevron_right, color: Theme.of(context).hintColor, size: 20),
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
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  isTodaySelected ? "Today so far" : "Your journey on ${DateFormat(dateFormatString).format(_selectedDay!)}",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              if (_selectedDay != null)
                Expanded(
                  child: combinedItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wb_sunny_outlined, size: 48, color: Theme.of(context).disabledColor.withOpacity(0.2)),
                              const SizedBox(height: 16),
                              Text(
                                'No entries yet.',
                                style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 16),
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
                                side: BorderSide(color: _showEntryTapHint ? Theme.of(context).colorScheme.primary.withOpacity(0.8) : Theme.of(context).dividerColor.withOpacity(0.1), width: _showEntryTapHint ? 2 : 1),
                              ),
                              child: ListTile(
                                onTap: () => _showRevisionDialog(item),
                                leading: CircleAvatar(
                                  backgroundColor: color.withOpacity(opacity),
                                  child: Text(
                                    intensity.toString(),
                                    style: TextStyle(
                                      color: opacity > 0.6 ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
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
                                        color: Theme.of(context).hintColor,
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
                                  style: TextStyle(color: Theme.of(context).hintColor),
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
                                side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                  child: Icon(Icons.book, color: Theme.of(context).colorScheme.onSecondaryContainer, size: 18),
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
                                        color: Theme.of(context).hintColor,
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  latest['content'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Theme.of(context).hintColor),
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
          if (_showFirstEntryHint)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showFirstEntryHint = false),
                child: Container(
                  color: Colors.black.withOpacity(0.85), 
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_upward, color: Colors.white, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            "Let's start your journey.",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "How are you feeling right now?\nTap 'Log Emotion' to record your first moment.",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 40),
                          OutlinedButton(
                            onPressed: () => setState(() => _showFirstEntryHint = false),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                            child: const Text("Got it"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_showJournalHighlight)
            Positioned.fill(
              child: GestureDetector(
                onTap: () async {
                  await SettingsService.setJournalHighlightPending(false);
                  setState(() => _showJournalHighlight = false);
                },
                child: Container(
                  color: Colors.black.withOpacity(0.85),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_stories, color: Colors.white, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            "Your Journal is ready.",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Use it to record long-form reflections whenever you need more space than a single emotion provides.",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 40),
                          ElevatedButton(
                            onPressed: () async {
                              await SettingsService.setJournalHighlightPending(false);
                              setState(() => _showJournalHighlight = false);
                            },
                            child: const Text("Got it"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_showEntryTapHint)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    Icon(Icons.touch_app, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "Your entry is just the beginning. Tap it to refine or reflect on this moment later.",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () async {
                        await SettingsService.setEntryTapHintShown(true);
                        setState(() => _showEntryTapHint = false);
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RevisionInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _RevisionInfoRow({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
              ],
            ),
          ),
        ],
      ),
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
