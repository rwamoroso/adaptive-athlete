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
        final latestDate = days.isEmpty ? 'none' : days.first.workoutDate;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            Text(
              'ATHLETIC ADAPTATION HISTORY',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            const ClinicalBanner(
              text: 'Clinical Focus: Trend Continuity & Session Recall',
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                MetricTile(
                  title: 'Total Days',
                  valueText: '${days.length}',
                  subtitleText: 'Logged workout days',
                  leadingIcon: Icons.calendar_month_outlined,
                ),
                MetricTile(
                  title: 'Latest Entry',
                  valueText: latestDate,
                  subtitleText:
                      days.isEmpty ? 'No sessions yet' : 'Most recent',
                  leadingIcon: Icons.event_note_outlined,
                ),
              ],
            ),
            const SizedBox(height: 14),
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
