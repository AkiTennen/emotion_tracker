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

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Column(
        children: [
          // REFERENCE HEADER
          if (_dayEntries.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Today\'s Emotions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: _dayEntries.map((e) {
                      final latest = DatabaseService.getLatestState(e);
                      return Chip(
                        label: Text(latest['tier1'], style: const TextStyle(fontSize: 10)),
                        backgroundColor: EmotionData.getColor(latest['tier1']).withOpacity(0.1),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.revisionType == RevisionType.addition && _previousContent.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        _previousContent,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('New Addition:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const SizedBox(height: 8),
                  ],
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: widget.revisionType == RevisionType.addition ? 'Add more thoughts...' : 'Write your thoughts here...',
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 18, height: 1.5),
                    autofocus: widget.revisionType == RevisionType.addition,
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
