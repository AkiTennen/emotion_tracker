import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/settings_service.dart';
import 'services/reminder_service.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

/// Application entry point. Initializes framework bindings, local storage,
/// and scheduled notification services before launching the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent Hive boxes and reminder notifications
  await DatabaseService.init();
  await SettingsService.init();
  await ReminderService.init();

  runApp(const EmotionTrackerApp());
}

/// Root application widget that configures Material 3 theming, routing,
/// and manages dynamic theme and onboarding state.
class EmotionTrackerApp extends StatefulWidget {
  const EmotionTrackerApp({super.key});

  /// Allows descendant widgets to access and trigger root app state changes.
  static _EmotionTrackerAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_EmotionTrackerAppState>()!;

  @override
  State<EmotionTrackerApp> createState() => _EmotionTrackerAppState();
}

class _EmotionTrackerAppState extends State<EmotionTrackerApp> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _themeMode = SettingsService.getThemeMode();
    _showOnboarding = !SettingsService.isOnboardingShown();
  }

  /// Reloads the user's selected theme mode from [SettingsService].
  void updateThemeMode() {
    setState(() {
      _themeMode = SettingsService.getThemeMode();
    });
  }

  /// Re-evaluates whether the onboarding flow should be displayed.
  void refreshOnboardingState() {
    setState(() {
      _showOnboarding = !SettingsService.isOnboardingShown();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emotion Tracker',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: _showOnboarding
          ? OnboardingScreen(
              onFinish: () {
                setState(() {
                  _showOnboarding = false;
                });
              },
            )
          : const HomeScreen(),
    );
  }
}
