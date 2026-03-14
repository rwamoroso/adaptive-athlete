import 'dart:convert';

import 'package:adaptive_athlete/db/app_db.dart' show AppDb;
import 'package:adaptive_athlete/features/plan/weekly_plan_prompt_service.dart';
import 'package:adaptive_athlete/features/plan/weekly_planner_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

PlannerPromptContext _contextWithSummary(Map<String, dynamic> summary) {
  return PlannerPromptContext(
    profile: const AthletePlanningProfile(
      workspaceId: 'local_workspace',
      athleteProfileId: 'local_profile',
      primaryGoal: 'run_goal',
      goalTarget: {
        'distance_miles': 5,
        'target_pace': '8:30/mi',
        'text': '5 miles @ 8:30/mi',
      },
      experienceLevel: 'intermediate',
      preferredSplit: SplitType.hybridRunLift,
      daysPerWeek: 5,
      availableEquipment: {'barbell', 'dumbbell', 'bodyweight'},
      contraindications: <String>{},
      scheduleConstraints: {
        'notes': '',
        'preferred_training_weekdays': [1, 2, 3, 4, 5],
      },
    ),
    weekStart: '2026-03-23',
    weekEnd: '2026-03-29',
    splitType: SplitType.hybridRunLift,
    modifier: WeeklyPlanModifier.followLongTerm,
    propagateLongTermChanges: false,
    longRangeContextRows: const <Map<String, dynamic>>[],
    recentMetricsSummary: summary,
    additionalInstructions: null,
  );
}

Map<String, dynamic> _fullRecentMetricsSummary() {
  return {
    'window_basis': 'standard_workbook_export',
    'plan_week_start': '2026-03-23',
    'window_start': '2026-03-01',
    'window_end': '2026-03-21',
    'window_days': 21,
    'strength': {
      'set_count': 7,
      'training_days': 4,
      'top_exercises': [
        {'exercise': 'back_squat', 'set_count': 3},
        {'exercise': 'bench_press', 'set_count': 2},
        {'exercise': 'romanian_deadlift', 'set_count': 2},
      ],
      'history_rows': [
        {
          'workout_date': '2026-03-03',
          'exercise': 'back_squat',
          'set_index': 1,
          'weight': 185,
          'reps': 5,
          'rir': 2,
          'unit': 'lb',
        },
        {
          'workout_date': '2026-03-08',
          'exercise': 'bench_press',
          'set_index': 1,
          'weight': 140,
          'reps': 8,
          'rir': 2,
          'unit': 'lb',
        },
        {
          'workout_date': '2026-03-10',
          'exercise': 'romanian_deadlift',
          'set_index': 1,
          'weight': 205,
          'reps': 6,
          'rir': 2,
          'unit': 'lb',
        },
        {
          'workout_date': '2026-03-16',
          'exercise': 'back_squat',
          'set_index': 2,
          'weight': 195,
          'reps': 5,
          'rir': 1,
          'unit': 'lb',
        },
        {
          'workout_date': '2026-03-18',
          'exercise': 'back_squat',
          'set_index': 3,
          'weight': 205,
          'reps': 4,
          'rir': 1,
          'unit': 'lb',
        },
        {
          'workout_date': '2026-03-19',
          'exercise': 'bench_press',
          'set_index': 2,
          'weight': 145,
          'reps': 8,
          'rir': 1,
          'unit': 'lb',
        },
        {
          'workout_date': '2026-03-20',
          'exercise': 'romanian_deadlift',
          'set_index': 2,
          'weight': 215,
          'reps': 6,
          'rir': 1,
          'unit': 'lb',
        },
      ],
    },
    'run': {
      'session_count': 6,
      'total_distance_m': 34700,
      'total_duration_s': 11880,
      'avg_hr': 149,
      'max_hr': 178,
      'history_rows': [
        {
          'workout_date': '2026-03-02',
          'duration_s': 1680,
          'distance_m': 4200,
          'avg_hr': 145,
        },
        {
          'workout_date': '2026-03-06',
          'duration_s': 1860,
          'distance_m': 5000,
          'avg_hr': 147,
        },
        {
          'workout_date': '2026-03-11',
          'duration_s': 2160,
          'distance_m': 6200,
          'avg_hr': 149,
        },
        {
          'workout_date': '2026-03-15',
          'duration_s': 2280,
          'distance_m': 7000,
          'avg_hr': 150,
        },
        {
          'workout_date': '2026-03-18',
          'duration_s': 2100,
          'distance_m': 6400,
          'avg_hr': 151,
        },
        {
          'workout_date': '2026-03-20',
          'duration_s': 1800,
          'distance_m': 5900,
          'avg_hr': 152,
        },
      ],
    },
    'sleep': {
      'nights_count': 8,
      'avg_total_sleep_min': 407,
      'history_rows': [
        {'sleep_date': '2026-03-02', 'total_sleep_min': 390},
        {'sleep_date': '2026-03-05', 'total_sleep_min': 430},
        {'sleep_date': '2026-03-08', 'total_sleep_min': 410},
        {'sleep_date': '2026-03-12', 'total_sleep_min': 395},
        {'sleep_date': '2026-03-14', 'total_sleep_min': 365},
        {'sleep_date': '2026-03-16', 'total_sleep_min': 405},
        {'sleep_date': '2026-03-19', 'total_sleep_min': 420},
        {'sleep_date': '2026-03-20', 'total_sleep_min': 440},
      ],
    },
    'workout_dates_with_activity': [
      '2026-03-02',
      '2026-03-03',
      '2026-03-06',
      '2026-03-08',
      '2026-03-10',
      '2026-03-11',
      '2026-03-15',
      '2026-03-16',
      '2026-03-18',
      '2026-03-19',
      '2026-03-20',
    ],
  };
}

Map<String, dynamic> _corruptedRunSummary() {
  final base = _fullRecentMetricsSummary();
  final run = Map<String, dynamic>.from(base['run'] as Map<String, dynamic>);
  final rows = List<Map<String, dynamic>>.from(
    (run['history_rows'] as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map)),
  );
  rows.add({
    'workout_date': '2026-03-19',
    'duration_s': 1200,
    'distance_m': 22000,
    'avg_hr': 120,
  });
  run['history_rows'] = rows;
  base['run'] = run;
  return base;
}

Map<String, dynamic>? _extractSectionJson(
    String promptText, String sectionName) {
  final exp = RegExp(
    '=== $sectionName ===\\n([\\s\\S]*?)\\n=== END_$sectionName ===',
  );
  final match = exp.firstMatch(promptText);
  if (match == null) {
    return null;
  }
  final raw = match.group(1)!;
  final decoded = jsonDecode(raw);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  if (decoded is Map) {
    return decoded.map((k, v) => MapEntry(k.toString(), v));
  }
  return null;
}

void main() {
  test(
      'buildPromptText includes all five derived context sections in fixed order',
      () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final promptService = WeeklyPlanPromptService(db: db);
    await promptService.savePromptOverride('BASE PROMPT');

    final service = WeeklyPlannerService(
      db: db,
      promptService: promptService,
      client: SupabaseClient('https://example.supabase.co', 'anon-key'),
    );

    final promptText = await service.buildPromptText(
      _contextWithSummary(_fullRecentMetricsSummary()),
    );

    const sectionNames = [
      'DERIVED_METRICS_V1',
      'PERFORMANCE_BASELINE_V1',
      'TRAINING_LOAD_V1',
      'PROGRESS_SIGNALS_V1',
      'ADAPTATION_HISTORY_V1',
    ];

    final indexes = <int>[];
    for (final name in sectionNames) {
      final start = '=== $name ===';
      final end = '=== END_$name ===';
      expect(promptText, contains(start));
      expect(promptText, contains(end));
      indexes.add(promptText.indexOf(start));
    }

    for (var i = 1; i < indexes.length; i++) {
      expect(indexes[i], greaterThan(indexes[i - 1]));
    }

    final derived = _extractSectionJson(promptText, 'DERIVED_METRICS_V1');
    expect(derived, isNotNull);
    expect(derived!['window_days'], 21);
    expect(derived.containsKey('data_quality'), isTrue);

    expect(
      promptText.indexOf('Recent Metrics Summary (JSON):'),
      lessThan(promptText.indexOf('=== DERIVED_METRICS_V1 ===')),
    );
    expect(
      promptText.indexOf('=== ADAPTATION_HISTORY_V1 ==='),
      lessThan(promptText.indexOf('=== END_APP_CONTEXT_V1 ===')),
    );
  });

  test(
      'buildPromptText omits all derived sections when metrics summary is empty',
      () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final promptService = WeeklyPlanPromptService(db: db);
    await promptService.savePromptOverride('BASE PROMPT');

    final service = WeeklyPlannerService(
      db: db,
      promptService: promptService,
      client: SupabaseClient('https://example.supabase.co', 'anon-key'),
    );

    final promptText = await service.buildPromptText(
      _contextWithSummary(const <String, dynamic>{}),
    );

    expect(promptText, isNot(contains('=== DERIVED_METRICS_V1 ===')));
    expect(promptText, isNot(contains('=== PERFORMANCE_BASELINE_V1 ===')));
    expect(promptText, isNot(contains('=== TRAINING_LOAD_V1 ===')));
    expect(promptText, isNot(contains('=== PROGRESS_SIGNALS_V1 ===')));
    expect(promptText, isNot(contains('=== ADAPTATION_HISTORY_V1 ===')));
  });

  test('corrupted run rows are excluded and reported in data_quality',
      () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final promptService = WeeklyPlanPromptService(db: db);
    await promptService.savePromptOverride('BASE PROMPT');

    final service = WeeklyPlannerService(
      db: db,
      promptService: promptService,
      client: SupabaseClient('https://example.supabase.co', 'anon-key'),
    );

    final promptText = await service.buildPromptText(
      _contextWithSummary(_corruptedRunSummary()),
    );

    final derived = _extractSectionJson(promptText, 'DERIVED_METRICS_V1');
    expect(derived, isNotNull);

    final quality = Map<String, dynamic>.from(derived!['data_quality'] as Map);
    expect(quality['run_data_valid'], isFalse);
    expect(quality['corrupted_runs_detected'], 1);

    // Original valid rows are 6; corrupted row must not increase run_sessions.
    expect(derived['run_sessions'], 6);
  });

  test('derived prompt context rendering is deterministic', () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final promptService = WeeklyPlanPromptService(db: db);
    await promptService.savePromptOverride('BASE PROMPT');

    final service = WeeklyPlannerService(
      db: db,
      promptService: promptService,
      client: SupabaseClient('https://example.supabase.co', 'anon-key'),
    );

    final context = _contextWithSummary(_fullRecentMetricsSummary());
    final promptA = await service.buildPromptText(context);
    final promptB = await service.buildPromptText(context);

    expect(promptA, equals(promptB));
  });
}
