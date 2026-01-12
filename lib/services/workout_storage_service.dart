import 'dart:io' if (dart.library.html) 'platform_stub.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout.dart';

class WorkoutStorageService {
  static final WorkoutStorageService _instance =
      WorkoutStorageService._internal();
  factory WorkoutStorageService() => _instance;
  WorkoutStorageService._internal();

  static const String _webStorageKey = 'user_workouts';

  Future<Directory> get _workoutsDirectory async {
    if (kIsWeb) {
      // On web, we can't use file system, so we'll use browser storage
      // For now, throw an error - we'll handle this separately
      throw UnsupportedError('File system not available on web');
    }

    final appDir = await getApplicationDocumentsDirectory();
    final workoutsDir = Directory('${appDir.path}/crosswatch/workouts');
    if (!await workoutsDir.exists()) {
      await workoutsDir.create(recursive: true);
    }
    return workoutsDir;
  }

  /// Load all available workouts (both from assets and user directory)
  Future<List<Workout>> loadAllWorkouts() async {
    final workouts = <Workout>[];

    // Load built-in workouts from assets (hardcoded list)
    final builtInWorkouts = [
      'assets/workouts/example.json',
      'assets/workouts/beginner-friendly.json',
      'assets/workouts/cindy-crossfit-wod.json',
    ];

    for (final path in builtInWorkouts) {
      try {
        final jsonString = await rootBundle.loadString(path);
        final workout = Workout.fromJson(json.decode(jsonString));
        workouts.add(workout);
      } catch (e) {
        print('Failed to load workout from $path: $e');
      }
    }

    // Load user workouts from storage
    if (kIsWeb) {
      // Load from localStorage on web
      try {
        final prefs = await SharedPreferences.getInstance();
        final workoutsJson = prefs.getStringList(_webStorageKey) ?? [];

        for (final jsonString in workoutsJson) {
          try {
            final workout = Workout.fromJson(json.decode(jsonString));
            workouts.add(workout);
          } catch (e) {
            print('Failed to parse workout from localStorage: $e');
          }
        }
      } catch (e) {
        print('Failed to load user workouts from web storage: $e');
      }
    } else {
      // Load from file system on native platforms
      try {
        final dir = await _workoutsDirectory;
        final files = dir
            .listSync()
            .where((entity) => entity is File && entity.path.endsWith('.json'))
            .cast<File>();

        for (final file in files) {
          try {
            final jsonString = await file.readAsString();
            final workout = Workout.fromJson(json.decode(jsonString));
            workouts.add(workout);
          } catch (e) {
            print('Failed to load workout from ${file.path}: $e');
          }
        }
      } catch (e) {
        print('Failed to load user workouts: $e');
      }
    }

    return workouts;
  }

  /// Save a workout to the user directory
  Future<void> saveWorkout(Workout workout) async {
    if (kIsWeb) {
      // Save to localStorage on web
      try {
        final prefs = await SharedPreferences.getInstance();
        final workoutsJson = prefs.getStringList(_webStorageKey) ?? [];

        // Check if workout already exists (by name)
        final existingIndex = workoutsJson.indexWhere((jsonString) {
          try {
            final existingWorkout = Workout.fromJson(json.decode(jsonString));
            return existingWorkout.name == workout.name;
          } catch (e) {
            return false;
          }
        });

        final workoutJson = json.encode(workout.toJson());

        if (existingIndex >= 0) {
          // Update existing workout
          workoutsJson[existingIndex] = workoutJson;
        } else {
          // Add new workout
          workoutsJson.add(workoutJson);
        }

        await prefs.setStringList(_webStorageKey, workoutsJson);
        print('Workout saved to web storage: ${workout.name}');
      } catch (e) {
        print('Failed to save workout to web storage: $e');
        rethrow;
      }
      return;
    }

    final dir = await _workoutsDirectory;
    final fileName = _sanitizeFileName(workout.name);
    final file = File('${dir.path}/$fileName.json');

    final jsonString = json.encode(workout.toJson());
    await file.writeAsString(jsonString);
  }

  /// Delete a workout from the user directory
  Future<bool> deleteWorkout(String workoutName) async {
    if (kIsWeb) {
      // Delete from localStorage on web
      try {
        final prefs = await SharedPreferences.getInstance();
        final workoutsJson = prefs.getStringList(_webStorageKey) ?? [];

        // Find and remove the workout
        final updatedWorkouts = workoutsJson.where((jsonString) {
          try {
            final workout = Workout.fromJson(json.decode(jsonString));
            return workout.name != workoutName;
          } catch (e) {
            return true; // Keep malformed entries for now
          }
        }).toList();

        if (updatedWorkouts.length < workoutsJson.length) {
          await prefs.setStringList(_webStorageKey, updatedWorkouts);
          print('Workout deleted from web storage: $workoutName');
          return true;
        }
        return false;
      } catch (e) {
        print('Failed to delete workout from web storage: $e');
        return false;
      }
    }

    try {
      final dir = await _workoutsDirectory;
      final fileName = _sanitizeFileName(workoutName);
      final file = File('${dir.path}/$fileName.json');

      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Failed to delete workout: $e');
      return false;
    }
  }

  /// Export a workout to a user-selected location
  Future<bool> exportWorkout(Workout workout) async {
    try {
      final jsonString = json.encode(workout.toJson());
      final fileName = _sanitizeFileName(workout.name);

      // Convert string to bytes for mobile platforms
      final bytes = Uint8List.fromList(utf8.encode(jsonString));

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Workout',
        fileName: '$fileName.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes, // Required for Android/iOS
      );

      if (path != null) {
        // On desktop platforms, path is returned and we need to write the file
        if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
          final file = File(path);
          await file.writeAsString(jsonString);
        }
        // On mobile platforms, the bytes are already saved by the picker
        return true;
      }
      return false;
    } catch (e) {
      print('Failed to export workout: $e');
      return false;
    }
  }

  /// Import a workout from a user-selected file
  /// Returns the workout if successfully imported, or null if canceled/failed
  /// Throws an exception with user-friendly message if workout already exists
  Future<Workout?> importWorkout() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Import Workout',
        withData: true, // Important for Android: loads file bytes
      );

      if (result != null && result.files.isNotEmpty) {
        String jsonString;

        // Try to get file content - Android typically provides bytes, desktop provides path
        if (result.files.single.bytes != null) {
          // Mobile/Web: Use bytes
          jsonString =
              utf8.decode(result.files.single.bytes!, allowMalformed: true);
        } else if (result.files.single.path != null) {
          // Desktop: Use path
          final file = File(result.files.single.path!);
          jsonString = await file.readAsString();
        } else {
          throw Exception('Unable to read file');
        }

        // Trim whitespace and remove any BOM characters
        jsonString = jsonString.trim();
        if (jsonString.startsWith('\uFEFF')) {
          jsonString = jsonString.substring(1);
        }

        // Try to parse JSON
        final jsonData = json.decode(jsonString) as Map<String, dynamic>;
        final workout = Workout.fromJson(jsonData);

        // Check if workout already exists
        final existingWorkouts = await loadAllWorkouts();
        final isDuplicate = existingWorkouts.any((w) => w.name == workout.name);

        if (isDuplicate) {
          throw Exception('DUPLICATE:${workout.name}');
        }

        // Save to user directory
        await saveWorkout(workout);

        return workout;
      }
      return null;
    } catch (e) {
      print('Failed to import workout: $e');
      rethrow; // Rethrow to handle in UI
    }
  }

  String _sanitizeFileName(String name) {
    // Remove or replace invalid filename characters
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }
}
