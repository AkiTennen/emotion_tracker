import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/journal_entry.dart';
import '../../models/journal_revision.dart';
import '../../models/emotion_entry_revision.dart';
import '../../services/database_service.dart';
import '../../services/settings_service.dart';

class JournalDetailScreen extends StatelessWidget {
  final JournalEntry journal;

  const JournalDetailScreen({super.key, required this.journal});

  @override
  Widget build(BuildContext context) {
    final revisions = DatabaseService.getRevisionsForJournal(journal.id);
    final dateFormat = SettingsService.getDateFormat();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal History'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildJournalTimelineTile(
              context,
              title: 'Original Moment',
              timestamp: journal.createdAt,
              content: journal.content,
              isOriginal: true,
              dateFormat: dateFormat,
            ),
            ...revisions.map((rev) => _buildJournalTimelineTile(
              context,
              title: _getTitle(rev.revisionType),
              timestamp: rev.timestamp,
              content: rev.content,
              note: rev.reflectionText,
              icon: _getIcon(rev.revisionType),
              dateFormat: dateFormat,
            )),
          ],
        ),
      ),
    );
  }

  String _getTitle(RevisionType type) {
    switch (type) {
      case RevisionType.correction: return 'Correction';
      case RevisionType.reflection: return 'Reflection';
      case RevisionType.addition: return 'Addition';
    }
  }

  IconData _getIcon(RevisionType type) {
    switch (type) {
      case RevisionType.correction: return Icons.edit_note;
      case RevisionType.reflection: return Icons.psychology;
      case RevisionType.addition: return Icons.add;
    }
  }

  Widget _buildJournalTimelineTile(
    BuildContext context, {
    required String title,
    required DateTime timestamp,
    required String content,
    required String dateFormat,
    String? note,
    bool isOriginal = false,
    IconData? icon,
  }) {
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
                  color: Theme.of(context).colorScheme.primary,
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
                const SizedBox(height: 4),
                Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (note != null && note.isNotEmpty) ...[
                          Text(
                            note,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                          ),
                          const Divider(),
                        ],
                        Text(
                          content,
                          style: const TextStyle(fontSize: 16, height: 1.4),
                        ),
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
