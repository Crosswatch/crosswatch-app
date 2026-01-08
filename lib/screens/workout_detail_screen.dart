import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../widgets/workout_card.dart';
import 'workout_builder_screen.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final Workout workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(workout.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      WorkoutBuilderScreen(existingWorkout: workout),
                ),
              );
            },
            tooltip: 'Edit Workout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (workout.description != null) ...[
              Text(
                workout.description!,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Icon(Icons.timer, size: 20),
                const SizedBox(width: 4),
                Text(
                  'Estimated: ${workout.formattedDuration()}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Sets',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...workout.sets.map(
              (set) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: WorkoutCard(set: set),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
