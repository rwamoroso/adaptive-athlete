import 'dart:convert';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_providers.dart';
import '../../core/utils/date_utils.dart';
import '../ui/clinical_widgets.dart';
import 'cardio_activity.dart';
import 'weekly_consistency.dart';
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
    final previous7Start = today.subtract(const Duration(days: 13));
    final last30Start = today.subtract(const Duration(days: 29));
    final currentWeekStart = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1),
    );
    final streakWindowStart = DateTime(
      currentWeekStart.year,
      currentWeekStart.month,
      currentWeekStart.day - (7 * 11),
    );

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
        Variable.withString(toYmd(streakWindowStart)),
        Variable.withString(toYmd(today)),
      ],
    ).get();
    final plannedDates = <String>{};
    final previousPlannedDates = <String>{};
    final streakPlannedDates = <String>{};
    for (final row in planRows) {
      final date = row.data['estimated_date']?.toString();
      final session = row.data['session_type']?.toString().toLowerCase() ?? '';
      if (date != null && date.isNotEmpty && !session.contains('rest')) {
        streakPlannedDates.add(date);
        if (date.compareTo(toYmd(last7Start)) >= 0) {
          plannedDates.add(date);
        } else if (date.compareTo(toYmd(previous7Start)) >= 0) {
          previousPlannedDates.add(date);
        }
      }
    }

    final completedDateRows = await db.customSelect(
      '''
      select distinct wd.workout_date
      from workout_days wd
      where wd.workout_date >= ? and wd.workout_date <= ?
        and (
          exists (
            select 1 from actual_strength_sets sets
            where sets.workout_day_id = wd.id
              and sets.source != 'manual_skip'
              and coalesce(sets.reps, 0) > 0
          )
          or exists (
            select 1 from run_sessions runs
            where runs.workout_day_id = wd.id
          )
        )
      ''',
      variables: [
        Variable.withString(toYmd(streakWindowStart)),
        Variable.withString(toYmd(today)),
      ],
    ).get();
    final streakCompletedDates = completedDateRows
        .map((row) => row.data['workout_date']?.toString())
        .whereType<String>()
        .toSet();
    final weeklyConsistencyStreak = calculateWeeklyConsistencyStreak(
      today: today,
      plannedDates: streakPlannedDates,
      completedDates: streakCompletedDates,
    );

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
    var runningMetersLast7 = 0.0;
    var runningMetersPrevious7 = 0.0;
    var strengthVolumeLast7 = 0.0;
    var strengthVolumePrevious7 = 0.0;
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
      final detailDate = parseYmd(detail.date);
      if (!detailDate.isBefore(last7Start) && !detailDate.isAfter(today)) {
        runningMetersLast7 += distance;
        strengthVolumeLast7 += volume;
      } else if (!detailDate.isBefore(previous7Start) &&
          detailDate.isBefore(last7Start)) {
        runningMetersPrevious7 += distance;
        strengthVolumePrevious7 += volume;
      }
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
    final previous7Completed = completedDates.where((date) {
      final dateValue = parseYmd(date);
      return !dateValue.isBefore(previous7Start) &&
          dateValue.isBefore(last7Start);
    }).length;
    final adherence = plannedDates.isEmpty
        ? null
        : plannedDates.where(completedDates.contains).length /
            plannedDates.length;
    final previousAdherence = previousPlannedDates.isEmpty
        ? null
        : previousPlannedDates.where(completedDates.contains).length /
            previousPlannedDates.length;
    final averageSleepMinutes = sleepByDate.isEmpty
        ? null
        : sleepByDate.values.reduce((a, b) => a + b) ~/ sleepByDate.length;

    return _ProgressSnapshot(
      sessionsLast7: last7Completed,
      sessionsPrevious7: previous7Completed,
      adherence: adherence,
      previousAdherence: previousAdherence,
      weeklyConsistencyStreak: weeklyConsistencyStreak,
      plannedDates: plannedDates,
      completedDates: completedDates,
      cardioSessions30: cardioSessions30,
      runningMeters30: runningMeters30,
      strengthVolume30: strengthVolume30,
      runningMetersLast7: runningMetersLast7,
      runningMetersPrevious7: runningMetersPrevious7,
      strengthVolumeLast7: strengthVolumeLast7,
      strengthVolumePrevious7: strengthVolumePrevious7,
      averageSleepMinutes: averageSleepMinutes,
      sleepSamples: sleepByDate.length,
      recent: summaries,
      today: today,
    );
  }

  @override
  Widget build(BuildContext context) {
    final weeklyResponse =
        ref.watch(latestAiWeeklyPlanResponseProvider).valueOrNull ?? '';
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
                      'How your recent work is shaping the next training block.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    _CoachProgressBrief(progress: progress),
                    const SizedBox(height: 16),
                    _TrainingReasoningCard(response: weeklyResponse),
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
                    if (progress.weeklyConsistencyStreak > 0) ...[
                      const SizedBox(height: 12),
                      GlassCard(
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${progress.weeklyConsistencyStreak} week consistency streak',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'You completed every scheduled session due in ${progress.weeklyConsistencyStreak == 1 ? 'this training week' : 'each of those training weeks'}.',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _CoachProgressBrief extends StatelessWidget {
  const _CoachProgressBrief({required this.progress});

  final _ProgressSnapshot progress;

  String get _headline {
    final adherence = progress.adherence;
    if (adherence == null) return 'Your next step: follow a weekly plan';
    if (adherence >= 0.85) return 'You’re building a strong training rhythm';
    if (adherence >= 0.5) return 'You’re keeping the plan moving';
    return 'A steady reset can get the plan back on track';
  }

  String get _detail {
    final delta = progress.sessionsLast7 - progress.sessionsPrevious7;
    if (delta > 0) {
      return 'You completed $delta more session${delta == 1 ? '' : 's'} than the week before. Keep the next week aligned with the prescribed recovery and workload.';
    }
    if (delta < 0) {
      final fewer = delta.abs();
      return 'You completed $fewer fewer session${fewer == 1 ? '' : 's'} than the week before. Review what fit your schedule and use that to guide the next prescription.';
    }
    return 'You completed the same number of sessions as the prior week. Compare the run and strength work below to see how the workload shifted.';
  }

  String _change(double current, double previous, {int decimals = 0}) {
    final delta = current - previous;
    final sign = delta > 0 ? '+' : '';
    return '$sign${delta.toStringAsFixed(decimals)}';
  }

  Widget _comparison(BuildContext context, String label, String current,
      String previous, String change) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('$current  vs  $previous', style: style),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            child: Text(change,
                textAlign: TextAlign.end,
                style: style?.copyWith(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adherence = progress.adherence;
    final value = adherence?.clamp(0.0, 1.0).toDouble() ?? 0.0;
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome_outlined,
                    color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Coach’s read', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 3),
                    Text(_headline,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(_detail, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Text('Last 7 days  vs  previous 7 days',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              )),
          _comparison(
            context,
            'Sessions',
            '${progress.sessionsLast7}',
            '${progress.sessionsPrevious7}',
            _change(progress.sessionsLast7.toDouble(),
                progress.sessionsPrevious7.toDouble()),
          ),
          _comparison(
            context,
            'Running',
            '${(progress.runningMetersLast7 / 1609.344).toStringAsFixed(1)} mi',
            '${(progress.runningMetersPrevious7 / 1609.344).toStringAsFixed(1)} mi',
            '${_change(progress.runningMetersLast7 / 1609.344, progress.runningMetersPrevious7 / 1609.344, decimals: 1)} mi',
          ),
          _comparison(
            context,
            'Strength volume',
            _formatVolume(progress.strengthVolumeLast7),
            _formatVolume(progress.strengthVolumePrevious7),
            _change(
                progress.strengthVolumeLast7, progress.strengthVolumePrevious7),
          ),
          if (adherence != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(value: value, minHeight: 7),
            ),
            const SizedBox(height: 4),
            Text(
              'Plan completion ${(adherence * 100).round()}%${progress.previousAdherence == null ? '' : ' • previous week ${(progress.previousAdherence! * 100).round()}%'}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

Map<String, String> _planRationale(String response) {
  final lines = const LineSplitter().convert(response);
  final start = lines.indexWhere(
    (line) => line.trim().toUpperCase() == 'PLAN_EXPLANATION_V1',
  );
  if (start < 0) return const {};
  final result = <String, String>{};
  for (var index = start + 1; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.toUpperCase() == 'END_PLAN_EXPLANATION_V1') break;
    final colon = line.indexOf(':');
    if (colon <= 0) continue;
    final key = line.substring(0, colon).trim().toUpperCase();
    final value = line.substring(colon + 1).trim();
    if (value.isNotEmpty) result[key] = value;
  }
  return result;
}

class _TrainingReasoningCard extends StatelessWidget {
  const _TrainingReasoningCard({required this.response});

  final String response;

  @override
  Widget build(BuildContext context) {
    final rationale = _planRationale(response);
    final theme = Theme.of(context);
    final why = rationale['WHY_THIS_WEEK'];
    final adaptation = rationale['ADAPTATION_OR_GROWTH'];
    final logic = rationale['LOGIC_OVERVIEW'];
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_alt_outlined,
                  color: theme.colorScheme.primary),
              const SizedBox(width: 9),
              Text('Why this training?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          if (why == null && adaptation == null && logic == null)
            Text(
              'A written rationale has not been saved with the current plan yet. When the plan includes its explanation, it will appear here.',
              style: theme.textTheme.bodySmall,
            )
          else ...[
            if (why != null) _reasonParagraph(context, 'Why this week', why),
            if (adaptation != null)
              _reasonParagraph(context, 'Training effect', adaptation),
            if (logic != null)
              _reasonParagraph(context, 'Load and recovery', logic),
          ],
        ],
      ),
    );
  }

  Widget _reasonParagraph(BuildContext context, String heading, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: 3),
          Text(body, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ProgressSnapshot {
  const _ProgressSnapshot({
    required this.sessionsLast7,
    required this.sessionsPrevious7,
    required this.adherence,
    required this.previousAdherence,
    required this.weeklyConsistencyStreak,
    required this.plannedDates,
    required this.completedDates,
    required this.cardioSessions30,
    required this.runningMeters30,
    required this.strengthVolume30,
    required this.runningMetersLast7,
    required this.runningMetersPrevious7,
    required this.strengthVolumeLast7,
    required this.strengthVolumePrevious7,
    required this.averageSleepMinutes,
    required this.sleepSamples,
    required this.recent,
    required this.today,
  });

  final int sessionsLast7;
  final int sessionsPrevious7;
  final double? adherence;
  final double? previousAdherence;
  final int weeklyConsistencyStreak;
  final Set<String> plannedDates;
  final Set<String> completedDates;
  final int cardioSessions30;
  final double runningMeters30;
  final double strengthVolume30;
  final double runningMetersLast7;
  final double runningMetersPrevious7;
  final double strengthVolumeLast7;
  final double strengthVolumePrevious7;
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
