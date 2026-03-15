import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/emotion_entry.dart';
import '../../models/journal_entry.dart';
import '../../models/journal_revision.dart';
import '../../models/emotion_entry_revision.dart';
import '../../services/database_service.dart';
import '../../models/emotion_data.dart';

class JournalEditorScreen extends StatefulWidget {
  final DateTime selectedDate;
  final JournalEntry? existingJournal;
  final RevisionType? revisionType;

  const JournalEditorScreen({
    super.key,
    required this.selectedDate,
    this.existingJournal,
    this.revisionType,
  });

  @override
  State<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _reflectionController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  List<EmotionEntry> _dayEntries = [];
  String _previousContent = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _dayEntries = DatabaseService.getAllEntries()
        .where((e) => isSameDay(e.timestamp, widget.selectedDate))
        .toList();
    
    if (widget.existingJournal != null) {
      final latest = DatabaseService.getLatestJournalState(widget.existingJournal!);
      if (widget.revisionType == RevisionType.addition) {
        _previousContent = latest['content'];
        _contentController.clear();
      } else {
        _contentController.text = latest['content'];
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _reflectionController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _save() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    String finalContent = content;
    if (widget.revisionType == RevisionType.addition) {
      finalContent = '$_previousContent\n\n$content';
    }

    if (widget.existingJournal != null && widget.revisionType != null) {
      // Save Revision
      final revision = JournalRevision(
        journalId: widget.existingJournal!.id,
        revisionType: widget.revisionType!,
        content: finalContent,
        reflectionText: _reflectionController.text.trim(),
      );
      await DatabaseService.saveJournalRevision(revision);
    } else {
      // Save New Entry
      final now = DateTime.now();
      final journal = JournalEntry(
        id: const Uuid().v4(),
        timestamp: DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          widget.selectedDate.day,
          now.hour,
          now.minute,
          now.second,
        ),
        createdAt: now,
        content: finalContent,
      );
      await DatabaseService.saveJournal(journal);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Journal';
    if (widget.existingJournal != null) {
      if (widget.revisionType == RevisionType.correction) title = 'Correcting Journal';
      if (widget.revisionType == RevisionType.reflection) title = 'Reflecting on Journal';
      if (widget.revisionType == RevisionType.addition) title = 'Adding to Journal';
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        children: [
          // REFERENCE HEADER
          if (_dayEntries.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: isDark ? Colors.grey[900] : Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Today\'s Emotions', 
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      color: Theme.of(context).hintColor
                    )
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dayEntries.map((e) {
                      final latest = DatabaseService.getLatestState(e);
                      final emotionColor = EmotionData.getColor(latest['tier1']);
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
                          latest['tier1'],
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
              ),
            ),
          
          if (widget.revisionType == RevisionType.reflection)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _reflectionController,
                decoration: const InputDecoration(
                  labelText: 'Why are you revising this?',
                  border: OutlineInputBorder(),
                ),
              ),
            ),

          Expanded(
            child: GestureDetector(
              onTap: () => _contentFocusNode.requestFocus(),
              behavior: HitTestBehavior.opaque,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.revisionType == RevisionType.addition && _previousContent.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Text(
                          _previousContent,
                          style: TextStyle(
                            fontSize: 16, 
                            color: isDark ? Colors.grey[400] : Colors.grey[700], 
                            height: 1.4
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('New Addition:', 
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          color: Theme.of(context).colorScheme.primary
                        )
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: _contentController,
                      focusNode: _contentFocusNode,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: widget.revisionType == RevisionType.addition ? 'Add more thoughts...' : 'Write your thoughts here...',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 18, height: 1.5),
                      autofocus: widget.revisionType == RevisionType.addition,
                    ),
                    const SizedBox(height: 200),
                  ],
                ),
              ),
            ),
          ),
          
          // BOTTOM SAVE BUTTON
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(widget.existingJournal == null ? 'Save Journal Entry' : 'Save Revision'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
