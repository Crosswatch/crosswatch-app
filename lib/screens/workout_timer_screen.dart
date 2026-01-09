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
                // Exercise counter - fixed height
                SizedBox(
                  height: 24,
                  child: Text(
                    'Exercise ${provider.currentExerciseNumber} of ${provider.totalExercises}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 8),

                // Phase indicator - fixed height container
                SizedBox(
                  height: 48,
                  child: provider.isTransition
                      ? Center(
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
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 16),

                // Breadcrumb - fixed height container
                SizedBox(
                  height: 20,
                  child: exercise.breadcrumb.length > 1
                      ? Text(
                          exercise.breadcrumb
                              .sublist(0, exercise.breadcrumb.length - 1)
                              .join(' > '),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 24),

                // Exercise name - fixed height with single line
                SizedBox(
                  height: 40,
                  child: Text(
                    exercise.displayName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: provider.isTransition ? Colors.blue[800] : null,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 32),

                // Timer display or manual completion
                if (provider.isTransition || exercise.needsTimer)
                  _buildTimerDisplay(context, provider, exercise)
                else
                  _buildManualCompletionDisplay(context, provider, exercise),

                const SizedBox(height: 24),

                // Description below timer - no fixed height needed
                if (exercise.set.description != null)
                  Text(
                    exercise.set.description!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
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
        // Navigation arrows and timer in a row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Previous button (left arrow) - hidden on first exercise
            SizedBox(
              width: 48,
              height: 48,
              child: provider.currentExerciseNumber > 1
                  ? IconButton(
                      icon: Icon(
                        Icons.chevron_left,
                        size: 48,
                        color: Colors.grey[600],
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () => provider.skipToPrevious(),
                      tooltip: 'Previous',
                    )
                  : null, // Empty space to maintain layout
            ),
            
            const SizedBox(width: 16),
            
            // Interactive circular progress indicator
            GestureDetector(
              onTapDown: (details) {
                // Calculate if tap is in center area for play/pause, or on ring for time adjustment
                final Offset localPosition = details.localPosition;
                final Offset center = const Offset(125, 125); // Half of 250x250
                final dx = localPosition.dx - center.dx;
                final dy = localPosition.dy - center.dy;
                final distanceFromCenter = math.sqrt(dx * dx + dy * dy);
                
                if (distanceFromCenter < 80) {
                  // Tap in center - toggle play/pause
                  if (provider.isRunning) {
                    provider.pause();
                  } else {
                    provider.start();
                  }
                } else {
                  // Tap on outer ring - adjust time by angle
                  _handleTimerTap(details, provider);
                }
              },
              onPanStart: (details) {
                // Only pause if we're dragging on the outer ring (not center)
                final Offset localPosition = details.localPosition;
                final Offset center = const Offset(125, 125);
                final dx = localPosition.dx - center.dx;
                final dy = localPosition.dy - center.dy;
                final distanceFromCenter = math.sqrt(dx * dx + dy * dy);
                
                if (distanceFromCenter >= 80 && provider.isRunning) {
                  provider.pause();
                }
              },
              onPanUpdate: (details) {
                // Only adjust time if dragging on outer ring
                final Offset localPosition = details.localPosition;
                final Offset center = const Offset(125, 125);
                final dx = localPosition.dx - center.dx;
                final dy = localPosition.dy - center.dy;
                final distanceFromCenter = math.sqrt(dx * dx + dy * dy);
                
                if (distanceFromCenter >= 80) {
                  _handleTimerDrag(details, provider);
                }
              },
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
                    // Overlay for paused state
                    if (provider.isPaused)
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
                      ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Show pause icon overlay when paused
                          if (provider.isPaused) ...[
                            Icon(
                              Icons.play_arrow,
                              size: 80,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            provider.remainingTimeFormatted,
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 56,
                                  color: provider.isPaused ? Colors.white : null,
                                ),
                          ),
                          const SizedBox(height: 8),
                          if (!isTransition && isReps) ...[
                            Text(
                              '${exercise.set.value!.toInt()} reps',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: provider.isPaused 
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          // Round indicator inside timer
                          if (!isTransition && exercise.totalRounds > 1)
                            Text(
                              'Round ${exercise.currentRound}/${exercise.totalRounds}',
                              style: TextStyle(
                                color: provider.isPaused 
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Next button (right arrow)
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  size: 48,
                  color: Colors.grey[600],
                ),
                padding: EdgeInsets.zero,
                onPressed: () => provider.skipToNext(),
                tooltip: 'Skip',
              ),
            ),
          ],
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
    // Use the circular drag approach - calculate angle from center
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

  Widget _buildManualCompletionDisplay(
    BuildContext context,
    WorkoutTimerProvider provider,
    WorkoutExercise exercise,
  ) {
    return Column(
      children: [
        // Navigation arrows and rep display in a row (matching timer layout)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Previous button (left arrow) - hidden on first exercise
            SizedBox(
              width: 48,
              height: 48,
              child: provider.currentExerciseNumber > 1
                  ? IconButton(
                      icon: Icon(
                        Icons.chevron_left,
                        size: 48,
                        color: Colors.grey[600],
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () => provider.skipToPrevious(),
                      tooltip: 'Previous',
                    )
                  : null, // Empty space to maintain layout
            ),
            
            const SizedBox(width: 16),
            
            // Large reps display (same size as timer: 250x250)
            GestureDetector(
              onTap: () {
                // Tap to complete the exercise
                if (provider.isRunning) {
                  provider.completeExercise();
                }
              },
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Center(
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
                      const SizedBox(height: 8),
                      Text(
                        'REPS',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      // Round indicator inside rep circle
                      if (exercise.totalRounds > 1) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Round ${exercise.currentRound}/${exercise.totalRounds}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Next button (right arrow)
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  size: 48,
                  color: Colors.grey[600],
                ),
                padding: EdgeInsets.zero,
                onPressed: () => provider.skipToNext(),
                tooltip: 'Skip',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletedView(
    BuildContext context,
    WorkoutTimerProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Exercise counter - fixed height (same as timer view)
          SizedBox(
            height: 24,
            child: Text(
              'Workout Complete!',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 8),

          // Phase indicator space (same as timer view)
          const SizedBox(height: 48),

          const SizedBox(height: 16),

          // Breadcrumb space (same as timer view)
          const SizedBox(height: 20),

          const SizedBox(height: 24),

          // Title space (same as timer view)
          SizedBox(
            height: 40,
            child: Text(
              'Great job!',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 32),

          // Check mark in place of timer (250x250 like timer)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Back arrow (same position as previous button on timer)
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  size: 48,
                  color: Colors.grey[600],
                ),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 120,
                    color: Colors.green[600],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const SizedBox(width: 48), // Space for alignment
            ],
          ),

          const SizedBox(height: 24),

          // Description space (same as timer view)
          Text(
            'You completed all ${provider.totalExercises} exercises.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
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
