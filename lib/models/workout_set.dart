/// Represents a set in a workout, which can be either:
/// - A leaf set with reps or time
/// - A container set with nested sets
class WorkoutSet {
  final String name;
  final String? description;
  final SetType? type;
  final double? value;
  final List<WorkoutSet>? sets;
  final int? rounds;
  final double? restBetweenRounds;
  final double? transitionTime;
  final double? duration; // Optional duration for rep-based sets

  WorkoutSet({
    required this.name,
    this.description,
    this.type,
    this.value,
    this.sets,
    this.rounds,
    this.restBetweenRounds,
    this.transitionTime,
    this.duration,
  }) {
    // Validate that this is either a leaf set or container set, not both
    if (sets != null && sets!.isNotEmpty) {
      // Container set - should not have type/value
      if (type != null) {
        throw ArgumentError(
          'Container sets (with nested sets) cannot have type',
        );
      }
    } else {
      // Leaf set - must have type (value is optional for reps)
      if (type == null) {
        throw ArgumentError(
          'Leaf sets (without nested sets) must have a type',
        );
      }
      // Time-based sets must have a value
      if (type == SetType.time && value == null) {
        throw ArgumentError(
          'Time-based sets must have a value',
        );
      }
    }
  }

  /// Check if this is a leaf set (has type)
  bool get isLeaf => type != null;

  /// Check if this is a container set (has nested sets)
  bool get isContainer => sets != null && sets!.isNotEmpty;

  /// Get effective rounds (default to 1 if not specified)
  int get effectiveRounds => rounds ?? 1;
  
  /// Get effective transition time (default to 5 seconds)
  double get effectiveTransitionTime => transitionTime ?? 5.0;

  /// Create from JSON
  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] != null 
          ? SetType.fromString(json['type'] as String)
          : null,
      value: json['value'] != null 
          ? (json['value'] as num).toDouble()
          : null,
      sets: json['sets'] != null
          ? (json['sets'] as List)
              .map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
      rounds: json['rounds'] as int?,
      restBetweenRounds: json['restBetweenRounds'] != null
          ? (json['restBetweenRounds'] as num).toDouble()
          : null,
      transitionTime: json['transitionTime'] != null
          ? (json['transitionTime'] as num).toDouble()
          : null,
      duration: json['duration'] != null
          ? (json['duration'] as num).toDouble()
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'name': name,
    };

    if (description != null) {
      json['description'] = description;
    }

    if (type != null) {
      json['type'] = type!.toString().split('.').last;
    }

    if (value != null) {
      json['value'] = value;
    }

    if (sets != null && sets!.isNotEmpty) {
      json['sets'] = sets!.map((s) => s.toJson()).toList();
    }

    if (rounds != null) {
      json['rounds'] = rounds;
    }

    if (restBetweenRounds != null) {
      json['restBetweenRounds'] = restBetweenRounds;
    }
    
    if (transitionTime != null) {
      json['transitionTime'] = transitionTime;
    }
    
    if (duration != null) {
      json['duration'] = duration;
    }

    return json;
  }
}

/// Type of set - either repetition-based or time-based
enum SetType {
  reps,
  time;

  static SetType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'reps':
        return SetType.reps;
      case 'time':
        return SetType.time;
      default:
        throw ArgumentError('Invalid SetType: $value');
    }
  }
}
