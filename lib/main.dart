import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'features/home/home_screen.dart';

void main() async {
  // 1. Ensure Flutter is fully initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize our Hive Database Service
  // This opens the storage boxes so the app is ready to read/write
  await DatabaseService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emotion Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true, // Corrected from useMaterialDesign
      ),
      home: const HomeScreen(),
    );
  }
}
