import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/workout.dart';
import '../models/workout_set.dart';
import '../services/notification_service.dart';
import '../services/audio_service.dart';

enum TimerState { idle, running, paused, completed }

enum ExercisePhase { transition, active }

/// Represents a flattened exercise in the workout with its context
class WorkoutExercise {
  final WorkoutSet set;
  final int currentRound;
  final int totalRounds;
  final List<String> breadcrumb; // Path to this exercise

  WorkoutExercise({
    required this.set,
    required this.currentRound,
    required this.totalRounds,
    required this.breadcrumb,
  });

  String get displayName => set.name;
  String get breadcrumbPath => breadcrumb.join(' > ');

  /// Check if this exercise requires a timer
  bool get needsTimer {
    if (set.type == SetType.time) return true;
    if (set.type == SetType.reps && set.duration != null) return true;
    return false;
  }

  /// Check if this exercise requires manual completion
  bool get requiresManualCompletion {
    return set.type == SetType.reps && set.duration == null;
  }
}

class WorkoutTimerProvider extends ChangeNotifier {
  final Workout workout;

  // Timer state
  TimerState _state = TimerState.idle;
  ExercisePhase _phase = ExercisePhase.transition;
  Timer? _timer;

  // Exercise progression
  final List<WorkoutExercise> _exercises = [];
  int _currentExerciseIndex = 0;
  double _remainingSeconds = 0;
  double _totalExerciseSeconds = 0;

  // Overall workout progress
  int _completedExercises = 0;

  // Services
  final NotificationService _notificationService = NotificationService();
  final AudioService _audioService = AudioService();

  // Track last countdown second to avoid duplicate sounds
  int _lastCountdownSecond = -1;

  WorkoutTimerProvider(this.workout) {
    _notificationService.initialize();
    _flattenWorkout();
    if (_exercises.isNotEmpty) {
      _initializeExercise(0);
      // Automatically start the workout after a 1-second delay
      _state = TimerState.running;
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (_state == TimerState.running) {
          _startTimer();
        }
      });
    }
  }

  // Getters
  TimerState get state => _state;
  ExercisePhase get phase => _phase;
  bool get isRunning => _state == TimerState.running;
  bool get isPaused => _state == TimerState.paused;
  bool get isCompleted => _state == TimerState.completed;
  bool get isIdle => _state == TimerState.idle;
  bool get isTransition => _phase == ExercisePhase.transition;
  bool get isActive => _phase == ExercisePhase.active;

  WorkoutExercise? get currentExercise =>
      _exercises.isNotEmpty ? _exercises[_currentExerciseIndex] : null;

  int get currentExerciseNumber => _currentExerciseIndex + 1;
  int get totalExercises => _exercises.length;
  double get remainingSeconds => _remainingSeconds;
  double get totalExerciseSeconds => _totalExerciseSeconds;
  double get progress => _totalExerciseSeconds > 0
      ? 1 - (_remainingSeconds / _totalExerciseSeconds)
      : 0;

  int get completedExercises => _completedExercises;

  String get remainingTimeFormatted {
    final minutes = (_remainingSeconds / 60).floor();
    final seconds = (_remainingSeconds % 60).ceil();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Actions
  void start() {
    if (_state == TimerState.idle || _state == TimerState.paused) {
      _state = TimerState.running;
      _startTimer();
      notifyListeners();
    }
  }

  void pause() {
    if (_state == TimerState.running) {
      _state = TimerState.paused;
      _timer?.cancel();
      notifyListeners();
    }
  }

  void stop() {
    _timer?.cancel();
    _state = TimerState.idle;
    _currentExerciseIndex = 0;
    _completedExercises = 0;
    _phase = ExercisePhase.transition;
    _initializeExercise(0);
    notifyListeners();
  }

  /// Complete current exercise (for rep-based exercises without timer)
  void completeExercise() {
    final exercise = currentExercise;
    if (exercise != null &&
        exercise.requiresManualCompletion &&
        _phase == ExercisePhase.active) {
      _playNotificationSound();
      _moveToNextExercise();
    }
  }

  /// Restart the current exercise/transition timer
  void restartCurrentTimer() {
    _remainingSeconds = _totalExerciseSeconds;
    _lastCountdownSecond = -1;
    notifyListeners();

    // Restart the timer if we were running
    if (_state == TimerState.running) {
      _startTimer();
    }
  }

  /// Set the timer to a specific position (0.0 to 1.0, where 0 is complete and 1 is start)
  void setTimerPosition(double position) {
    if (position < 0) position = 0;
    if (position > 1) position = 1;

    _remainingSeconds = _totalExerciseSeconds * position;
    _lastCountdownSecond = -1;
    notifyListeners();

    // If running, restart the timer to continue from new position
    if (_state == TimerState.running) {
      _startTimer();
    }
  }

  void skipToNext() {
    // Skip to next exercise's transition phase
    if (_currentExerciseIndex < _exercises.length - 1) {
      _timer?.cancel(); // Stop current timer

      _currentExerciseIndex++;
      if (_completedExercises < _currentExerciseIndex) {
        _completedExercises = _currentExerciseIndex;
      }

      // Initialize next exercise (starts with transition)
      _initializeExercise(_currentExerciseIndex);
      notifyListeners();

      // Start timer with delay if we were running
      if (_state == TimerState.running) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (_state == TimerState.running) {
            _remainingSeconds -= 0.2;
            _startTimer();
          }
        });
      }
    } else {
      _completeWorkout();
    }
  }

  void skipToPrevious() {
    // Skip to previous exercise's transition phase
    if (_currentExerciseIndex > 0) {
      _timer?.cancel(); // Stop current timer

      _currentExerciseIndex--;
      if (_completedExercises > 0) {
        _completedExercises--;
      }

      // Initialize previous exercise (starts with transition)
      _initializeExercise(_currentExerciseIndex);
      notifyListeners();

      // Start timer with delay if we were running
      if (_state == TimerState.running) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (_state == TimerState.running) {
            _remainingSeconds -= 0.2;
            _startTimer();
          }
        });
      }
    }
  }

  // Private methods
  void _startTimer() {
    _timer?.cancel();
    _lastCountdownSecond = -1;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_remainingSeconds > 0) {
        // Play countdown sound BEFORE decrementing (so we beep at 5, 4, 3, 2, 1)
        final currentSecond = _remainingSeconds.ceil();
        if (currentSecond <= 5 &&
            currentSecond > 0 &&
            currentSecond != _lastCountdownSecond) {
          _lastCountdownSecond = currentSecond;
          _playCountdownSound();
        }

        _remainingSeconds -= 0.1;
        if (_remainingSeconds < 0) _remainingSeconds = 0;

        notifyListeners();

        // If we just hit zero, complete immediately
        if (_remainingSeconds <= 0) {
          _onTimerComplete();
        }
      }
    });
  }

  void _onTimerComplete() {
    if (_phase == ExercisePhase.transition) {
      // Transition complete, start the actual exercise
      _phase = ExercisePhase.active;
      _playNotificationSound(); // Play complete sound to signal exercise start

      final exercise = currentExercise;
      if (exercise != null) {
        // Send notification about starting exercise NOW
        _notificationService.showExerciseNotification(
          exerciseName: exercise.displayName,
          description: exercise.set.description ?? 'Start your exercise now!',
        );

        if (exercise.needsTimer) {
          // Start timer for timed exercises
          if (exercise.set.type == SetType.time) {
            _totalExerciseSeconds = exercise.set.value!;
            _remainingSeconds = exercise.set.value!;
          } else if (exercise.set.type == SetType.reps &&
              exercise.set.duration != null) {
            _totalExerciseSeconds = exercise.set.duration!;
            _remainingSeconds = exercise.set.duration!;
          }
          _lastCountdownSecond = -1; // Reset countdown tracker

          // Cancel existing timer and restart after a delay to avoid audio collision
          _timer?.cancel();
          notifyListeners();

          if (_state == TimerState.running) {
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (_state == TimerState.running) {
                // Subtract a tiny amount to ensure we don't start exactly on a whole second
                _remainingSeconds -= 0.2;
                _startTimer();
              }
            });
          }
        } else {
          // Manual completion required - stop timer
          _timer?.cancel();
          notifyListeners();
        }
      }
    } else {
      // Exercise complete
      _playNotificationSound();
      _moveToNextExercise();
    }
  }

  void _moveToNextExercise() {
    _completedExercises++;

    // IMPORTANT: Cancel the existing timer immediately to prevent it from continuing
    // while we wait for the delay
    _timer?.cancel();

    if (_currentExerciseIndex < _exercises.length - 1) {
      _currentExerciseIndex++;
      final nextExercise = _exercises[_currentExerciseIndex];

      // Send appropriate notification based on whether there's a transition
      if (nextExercise.set.effectiveTransitionTime > 0) {
        // Normal transition - notify about upcoming exercise
        _notificationService.showTransitionNotification(
          nextExerciseName: nextExercise.displayName,
          secondsRemaining: nextExercise.set.effectiveTransitionTime.toInt(),
        );
      } else {
        // No transition - notify that exercise is starting now
        _notificationService.showExerciseNotification(
          exerciseName: nextExercise.displayName,
          description: nextExercise.set.description ?? 'Start now!',
        );
      }

      _initializeExercise(_currentExerciseIndex);
      notifyListeners();

      // Add a 1-second delay before starting the next timer to avoid audio collision
      // with the completion sound
      if (_state == TimerState.running) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (_state == TimerState.running) {
            // Subtract a tiny amount to ensure we don't start exactly on a whole second
            // which would immediately trigger a countdown beep
            _remainingSeconds -= 0.2;
            _startTimer();
          }
        });
      }
    } else {
      _completeWorkout();
    }
  }

  void _completeWorkout() {
    _timer?.cancel();
    _state = TimerState.completed;
    _playNotificationSound();
    _notificationService.showWorkoutCompleteNotification();
    notifyListeners();
  }

  void _initializeExercise(int index) {
    if (index >= _exercises.length) return;

    final exercise = _exercises[index];

    // Skip transition if transition time is 0 (e.g., for rest periods)
    if (exercise.set.effectiveTransitionTime <= 0) {
      _startExerciseActive(index);
      return;
    }

    // Start with transition phase
    _phase = ExercisePhase.transition;
    _totalExerciseSeconds = exercise.set.effectiveTransitionTime;
    _remainingSeconds = exercise.set.effectiveTransitionTime;
    _lastCountdownSecond = -1; // Reset countdown tracker
  }

  /// Start an exercise directly in active phase (used for navigation)
  void _startExerciseActive(int index) {
    if (index >= _exercises.length) return;

    final exercise = _exercises[index];

    // Skip transition, go directly to active phase
    _phase = ExercisePhase.active;

    if (exercise.needsTimer) {
      if (exercise.set.type == SetType.time) {
        _totalExerciseSeconds = exercise.set.value!;
        _remainingSeconds = exercise.set.value!;
      } else if (exercise.set.type == SetType.reps &&
          exercise.set.duration != null) {
        _totalExerciseSeconds = exercise.set.duration!;
        _remainingSeconds = exercise.set.duration!;
      }
      _lastCountdownSecond = -1; // Reset countdown tracker
    } else {
      // Manual completion - no timer
      _totalExerciseSeconds = 0;
      _remainingSeconds = 0;
      _timer?.cancel();
    }
  }

  void _playNotificationSound() {
    // Play audio notification
    _audioService.playNotification();
  }

  void _playCountdownSound() {
    // Play audio countdown
    _audioService.playCountdown();
  }

  void _flattenWorkout() {
    _exercises.clear();
    for (final set in workout.sets) {
      _flattenSet(set, []);
    }
  }

  void _flattenSet(WorkoutSet set, List<String> parentBreadcrumb) {
    final breadcrumb = [...parentBreadcrumb, set.name];

    if (set.isLeaf) {
      // Leaf set - add to exercises list
      final rounds = set.rounds ?? 1;
      for (int r = 1; r <= rounds; r++) {
        _exercises.add(
          WorkoutExercise(
            set: set,
            currentRound: r,
            totalRounds: rounds,
            breadcrumb: breadcrumb,
          ),
        );

        // Add rest period after each round (except the last) for leaf exercises too
        if (set.restBetweenRounds != null &&
            set.restBetweenRounds! > 0 &&
            r < rounds) {
          _exercises.add(
            WorkoutExercise(
              set: WorkoutSet(
                name: 'Rest',
                description: 'Rest between rounds',
                type: SetType.time,
                value: set.restBetweenRounds,
                transitionTime: 0, // No transition for rest periods
              ),
              currentRound: r,
              totalRounds: rounds,
              breadcrumb: [...breadcrumb, 'Rest'],
            ),
          );
        }
      }
    } else if (set.isContainer && set.sets != null) {
      // Container set - flatten children
      final rounds = set.effectiveRounds;
      for (int r = 1; r <= rounds; r++) {
        for (final childSet in set.sets!) {
          _flattenSet(childSet, breadcrumb);
        }

        // Add rest period after each round (except the last)
        if (set.restBetweenRounds != null &&
            set.restBetweenRounds! > 0 &&
            r < rounds) {
          _exercises.add(
            WorkoutExercise(
              set: WorkoutSet(
                name: 'Rest',
                description: 'Rest between rounds',
                type: SetType.time,
                value: set.restBetweenRounds,
                transitionTime: 0, // No transition for rest periods
              ),
              currentRound: r,
              totalRounds: rounds,
              breadcrumb: [...breadcrumb, 'Rest'],
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
