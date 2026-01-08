import 'workout_set.dart';

/// Represents a complete workout with a name, description, and sets
class Workout {
  final String name;
  final String? description;
  final List<WorkoutSet> sets;

  Workout({
    required this.name,
    this.description,
    required this.sets,
  });

  /// Create from JSON
  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      name: json['name'] as String,
      description: json['description'] as String?,
      sets: (json['sets'] as List)
          .map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'name': name,
      'sets': sets.map((s) => s.toJson()).toList(),
    };

    if (description != null) {
      json['description'] = description;
    }

    return json;
  }

  /// Calculate total estimated duration in seconds
  /// This is a rough estimate that counts all time-based exercises
  /// and assumes 2 seconds per rep for rep-based exercises
  double estimatedDuration() {
    return _calculateSetDuration(sets);
  }

  double _calculateSetDuration(List<WorkoutSet> sets) {
    double total = 0;

    for (final set in sets) {
      final rounds = set.effectiveRounds;
      
      if (set.isLeaf) {
        // Leaf set
        if (set.type == SetType.time) {
          total += set.value! * rounds;
        } else if (set.type == SetType.reps) {
          // Assume 2 seconds per rep
          total += (set.value! * 2) * rounds;
        }
      } else if (set.isContainer) {
        // Container set
        final nestedDuration = _calculateSetDuration(set.sets!);
        total += nestedDuration * rounds;
      }

      // Add rest between rounds (but not after the last round)
      if (set.restBetweenRounds != null && rounds > 1) {
        total += set.restBetweenRounds! * (rounds - 1);
      }
    }

    return total;
  }

  /// Format duration as MM:SS
  String formattedDuration() {
    final duration = estimatedDuration().round();
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
