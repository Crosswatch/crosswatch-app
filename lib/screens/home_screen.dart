import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../services/workout_storage_service.dart';
import 'workout_detail_screen.dart';
import 'workout_timer_screen.dart';
import 'workout_builder_screen.dart';
import 'workout_import_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storageService = WorkoutStorageService();
  List<Workout> _workouts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final workouts = await _storageService.loadAllWorkouts();
      setState(() {
        _workouts = workouts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load workouts: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _importWorkout() async {
    // Navigate to the new import screen
    final workout = await Navigator.push<Workout>(
      context,
      MaterialPageRoute(builder: (context) => const WorkoutImportScreen()),
    );

    if (workout != null) {
      _loadWorkouts();
    }
  }

  Future<void> _importWorkoutFromFile() async {
    try {
      final workout = await _storageService.importWorkout();
      if (workout != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported "${workout.name}"'),
            backgroundColor: Colors.green,
          ),
        );
        _loadWorkouts();
      }
    } catch (e) {
      if (mounted) {
        // Check if it's a duplicate error
        final errorMessage = e.toString();
        if (errorMessage.contains('DUPLICATE:')) {
          final workoutName = errorMessage
              .split('DUPLICATE:')[1]
              .replaceAll('\'', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Workout "$workoutName" already exists'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        } else {
          // Generic error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to import workout: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _exportWorkout(Workout workout) async {
    final success = await _storageService.exportWorkout(workout);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Exported "${workout.name}"'
                : 'Export canceled or failed',
          ),
        ),
      );
    }
  }

  Future<void> _deleteWorkout(Workout workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout?'),
        content: Text('Are you sure you want to delete "${workout.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _storageService.deleteWorkout(workout.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Deleted "${workout.name}"'
                  : 'Failed to delete workout',
            ),
          ),
        );
        if (success) {
          _loadWorkouts();
        }
      }
    }
  }

  Future<void> _duplicateWorkout(Workout workout) async {
    final newName = '${workout.name} (Copy)';
    final duplicated = Workout(
      name: newName,
      description: workout.description,
      sets: workout.sets, // Shallow copy is fine for now
    );

    await _storageService.saveWorkout(duplicated);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Duplicated as "$newName"')));
      _loadWorkouts();
    }
  }

  void _showWorkoutOptions(Workout workout) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Start Workout'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutTimerScreen(workout: workout),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutDetailScreen(workout: workout),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        WorkoutBuilderScreen(existingWorkout: workout),
                  ),
                );
                _loadWorkouts();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('Export'),
              onTap: () {
                Navigator.pop(context);
                _exportWorkout(workout);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.pop(context);
                _duplicateWorkout(workout);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteWorkout(workout);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNewWorkoutMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Create New Workout',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Build Manually'),
              subtitle: const Text('Create a workout step by step'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkoutBuilderScreen(),
                  ),
                );
                _loadWorkouts();
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('AI Import'),
              subtitle: const Text('From URL or plain text description'),
              onTap: () async {
                Navigator.pop(context);
                await _importWorkout();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_open),
              title: const Text('Import from File'),
              subtitle: const Text('Load a previously exported workout'),
              onTap: () async {
                Navigator.pop(context);
                await _importWorkoutFromFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crosswatch'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              _loadWorkouts();
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewWorkoutMenu,
        icon: const Icon(Icons.add),
        label: const Text('New Workout'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWorkouts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_workouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No workouts found',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new workout or import one',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _workouts.length,
      itemBuilder: (context, index) {
        final workout = _workouts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _showWorkoutOptions(workout),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (workout.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            workout.description!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.timer, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              workout.formattedDuration(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.list, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${workout.sets.length} sets',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_circle_filled),
                    iconSize: 48,
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              WorkoutTimerScreen(workout: workout),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
