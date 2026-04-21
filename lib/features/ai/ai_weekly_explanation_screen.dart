import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_providers.dart';
import '../ui/clinical_widgets.dart';

class AiWeeklyExplanationScreen extends ConsumerWidget {
  const AiWeeklyExplanationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveResponse = ref.watch(aiWeeklyPlanResponseProvider).trim();
    final savedResponse =
        ref.watch(latestAiWeeklyPlanResponseProvider).valueOrNull?.trim() ?? '';
    final rawResponse = liveResponse.isNotEmpty ? liveResponse : savedResponse;
    final explanation = _extractPlanExplanation(rawResponse);
    final weeklyPlanDays = _extractWeeklyPlanDays(rawResponse);
    final tenWeekRows = _extractTenWeekRows(rawResponse);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        Text(
          'AI WEEKLY EXPLANATION',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        const ClinicalBanner(
          text:
              'Paste AI weekly response in Plan > Step 3. This tab presents weekly explanation, weekly plan, and the 10-week plan.',
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(text: 'Weekly Explanation'),
              const SizedBox(height: 8),
              if (explanation == null)
                const Text(
                  'No PLAN_EXPLANATION_V1 block found yet. Paste and apply AI response from Plan > Step 3.',
                )
              else ...[
                Text(
                  'Why am I training like this for the week?\n${explanation.whyThisWeek.isEmpty ? 'Not provided.' : explanation.whyThisWeek}',
                ),
                const SizedBox(height: 10),
                Text(
                  'What adaptation or growth does the week provide to my body?\n${explanation.adaptationOrGrowth.isEmpty ? 'Not provided.' : explanation.adaptationOrGrowth}',
                ),
                if (explanation.logicOverview.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Logic overview:\n${explanation.logicOverview}'),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(text: 'Weekly Plan'),
              const SizedBox(height: 8),
              if (weeklyPlanDays.isEmpty)
                const Text(
                  'No WEEK_PLAN_V1 block found in the latest AI response yet.',
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < weeklyPlanDays.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 88,
                              child: Text(
                                weeklyPlanDays[i].dayLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (weeklyPlanDays[i].cardioTitle != null)
                                    Text(
                                      'Cardio: ${weeklyPlanDays[i].cardioTitle}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  if (weeklyPlanDays[i].strengthTitle != null)
                                    Text(
                                      'Strength: ${weeklyPlanDays[i].strengthTitle}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  if (weeklyPlanDays[i].cardioTitle == null &&
                                      weeklyPlanDays[i].strengthTitle == null)
                                    Text(
                                      'Rest / Recovery',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i != weeklyPlanDays.length - 1)
                        const Divider(height: 1),
                    ],
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(text: '10-Week Plan'),
              const SizedBox(height: 8),
              if (tenWeekRows.isEmpty)
                const Text(
                  'No TEN_WEEK_PLAN_UPDATE_V1 block found in the latest AI response yet.',
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 14,
                    columns: const [
                      DataColumn(label: Text('Week')),
                      DataColumn(label: Text('Start')),
                      DataColumn(label: Text('End')),
                      DataColumn(label: Text('Run Focus')),
                      DataColumn(label: Text('Strength Focus')),
                      DataColumn(label: Text('Strength Expectation')),
                      DataColumn(label: Text('Primary Target')),
                      DataColumn(label: Text('Recovery')),
                      DataColumn(label: Text('Deload')),
                      DataColumn(label: Text('Notes')),
                    ],
                    rows: tenWeekRows
                        .map(
                          (row) => DataRow(
                            cells: [
                              DataCell(Text(row.week)),
                              DataCell(Text(row.weekStart)),
                              DataCell(Text(row.weekEnd)),
                              DataCell(Text(row.runFocus)),
                              DataCell(Text(row.strengthFocus)),
                              DataCell(
                                  Text(row.strengthProgressionExpectation)),
                              DataCell(Text(row.primaryProgressionTarget)),
                              DataCell(Text(row.recoveryEmphasis)),
                              DataCell(Text(row.deload)),
                              DataCell(Text(row.notes)),
                            ],
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanExplanationView {
  const _PlanExplanationView({
    required this.whyThisWeek,
    required this.adaptationOrGrowth,
    required this.logicOverview,
  });

  final String whyThisWeek;
  final String adaptationOrGrowth;
  final String logicOverview;
}

class _TenWeekRowView {
  const _TenWeekRowView({
    required this.week,
    required this.weekStart,
    required this.weekEnd,
    required this.runFocus,
    required this.strengthFocus,
    required this.strengthProgressionExpectation,
    required this.primaryProgressionTarget,
    required this.recoveryEmphasis,
    required this.deload,
    required this.notes,
  });

  final String week;
  final String weekStart;
  final String weekEnd;
  final String runFocus;
  final String strengthFocus;
  final String strengthProgressionExpectation;
  final String primaryProgressionTarget;
  final String recoveryEmphasis;
  final String deload;
  final String notes;
}

class _WeeklyPlanDayView {
  const _WeeklyPlanDayView({
    required this.dayNumber,
    required this.dayLabel,
    required this.cardioTitle,
    required this.strengthTitle,
  });

  final int dayNumber;
  final String dayLabel;
  final String? cardioTitle;
  final String? strengthTitle;
}

_PlanExplanationView? _extractPlanExplanation(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final lines = LineSplitter().convert(trimmed);
  final start = lines.indexWhere(
    (line) => line.trim().toUpperCase() == 'PLAN_EXPLANATION_V1',
  );
  if (start < 0) {
    return null;
  }

  var end = -1;
  for (var i = start + 1; i < lines.length; i++) {
    if (lines[i].trim().toUpperCase() == 'END_PLAN_EXPLANATION_V1') {
      end = i;
      break;
    }
  }
  final endIndex = end < 0 ? lines.length : end;

  String whyThisWeek = '';
  String adaptationOrGrowth = '';
  String logicOverview = '';

  for (var i = start + 1; i < endIndex; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) {
      continue;
    }
    final colon = line.indexOf(':');
    if (colon <= 0) {
      continue;
    }
    final key = line.substring(0, colon).trim().toUpperCase();
    final value = line.substring(colon + 1).trim();
    switch (key) {
      case 'WHY_THIS_WEEK':
        whyThisWeek = value;
        break;
      case 'ADAPTATION_OR_GROWTH':
        adaptationOrGrowth = value;
        break;
      case 'LOGIC_OVERVIEW':
        logicOverview = value;
        break;
    }
  }

  if (whyThisWeek.isEmpty &&
      adaptationOrGrowth.isEmpty &&
      logicOverview.isEmpty) {
    return null;
  }
  return _PlanExplanationView(
    whyThisWeek: whyThisWeek,
    adaptationOrGrowth: adaptationOrGrowth,
    logicOverview: logicOverview,
  );
}

List<_TenWeekRowView> _extractTenWeekRows(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return const <_TenWeekRowView>[];
  }
  final lines = LineSplitter().convert(trimmed);
  final start = lines.indexWhere(
    (line) => line.trim().toUpperCase() == 'TEN_WEEK_PLAN_UPDATE_V1',
  );
  if (start < 0) {
    return const <_TenWeekRowView>[];
  }

  final rows = <_TenWeekRowView>[];
  for (var i = start + 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) {
      continue;
    }
    if (line.toUpperCase() == 'END_TEN_WEEK_PLAN_UPDATE_V1') {
      break;
    }
    if (!line.startsWith('TEN_WEEK_ROW:')) {
      continue;
    }
    final payload = line.substring('TEN_WEEK_ROW:'.length).trim();
    final map = <String, String>{};
    final parts = payload
        .split('|')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    for (final part in parts) {
      final eq = part.indexOf('=');
      if (eq <= 0) {
        continue;
      }
      final key = part.substring(0, eq).trim().toLowerCase();
      final value = part.substring(eq + 1).trim();
      if (key.isEmpty) {
        continue;
      }
      map[key] = value;
    }
    rows.add(
      _TenWeekRowView(
        week: map['week'] ?? '',
        weekStart: map['week_start'] ?? '',
        weekEnd: map['week_end'] ?? '',
        runFocus: map['run_focus'] ?? '',
        strengthFocus: map['strength_focus'] ?? '',
        strengthProgressionExpectation:
            map['strength_progression_expectation'] ?? '',
        primaryProgressionTarget: map['primary_progression_target'] ?? '',
        recoveryEmphasis: map['recovery_emphasis'] ?? '',
        deload: map['deload'] ?? '',
        notes: map['notes'] ?? '',
      ),
    );
  }
  return List<_TenWeekRowView>.unmodifiable(rows);
}

List<_WeeklyPlanDayView> _extractWeeklyPlanDays(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return const <_WeeklyPlanDayView>[];
  }
  final lines = LineSplitter().convert(trimmed);
  final start = lines.indexWhere(
    (line) => line.trim().toUpperCase() == 'WEEK_PLAN_V1',
  );
  if (start < 0) {
    return const <_WeeklyPlanDayView>[];
  }

  final rows = <_WeeklyPlanDayView>[];
  var i = start + 1;
  while (i < lines.length) {
    final line = lines[i].trim();
    final upper = line.toUpperCase();
    if (upper == 'END WEEK_PLAN_V1') {
      break;
    }
    if (!upper.startsWith('DAY ')) {
      i += 1;
      continue;
    }
    final dayNumber = int.tryParse(line.substring(4).trim());
    if (dayNumber == null) {
      i += 1;
      continue;
    }
    final blockLines = <String>[];
    i += 1;
    while (i < lines.length) {
      final current = lines[i].trim();
      final currentUpper = current.toUpperCase();
      if (currentUpper == 'END DAY $dayNumber') {
        i += 1;
        break;
      }
      if (currentUpper.startsWith('DAY ')) {
        break;
      }
      blockLines.add(current);
      i += 1;
    }
    rows.add(_parseWeeklyPlanDayBlock(dayNumber: dayNumber, lines: blockLines));
  }

  rows.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
  return List<_WeeklyPlanDayView>.unmodifiable(rows);
}

_WeeklyPlanDayView _parseWeeklyPlanDayBlock({
  required int dayNumber,
  required List<String> lines,
}) {
  final kv = <String, String>{};
  final strengthExercises = <String>{};
  var strengthLineValue = '';
  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      continue;
    }
    final upper = line.toUpperCase();
    if (upper.startsWith('STRENGTH_SET:')) {
      final payload = line.substring('STRENGTH_SET:'.length).trim();
      final exercise = payload.split('|').first.trim();
      if (exercise.isNotEmpty) {
        strengthExercises.add(_humanizeToken(exercise));
      }
      continue;
    }
    if (upper.startsWith('STRENGTH:')) {
      strengthLineValue = line.substring('STRENGTH:'.length).trim();
    }
    final colon = line.indexOf(':');
    if (colon <= 0) {
      continue;
    }
    final key = line.substring(0, colon).trim().toUpperCase();
    final value = line.substring(colon + 1).trim();
    kv[key] = value;
  }

  final dayLabelRaw = kv['DAY_LABEL'] ?? '';
  final dateRaw = kv['DATE'] ?? '';
  final runType = kv['RUN_TYPE'] ?? '';
  final runDuration = kv['RUN_DURATION'] ?? '';
  final runNotes = kv['RUN_NOTES'] ?? '';
  final sessionType = kv['SESSION_TYPE'] ?? '';
  final liftFocus = kv['LIFT_FOCUS'] ?? '';

  final cardioTitle = _buildCardioSummary(
    runType: runType,
    runDuration: runDuration,
    runNotes: runNotes,
  );
  final strengthTitle = _buildStrengthSummary(
    sessionType: sessionType,
    liftFocus: liftFocus,
    strengthLineValue: strengthLineValue,
    exerciseCount: strengthExercises.length,
  );

  final dayLabel = dayLabelRaw.isNotEmpty
      ? dayLabelRaw
      : _fallbackDayLabel(dayNumber, dateRaw);
  return _WeeklyPlanDayView(
    dayNumber: dayNumber,
    dayLabel: dayLabel,
    cardioTitle: cardioTitle,
    strengthTitle: strengthTitle,
  );
}

String _fallbackDayLabel(int dayNumber, String dateRaw) {
  final parsedDate = DateTime.tryParse(dateRaw);
  if (parsedDate == null) {
    return 'Day $dayNumber';
  }
  const weekdays = <int, String>{
    DateTime.monday: 'Mon',
    DateTime.tuesday: 'Tue',
    DateTime.wednesday: 'Wed',
    DateTime.thursday: 'Thu',
    DateTime.friday: 'Fri',
    DateTime.saturday: 'Sat',
    DateTime.sunday: 'Sun',
  };
  final shortWeekday = weekdays[parsedDate.weekday] ?? 'Day';
  return '$shortWeekday ${parsedDate.month}/${parsedDate.day}';
}

String? _buildCardioSummary({
  required String runType,
  required String runDuration,
  required String runNotes,
}) {
  final normalizedType = runType.trim().toLowerCase();
  final duration = runDuration.trim();
  if (normalizedType.isNotEmpty && normalizedType != 'none') {
    final title = _humanizeToken(normalizedType);
    if (duration.isNotEmpty) {
      return '$title • $duration';
    }
    return title;
  }
  if (duration.isNotEmpty) {
    return duration;
  }
  final notes = runNotes.trim();
  if (notes.toLowerCase().startsWith('no run')) {
    return null;
  }
  return null;
}

String? _buildStrengthSummary({
  required String sessionType,
  required String liftFocus,
  required String strengthLineValue,
  required int exerciseCount,
}) {
  if (exerciseCount > 0) {
    final session = _humanizeToken(sessionType);
    final base = session.isEmpty ? 'Strength' : session;
    return '$base ($exerciseCount exercises)';
  }
  final strengthRaw = strengthLineValue.trim();
  if (strengthRaw.isNotEmpty && strengthRaw.toLowerCase() != 'none') {
    return strengthRaw;
  }
  final lift = liftFocus.trim();
  if (lift.isNotEmpty) {
    return lift;
  }
  return null;
}

String _humanizeToken(String raw) {
  final text = raw
      .trim()
      .replaceAll(RegExp(r'[_\-\s]+'), ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map(
        (part) =>
            '${part.substring(0, 1).toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
  return text;
}
