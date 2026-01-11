import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/workout_set.dart';
import '../services/workout_import_service.dart';
import '../services/workout_storage_service.dart';

class WorkoutImportScreen extends StatefulWidget {
  const WorkoutImportScreen({super.key});

  @override
  State<WorkoutImportScreen> createState() => _WorkoutImportScreenState();
}

class _WorkoutImportScreenState extends State<WorkoutImportScreen> {
  final _urlController = TextEditingController();
  final _textController = TextEditingController();
  int _selectedTab = 0; // 0 = URL, 1 = Text
  bool _isImporting = false;
  String? _error;
  Workout? _previewWorkout;

  @override
  void initState() {
    super.initState();
    // Check if API key is available when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkApiKey();
    });
  }

  Future<void> _checkApiKey() async {
    final hasKey = await WorkoutImportService.hasApiKey();
    final onDevice = await WorkoutImportService.isOnDeviceAvailable();

    if (!hasKey && !onDevice && mounted) {
      final goToSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('API Key Required'),
          content: const Text(
            'You need to add a Gemini API key to import workouts. '
            'Would you like to go to settings now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Go to Settings'),
            ),
          ],
        ),
      );

      if (goToSettings == true && mounted) {
        Navigator.pop(context); // Go back to home
        // Home screen will handle navigation to settings
      }
    }
  }

  Future<void> _importWorkout() async {
    setState(() {
      _isImporting = true;
      _error = null;
      _previewWorkout = null;
    });

    try {
      final String? url =
          _selectedTab == 0 && _urlController.text.trim().isNotEmpty
          ? _urlController.text.trim()
          : null;
      final String? text =
          _selectedTab == 1 && _textController.text.trim().isNotEmpty
          ? _textController.text.trim()
          : null;

      if (url == null && text == null) {
        throw Exception('Please enter a URL or paste workout text');
      }

      final workoutJson = await WorkoutImportService.importWorkout(
        url: url,
        text: text,
      );

      // Create workout from JSON
      final workout = Workout.fromJson(workoutJson);

      setState(() {
        _previewWorkout = workout;
        _isImporting = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isImporting = false;
      });
    }
  }

  Future<void> _saveWorkout() async {
    if (_previewWorkout == null) return;

    try {
      final storageService = WorkoutStorageService();
      await storageService.saveWorkout(_previewWorkout!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved "${_previewWorkout!.name}"'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, _previewWorkout);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Workout'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _previewWorkout != null ? _buildPreview() : _buildImportForm(),
    );
  }

  Widget _buildImportForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info card
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'AI-Powered Import',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Paste a URL or workout text, and AI will convert it to a structured workout for you.',
                    style: TextStyle(color: Colors.blue[900], fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Tab selector
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                label: Text('From URL'),
                icon: Icon(Icons.link),
              ),
              ButtonSegment(
                value: 1,
                label: Text('From Text'),
                icon: Icon(Icons.text_fields),
              ),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (Set<int> selected) {
              setState(() {
                _selectedTab = selected.first;
              });
            },
          ),

          const SizedBox(height: 24),

          // Input field
          if (_selectedTab == 0)
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Workout URL',
                hintText: 'https://example.com/workout',
                helperText:
                    'CrossFit.com, social media, or any webpage with a workout',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              maxLines: 2,
            )
          else
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Workout Text',
                hintText: 'Paste your workout description here...',
                helperText: 'Can be from anywhere - social media, notes, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 15,
              minLines: 10,
            ),

          const SizedBox(height: 24),

          // Import button
          ElevatedButton.icon(
            onPressed: _isImporting ? null : _importWorkout,
            icon: _isImporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: Text(_isImporting ? 'Converting...' : 'Import Workout'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),

          // Error display
          if (_error != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Import Failed',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_error!, style: TextStyle(color: Colors.red[900])),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Examples
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Example Workouts to Try:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildExample(
                    'Murph',
                    '1 mile run, 100 pull-ups, 200 push-ups, 300 air squats, 1 mile run',
                  ),
                  _buildExample(
                    'Fran',
                    '21-15-9 reps of thrusters (95 lbs) and pull-ups',
                  ),
                  _buildExample(
                    'Quick HIIT',
                    '4 rounds: 30 sec burpees, 30 sec rest, 30 sec mountain climbers, 30 sec rest',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExample(String name, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Import Successful!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Review the workout below and save it to your library.',
                    style: TextStyle(color: Colors.green[900]),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _previewWorkout!.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_previewWorkout!.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _previewWorkout!.description!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Structure:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._buildSetPreview(_previewWorkout!.sets, 0),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Structure:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._buildSetPreview(_previewWorkout!.sets, 0),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Estimated Duration: ${_previewWorkout!.formattedDuration()}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _previewWorkout = null;
                      _error = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _saveWorkout,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Workout'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSetPreview(List<WorkoutSet> sets, int depth) {
    final List<Widget> widgets = [];
    final indent = depth * 16.0;

    for (final set in sets) {
      // Build the set display
      widgets.add(
        Padding(
          padding: EdgeInsets.only(left: indent, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                set.isContainer ? Icons.folder_open : Icons.fitness_center,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      set.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatSetDetails(set),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      // Recursively display nested sets
      if (set.isContainer && set.sets != null) {
        widgets.addAll(_buildSetPreview(set.sets!, depth + 1));
      }
    }

    return widgets;
  }

  String _formatSetDetails(WorkoutSet set) {
    final List<String> details = [];

    // Rounds
    if (set.rounds != null && set.rounds! > 1) {
      if (set.rounds == 999) {
        details.add('AMRAP');
      } else {
        details.add('${set.rounds} rounds');
      }
    }

    // Type and value (for leaf sets)
    if (set.isLeaf) {
      if (set.type == SetType.reps) {
        if (set.value != null) {
          details.add('${set.value!.toInt()} reps');
        } else {
          details.add('reps');
        }
      } else if (set.type == SetType.time) {
        final seconds = set.value!.toInt();
        if (seconds >= 60) {
          final minutes = seconds ~/ 60;
          final remainingSeconds = seconds % 60;
          if (remainingSeconds > 0) {
            details.add('${minutes}m ${remainingSeconds}s');
          } else {
            details.add('${minutes}m');
          }
        } else {
          details.add('${seconds}s');
        }
      }
    }

    // Rest
    if (set.restBetweenRounds != null && set.restBetweenRounds! > 0) {
      details.add('${set.restBetweenRounds!.toInt()}s rest');
    }

    // Number of exercises (for container sets)
    if (set.isContainer && set.sets != null) {
      details.add('${set.sets!.length} exercises');
    }

    return details.isEmpty ? 'Exercise' : details.join(' • ');
  }
}
