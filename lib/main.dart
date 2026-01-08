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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5), // Electric Blue
          secondary: const Color(0xFFFF6B6B), // Vibrant Coral
          tertiary: const Color(0xFF00E676), // Neon Lime
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1E88E5),
          foregroundColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5), // Electric Blue
          secondary: const Color(0xFFFF6B6B), // Vibrant Coral
          tertiary: const Color(0xFF00E676), // Neon Lime
          brightness: Brightness.dark,
          surface: const Color(0xFF132F4C), // Dark Navy surface
          background: const Color(0xFF0A1929), // Darker Navy background
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A1929),
        cardTheme: const CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          color: Color(0xFF132F4C),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1E88E5),
          foregroundColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF132F4C),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      themeMode: ThemeMode.system, // Respect system theme preference
      home: const HomeScreen(),
    );
  }
}
