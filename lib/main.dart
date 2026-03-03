import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/settings_service.dart';
import 'services/reminder_service.dart';
import 'features/home/home_screen.dart';

void main() async {
  // Ensure Flutter is initialized before calling any services
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize our local database and settings
  await DatabaseService.init();
  await SettingsService.init();
  await ReminderService.init();

  runApp(const EmotionTrackerApp());
}

class EmotionTrackerApp extends StatelessWidget {
  const EmotionTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emotion Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
        // Make our app bar look a bit cleaner
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
