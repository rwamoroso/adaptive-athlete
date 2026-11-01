import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_providers.dart';
import '../../core/utils/date_utils.dart';
import '../ui/clinical_widgets.dart';
import 'cardio_activity.dart';
import 'workout_day_detail_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _refresh = 0;

  Future<_ProgressSnapshot> _load() async {
    final db = ref.read(appDbProvider);
    final workoutDao = ref.read(workoutDaoProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last7Start = today.subtract(const Duration(days: 6));
    final last30Start = today.subtract(const Duration(days: 29));

    final allDays = await workoutDao.listDays();
    final recentDays = allDays
        .where((day) => !parseYmd(day.workoutDate).isBefore(last30Start))
        .take(40)
        .toList(growable: false);
    final details = await Future.wait(
      recentDays.map((day) => workoutDao.getDay(day.workoutDate)),
    );

    final planRows = await db.customSelect(
      '''
      select estimated_date, session_type
      from plan_days
      where estimated_date >= ? and estimated_date <= ?
      order by estimated_date
      ''',
      variables: [
        Variable.withString(toYmd(last7Start)),
        Variable.withString(toYmd(today)),
      ],
    ).get();
    final plannedDates = <String>{};
    for (final row in planRows) {
      final date = row.data['estimated_date']?.toString();
      final session = row.data['session_type']?.toString().toLowerCase() ?? '';
      if (date != null && date.isNotEmpty && !session.contains('rest')) {
        plannedDates.add(date);
      }
    }

    final sleepRows = await db.customSelect(
      '''
      select sleep_date, total_sleep_min
      from sleep_nights
      where sleep_date >= ? and sleep_date <= ?
      order by sleep_date
      ''',
      variables: [
        Variable.withString(toYmd(last7Start)),
        Variable.withString(toYmd(today)),
      ],
    ).get();
    final sleepByDate = <String, int>{};
    for (final row in sleepRows) {
      final date = row.data['sleep_date']?.toString();
      final raw = row.data['total_sleep_min'];
      final minutes = raw is int ? raw : int.tryParse('$raw');
      if (date != null && minutes != null && minutes > 0) {
        sleepByDate[date] = minutes;
      }
    }

    final completedDates = <String>{};
    var cardioSessions30 = 0;
    var runningMeters30 = 0.0;
    var strengthVolume30 = 0.0;
    final summaries = <_DayProgress>[];
    for (final detail in details) {
      final strengthSets = detail.groups
          .expand((group) => group.actual)
          .where((set) => set.source != 'manual_skip')
          .toList(growable: false);
      final cardioSessions = detail.runSessions.length;
      final distance = detail.runSessions.fold<double>(0, (sum, run) {
        if (!CardioActivity.isRunningSession(
          activityType: run.session.activityType,
          title: run.session.title,
          treadmill: run.session.treadmill ?? false,
        )) {
          return sum;
        }
        return sum + (run.session.distanceM ?? 0);
      });
      final volume = strengthSets.fold<double>(
        0,
        (sum, set) => sum + ((set.weight ?? 0) * (set.reps ?? 0)),
      );
      if (strengthSets.isNotEmpty || cardioSessions > 0) {
        completedDates.add(detail.date);
      }
      cardioSessions30 += cardioSessions;
      runningMeters30 += distance;
      strengthVolume30 += volume;
      summaries.add(
        _DayProgress(
          date: detail.date,
          strengthSets: strengthSets.length,
          cardioSessions: cardioSessions,
          runningMeters: distance,
          strengthVolume: volume,
        ),
      );
    }

    final last7Completed = completedDates
        .where((date) => !parseYmd(date).isBefore(last7Start))
        .length;
    final adherence = plannedDates.isEmpty
        ? null
        : plannedDates.where(completedDates.contains).length /
            plannedDates.length;
    final averageSleepMinutes = sleepByDate.isEmpty
        ? null
        : sleepByDate.values.reduce((a, b) => a + b) ~/ sleepByDate.length;

    return _ProgressSnapshot(
      sessionsLast7: last7Completed,
      adherence: adherence,
      plannedDates: plannedDates,
      completedDates: completedDates,
      cardioSessions30: cardioSessions30,
      runningMeters30: runningMeters30,
      strengthVolume30: strengthVolume30,
      averageSleepMinutes: averageSleepMinutes,
      sleepSamples: sleepByDate.length,
      recent: summaries,
      today: today,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProgressSnapshot>(
      key: ValueKey(_refresh),
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _ProgressError(
            onRetry: () => setState(() => _refresh++),
          );
        }
        final progress = snapshot.requireData;
        return RefreshIndicator(
          onRefresh: () async => setState(() => _refresh++),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                sliver: SliverList.list(
                  children: [
                    Text(
                      'Progress',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Training consistency, workload, cardio, and recovery at a glance.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.45,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        MetricTile(
                          title: 'Sessions',
                          valueText: '${progress.sessionsLast7}',
                          subtitleText: 'Completed in 7 days',
                          leadingIcon: Icons.check_circle_outline,
                        ),
                        MetricTile(
                          title: 'Plan',
                          valueText: progress.adherence == null
                              ? '—'
                              : '${(progress.adherence! * 100).round()}%',
                          subtitleText: progress.adherence == null
                              ? 'No planned sessions this week'
                              : '7-day adherence',
                          leadingIcon: Icons.event_available_outlined,
                        ),
                        MetricTile(
                          title: 'Running',
                          valueText:
                              '${(progress.runningMeters30 / 1609.344).toStringAsFixed(1)} mi',
                          subtitleText:
                              '${progress.cardioSessions30} cardio sessions • 30 days',
                          leadingIcon: Icons.directions_run_outlined,
                        ),
                        MetricTile(
                          title: 'Strength',
                          valueText: _formatVolume(progress.strengthVolume30),
                          subtitleText: 'Total volume • 30 days',
                          leadingIcon: Icons.fitness_center_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const SectionHeader(text: 'Last 7 Days'),
                    const SizedBox(height: 8),
                    _ConsistencyCard(progress: progress),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: Row(
                        children: [
                          const Icon(Icons.bedtime_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Average sleep',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  progress.averageSleepMinutes == null
                                      ? 'No sleep data yet'
                                      : '${_formatMinutes(progress.averageSleepMinutes!)} from ${progress.sleepSamples} night${progress.sleepSamples == 1 ? '' : 's'}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const SectionHeader(text: 'Recent Activity'),
                    const SizedBox(height: 8),
                    if (progress.recent.isEmpty)
                      const GlassCard(
                        child: Text(
                          'No activity yet. Complete a workout or sync Apple Health to start your progress view.',
                        ),
                      ),
                  ],
                ),
              ),
              if (progress.recent.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList.builder(
                    itemCount: progress.recent.length,
                    itemBuilder: (context, index) {
                      final day = progress.recent[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  WorkoutDayDetailScreen(date: day.date),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.insights_outlined),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _friendlyDate(day.date),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      day.summary,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (progress.recent.isEmpty)
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressSnapshot {
  const _ProgressSnapshot({
    required this.sessionsLast7,
    required this.adherence,
    required this.plannedDates,
    required this.completedDates,
    required this.cardioSessions30,
    required this.runningMeters30,
    required this.strengthVolume30,
    required this.averageSleepMinutes,
    required this.sleepSamples,
    required this.recent,
    required this.today,
  });

  final int sessionsLast7;
  final double? adherence;
  final Set<String> plannedDates;
  final Set<String> completedDates;
  final int cardioSessions30;
  final double runningMeters30;
  final double strengthVolume30;
  final int? averageSleepMinutes;
  final int sleepSamples;
  final List<_DayProgress> recent;
  final DateTime today;
}

class _DayProgress {
  const _DayProgress({
    required this.date,
    required this.strengthSets,
    required this.cardioSessions,
    required this.runningMeters,
    required this.strengthVolume,
  });

  final String date;
  final int strengthSets;
  final int cardioSessions;
  final double runningMeters;
  final double strengthVolume;

  String get summary {
    final parts = <String>[];
    if (strengthSets > 0) {
      parts.add('$strengthSets strength set${strengthSets == 1 ? '' : 's'}');
    }
    if (cardioSessions > 0) {
      parts.add(
        '$cardioSessions cardio session${cardioSessions == 1 ? '' : 's'}',
      );
    }
    if (runningMeters > 0) {
      parts.add('${(runningMeters / 1609.344).toStringAsFixed(1)} mi');
    }
    if (strengthVolume > 0) {
      parts.add('${_formatVolume(strengthVolume)} volume');
    }
    return parts.isEmpty ? 'Workout day created' : parts.join(' • ');
  }
}

class _ConsistencyCard extends StatelessWidget {
  const _ConsistencyCard({required this.progress});

  final _ProgressSnapshot progress;

  @override
  Widget build(BuildContext context) {
    final start = progress.today.subtract(const Duration(days: 6));
    const weekdays = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return GlassCard(
      child: Row(
        children: List.generate(7, (index) {
          final date = start.add(Duration(days: index));
          final ymd = toYmd(date);
          final planned = progress.plannedDates.contains(ymd);
          final completed = progress.completedDates.contains(ymd);
          final color = completed
              ? Theme.of(context).colorScheme.primary
              : planned
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.white.withValues(alpha: 0.12);
          return Expanded(
            child: Semantics(
              label:
                  '$ymd, ${completed ? 'completed' : planned ? 'planned' : 'not planned'}',
              child: Column(
                children: [
                  Text(weekdays[date.weekday - 1]),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: completed
                        ? 42
                        : planned
                            ? 28
                            : 12,
                    width: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${date.day}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ProgressError extends StatelessWidget {
  const _ProgressError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36),
            const SizedBox(height: 10),
            const Text('Progress could not be loaded.'),
            const SizedBox(height: 10),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

String _formatVolume(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toStringAsFixed(0);
}

String _formatMinutes(int minutes) => '${minutes ~/ 60}h ${minutes % 60}m';

String _friendlyDate(String ymd) {
  final date = parseYmd(ymd);
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
