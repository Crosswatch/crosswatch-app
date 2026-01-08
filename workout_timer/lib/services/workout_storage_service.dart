import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:file_picker/file_picker.dart';
import '../models/workout.dart';

class WorkoutStorageService {
  static final WorkoutStorageService _instance =
      WorkoutStorageService._internal();
  factory WorkoutStorageService() => _instance;
  WorkoutStorageService._internal();

  Future<Directory> get _workoutsDirectory async {
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

    // Load user workouts from file system
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

    return workouts;
  }

  /// Save a workout to the user directory
  Future<void> saveWorkout(Workout workout) async {
    final dir = await _workoutsDirectory;
    final fileName = _sanitizeFileName(workout.name);
    final file = File('${dir.path}/$fileName.json');

    final jsonString = json.encode(workout.toJson());
    await file.writeAsString(jsonString);
  }

  /// Delete a workout from the user directory
  Future<bool> deleteWorkout(String workoutName) async {
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

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Workout',
        fileName: '$fileName.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (path != null) {
        final file = File(path);
        await file.writeAsString(jsonString);
        return true;
      }
      return false;
    } catch (e) {
      print('Failed to export workout: $e');
      return false;
    }
  }

  /// Import a workout from a user-selected file
  Future<Workout?> importWorkout() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Import Workout',
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final workout = Workout.fromJson(json.decode(jsonString));

        // Save to user directory
        await saveWorkout(workout);

        return workout;
      }
      return null;
    } catch (e) {
      print('Failed to import workout: $e');
      return null;
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
