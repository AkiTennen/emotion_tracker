import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'database_service.dart';
import 'settings_service.dart';

class BackupService {
  static const int currentBackupVersion = 1;

  /// Bundles all database data into a single JSON map.
  static Future<Map<String, dynamic>> _createDataBundle() async {
    final Map<String, dynamic> bundle = {
      'metadata': {
        'version': currentBackupVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'app_name': 'Emotion Tracker',
      },
      'data': {
        'emotion_entries': Hive.box(DatabaseService.entriesBoxName).values.toList(),
        'emotion_revisions': Hive.box(DatabaseService.revisionsBoxName).values.toList(),
        'journals': Hive.box(DatabaseService.journalsBoxName).values.toList(),
        'journal_revisions': Hive.box(DatabaseService.journalRevisionsBoxName).values.toList(),
        'custom_emotions': Map.fromEntries(
          Hive.box(DatabaseService.customEmotionsBoxName).keys.map(
            (key) => MapEntry(key.toString(), Hive.box(DatabaseService.customEmotionsBoxName).get(key))
          )
        ),
        'settings': Map.fromEntries(
          Hive.box(SettingsService.settingsBoxName).keys.map(
            (key) => MapEntry(key.toString(), Hive.box(SettingsService.settingsBoxName).get(key))
          )
        ),
      }
    };
    return bundle;
  }

  /// Exports the data bundle to a JSON file. 
  static Future<void> exportBackup() async {
    try {
      final bundle = await _createDataBundle();
      final jsonString = jsonEncode(bundle);
      final Uint8List bytes = utf8.encode(jsonString); // Convert string to bytes
      
      final dateStr = DateFormat('yyyy_MM_dd_HHmm').format(DateTime.now());
      final fileName = 'emotion_tracker_backup_$dateStr.json';

      // 1. Try letting the user pick a save location
      // Note: On Android/iOS, providing 'bytes' is mandatory for this method.
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Select where to save your backup',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      // On mobile, if outputPath is not null, the plugin has already saved the file using the bytes provided.
      if (outputPath == null) {
        // User cancelled the "Save As" dialog. We can optionally fall back to Share if preferred,
        // but usually, a cancel means the user changed their mind.
        // For now, we'll do nothing on cancel to stay "calm".
      }
    } catch (e) {
      // If saveFile is not supported on this platform/version, fallback to Share.
      final directory = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyy_MM_dd_HHmm').format(DateTime.now());
      final filePath = '${directory.path}/emotion_tracker_backup_$dateStr.json';
      final file = File(filePath);
      await file.writeAsString(jsonEncode(await _createDataBundle()));
      
      await Share.shareXFiles([XFile(filePath)], text: 'Emotion Tracker Data Backup');
    }
  }

  /// Opens a file picker, reads the JSON backup, and restores the database.
  static Future<bool> importBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return false;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final Map<String, dynamic> bundle = jsonDecode(jsonString);

      if (bundle['metadata'] == null || bundle['metadata']['app_name'] != 'Emotion Tracker') {
        throw Exception('Invalid backup file');
      }

      final data = bundle['data'] as Map<String, dynamic>;

      await _clearAllData();

      // Restore Emotions
      final entriesBox = Hive.box(DatabaseService.entriesBoxName);
      final entries = data['emotion_entries'] as List;
      for (var entry in entries) {
        final map = Map<String, dynamic>.from(entry as Map);
        await entriesBox.put(map['id'], map);
      }

      // Restore Emotion Revisions
      final revBox = Hive.box(DatabaseService.revisionsBoxName);
      final revs = data['emotion_revisions'] as List;
      for (var rev in revs) {
        await revBox.add(Map<String, dynamic>.from(rev as Map));
      }

      // Restore Journals
      final journalBox = Hive.box(DatabaseService.journalsBoxName);
      final journals = data['journals'] as List;
      for (var j in journals) {
        final map = Map<String, dynamic>.from(j as Map);
        await journalBox.put(map['id'], map);
      }

      // Restore Journal Revisions
      final journalRevBox = Hive.box(DatabaseService.journalRevisionsBoxName);
      final jRevs = data['journal_revisions'] as List;
      for (var jr in jRevs) {
        await journalRevBox.add(Map<String, dynamic>.from(jr as Map));
      }

      // Restore Custom Emotions
      final customBox = Hive.box(DatabaseService.customEmotionsBoxName);
      final customEmotions = data['custom_emotions'] as Map;
      for (var key in customEmotions.keys) {
        await customBox.put(key, customEmotions[key]);
      }

      // Restore Settings
      final settingsBox = Hive.box(SettingsService.settingsBoxName);
      final settings = data['settings'] as Map;
      for (var key in settings.keys) {
        await settingsBox.put(key, settings[key]);
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> _clearAllData() async {
    await Hive.box(DatabaseService.entriesBoxName).clear();
    await Hive.box(DatabaseService.revisionsBoxName).clear();
    await Hive.box(DatabaseService.journalsBoxName).clear();
    await Hive.box(DatabaseService.journalRevisionsBoxName).clear();
    await Hive.box(DatabaseService.customEmotionsBoxName).clear();
    await Hive.box(SettingsService.settingsBoxName).clear();
  }
}
