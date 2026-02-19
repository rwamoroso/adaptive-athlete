import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_providers.dart';
import '../../db/app_db.dart';
import '../ui/clinical_widgets.dart';
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

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            const SectionHeader(text: 'Workout History'),
            const SizedBox(height: 8),
            GlassCard(
              child: Text(
                days.isEmpty
                    ? 'No workout days yet.'
                    : '${days.length} workout day entries',
              ),
            ),
            const SizedBox(height: 10),
            if (days.isEmpty)
              const GlassCard(child: Text('No workout days yet.'))
            else
              ...days.map(
                (day) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              WorkoutDayDetailScreen(date: day.workoutDate),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.event_note_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                day.workoutDate,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'id: ${day.id}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
