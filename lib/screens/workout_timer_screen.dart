import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/workout.dart';
import '../models/workout_set.dart';
import '../providers/workout_timer_provider.dart';

class WorkoutTimerScreen extends StatelessWidget {
  final Workout workout;

  const WorkoutTimerScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WorkoutTimerProvider(workout),
      child: const _WorkoutTimerScreenContent(),
    );
  }
}

class _WorkoutTimerScreenContent extends StatelessWidget {
  const _WorkoutTimerScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<WorkoutTimerProvider>(
          builder: (context, provider, child) {
            return Text(provider.workout.name);
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () {
              _showStopConfirmation(context);
            },
            tooltip: 'Stop workout',
          ),
        ],
      ),
      body: Consumer<WorkoutTimerProvider>(
        builder: (context, provider, child) {
          if (provider.isCompleted) {
            return _buildCompletedView(context, provider);
          }

          return _buildTimerView(context, provider);
        },
      ),
    );
  }

  Widget _buildTimerView(BuildContext context, WorkoutTimerProvider provider) {
    final exercise = provider.currentExercise;

    if (exercise == null) {
      return const Center(child: Text('No exercises found'));
    }

    return Column(
      children: [
        // Progress indicator
        LinearProgressIndicator(
          value: provider.completedExercises / provider.totalExercises,
          minHeight: 8,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Exercise counter
                Text(
                  'Exercise ${provider.currentExerciseNumber} of ${provider.totalExercises}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Phase indicator
                if (provider.isTransition)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.blue[300]!, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.schedule,
                            color: Colors.blue[900],
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'GET READY',
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Breadcrumb
                if (exercise.breadcrumb.length > 1)
                  Text(
                    exercise.breadcrumb
                        .sublist(0, exercise.breadcrumb.length - 1)
                        .join(' > '),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 24),

                // Exercise name
                Text(
                  provider.isTransition
                      ? 'Coming Up: ${exercise.displayName}'
                      : exercise.displayName,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: provider.isTransition ? Colors.blue[800] : null,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Description
                if (exercise.set.description != null)
                  Text(
                    exercise.set.description!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 32),

                // Timer display or manual completion
                if (provider.isTransition || exercise.needsTimer)
                  _buildTimerDisplay(context, provider, exercise)
                else
                  _buildManualCompletionDisplay(context, provider, exercise),

                const SizedBox(height: 48),

                // Control buttons
                _buildControlButtons(context, provider),

                const SizedBox(height: 24),

                // Navigation buttons
                _buildNavigationButtons(context, provider),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerDisplay(
    BuildContext context,
    WorkoutTimerProvider provider,
    WorkoutExercise exercise,
  ) {
    final isTransition = provider.isTransition;
    final isReps = !isTransition && exercise.set.type == SetType.reps;
    final colorScheme = Theme.of(context).colorScheme;
    final color = isTransition
        ? colorScheme.primary
        : (isReps ? colorScheme.tertiary : colorScheme.secondary);

    return Column(
      children: [
        // Interactive circular progress indicator
        GestureDetector(
          onTapDown: (details) => _handleTimerTap(details, provider),
          onPanUpdate: (details) => _handleTimerDrag(details, provider),
          child: SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: provider.progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        provider.remainingTimeFormatted,
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 56,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (!isTransition && isReps) ...[
                        Text(
                          '${exercise.set.value!.toInt()} reps',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Restart button
        OutlinedButton.icon(
          onPressed: () => provider.restartCurrentTimer(),
          icon: const Icon(Icons.restart_alt, size: 20),
          label: const Text('Restart'),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
          ),
        ),

        const SizedBox(height: 16),

        // Round indicator
        if (!isTransition && exercise.totalRounds > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Round ${exercise.currentRound} of ${exercise.totalRounds}',
              style: TextStyle(
                color: Colors.blue[900],
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
      ],
    );
  }

  void _handleTimerTap(TapDownDetails details, WorkoutTimerProvider provider) {
    final Offset localPosition = details.localPosition;
    final Offset center = const Offset(125, 125); // Half of 250x250

    // Calculate angle from center (-π to π)
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    var angle = math.atan2(dy, dx);

    // Convert to 0-1 range (starting from top, going clockwise)
    // Top is -π/2, so we adjust
    angle = angle + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;

    // Convert to progress (1.0 at top, 0.0 after full rotation)
    final position = 1.0 - (angle / (2 * math.pi));

    provider.setTimerPosition(position);
  }

  void _handleTimerDrag(
    DragUpdateDetails details,
    WorkoutTimerProvider provider,
  ) {
    // For drag, we'll use a simpler approach - just use the vertical position
    // This is easier than trying to calculate angles during drag
    final dy = details.localPosition.dy;

    // Map vertical position (0-250) to timer position (1.0-0.0)
    // Top = 1.0 (full time), Bottom = 0.0 (no time)
    final position = 1.0 - (dy / 250).clamp(0.0, 1.0);

    provider.setTimerPosition(position);
  }

  Widget _buildManualCompletionDisplay(
    BuildContext context,
    WorkoutTimerProvider provider,
    WorkoutExercise exercise,
  ) {
    return Column(
      children: [
        const SizedBox(height: 40),

        // Large reps display
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.green[100],
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                exercise.set.value!.toInt().toString(),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 72,
                  color: Colors.green[900],
                ),
              ),
              Text(
                'REPS',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Complete button
        ElevatedButton.icon(
          onPressed: provider.isRunning
              ? () => provider.completeExercise()
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          icon: const Icon(Icons.check_circle, size: 32),
          label: const Text('Complete'),
        ),

        const SizedBox(height: 16),

        Text(
          'Press when you finish your ${exercise.set.value!.toInt()} reps',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        // Round indicator
        if (exercise.totalRounds > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Round ${exercise.currentRound} of ${exercise.totalRounds}',
              style: TextStyle(
                color: Colors.blue[900],
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildControlButtons(
    BuildContext context,
    WorkoutTimerProvider provider,
  ) {
    final exercise = provider.currentExercise;
    final showPlayPause =
        provider.isTransition || (exercise != null && exercise.needsTimer);

    if (!showPlayPause) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (provider.isRunning)
          FloatingActionButton.large(
            onPressed: () => provider.pause(),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: const Icon(Icons.pause, size: 36),
          )
        else
          FloatingActionButton.large(
            onPressed: () => provider.start(),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            child: const Icon(Icons.play_arrow, size: 36),
          ),
      ],
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    WorkoutTimerProvider provider,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        OutlinedButton.icon(
          onPressed: provider.currentExerciseNumber > 1
              ? () => provider.skipToPrevious()
              : null,
          icon: const Icon(Icons.skip_previous),
          label: const Text('Previous'),
        ),
        OutlinedButton.icon(
          onPressed: () => provider.skipToNext(),
          icon: const Icon(Icons.skip_next),
          label: const Text('Skip'),
        ),
      ],
    );
  }

  Widget _buildCompletedView(
    BuildContext context,
    WorkoutTimerProvider provider,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 120,
              color: Colors.green[600],
            ),
            const SizedBox(height: 24),
            Text(
              'Workout Complete!',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Great job! You completed all ${provider.totalExercises} exercises.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => provider.stop(),
                  icon: const Icon(Icons.replay),
                  label: const Text('Restart'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.home),
                  label: const Text('Go Home'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStopConfirmation(BuildContext context) {
    final provider = context.read<WorkoutTimerProvider>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Stop Workout?'),
          content: const Text(
            'Are you sure you want to stop this workout? Your progress will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                provider.stop();
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Stop'),
            ),
          ],
        );
      },
    );
  }
}
