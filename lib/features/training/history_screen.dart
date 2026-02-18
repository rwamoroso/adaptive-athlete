import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_providers.dart';
import '../../db/app_db.dart';
import 'workout_day_detail_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDbProvider);

    return FutureBuilder<List<WorkoutDay>>(
      future: db.listWorkoutDays(desc: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final days = snapshot.data ?? const <WorkoutDay>[];
        if (days.isEmpty) {
          return const Center(child: Text('No workout days yet.'));
        }

        return ListView.builder(
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            return ListTile(
              title: Text(day.workoutDate),
              subtitle: Text('id: ${day.id}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        WorkoutDayDetailScreen(date: day.workoutDate)));
              },
            );
          },
        );
      },
    );
  }
}
