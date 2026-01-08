import 'package:flutter/material.dart';
import '../models/workout_set.dart';

class WorkoutCard extends StatelessWidget {
  final WorkoutSet set;
  final int depth;

  const WorkoutCard({super.key, required this.set, this.depth = 0});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(left: depth * 16.0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    set.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (set.isLeaf) _buildSetBadge(context),
                if (set.rounds != null && set.rounds! > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${set.rounds}x',
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (set.description != null) ...[
              const SizedBox(height: 4),
              Text(
                set.description!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
            if (set.restBetweenRounds != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.timer_off, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Rest: ${set.restBetweenRounds}s between rounds',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (set.isContainer && set.sets != null) ...[
              const SizedBox(height: 12),
              ...set.sets!.map(
                (childSet) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: WorkoutCard(set: childSet, depth: depth + 1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSetBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isReps = set.type == SetType.reps;
    final color = isReps ? colorScheme.tertiary : colorScheme.secondary;
    final icon = isReps ? Icons.repeat : Icons.timer;
    final text = isReps
        ? '${set.value!.toInt()} reps'
        : '${set.value!.toInt()}s';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
