import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable wakelock by default to prevent screen from sleeping during workouts
  WakelockPlus.enable();

  // Initialize notifications
  await NotificationService().initialize();

  // Initialize audio service
  await AudioService().initialize();

  runApp(const CrosswatchApp());
}

class CrosswatchApp extends StatelessWidget {
  const CrosswatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crosswatch',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
