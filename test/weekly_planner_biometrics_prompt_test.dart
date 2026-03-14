import 'package:adaptive_athlete/db/app_db.dart' show AppDb;
import 'package:adaptive_athlete/features/plan/weekly_plan_prompt_service.dart';
import 'package:adaptive_athlete/features/plan/weekly_planner_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

PlannerPromptContext _contextWithBiometrics(Map<String, dynamic> biometrics) {
  return PlannerPromptContext(
    profile: AthletePlanningProfile(
      workspaceId: 'local_workspace',
      athleteProfileId: 'local_profile',
      primaryGoal: 'run_goal',
      goalTarget: const {
        'distance_miles': 5,
        'target_pace': '8:45/mi',
        'text': '5 miles @ 8:45/mi',
      },
      experienceLevel: 'intermediate',
      preferredSplit: SplitType.hybridRunLift,
      daysPerWeek: 5,
      availableEquipment: const {'dumbbell', 'barbell'},
      contraindications: const <String>{},
      scheduleConstraints: const {
        'notes': '',
        'preferred_training_weekdays': [1, 2, 3, 4, 5],
      },
      biometrics: biometrics,
    ),
    weekStart: '2026-03-16',
    weekEnd: '2026-03-22',
    splitType: SplitType.hybridRunLift,
    modifier: WeeklyPlanModifier.followLongTerm,
    propagateLongTermChanges: false,
    longRangeContextRows: const <Map<String, dynamic>>[],
    recentMetricsSummary: const <String, dynamic>{},
    additionalInstructions: null,
  );
}

void main() {
  test('buildPromptText includes BIOMETRICS_V1 section when available',
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

    final context = _contextWithBiometrics({
      'age': 32,
      'sex': 'male',
      'height_ft': 5,
      'height_in': 11,
      'weight_lb': 185.0,
      'build_type': 'athletic',
    });

    final promptText = await service.buildPromptText(context);
    expect(promptText, contains('BIOMETRICS_V1 (JSON):'));
    expect(promptText, contains('"height_ft_inchs": "5 ft 11 in"'));
    expect(promptText, contains('"estimated_tdee_kcal":'));
  });

  test('buildPromptText omits BIOMETRICS_V1 section when missing', () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final promptService = WeeklyPlanPromptService(db: db);
    await promptService.savePromptOverride('BASE PROMPT');

    final service = WeeklyPlannerService(
      db: db,
      promptService: promptService,
      client: SupabaseClient('https://example.supabase.co', 'anon-key'),
    );

    final promptText =
        await service.buildPromptText(_contextWithBiometrics(const {}));
    expect(promptText, isNot(contains('BIOMETRICS_V1 (JSON):')));
  });

  test('biometrics prompt rendering remains deterministic', () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final promptService = WeeklyPlanPromptService(db: db);
    await promptService.savePromptOverride('BASE PROMPT');

    final service = WeeklyPlannerService(
      db: db,
      promptService: promptService,
      client: SupabaseClient('https://example.supabase.co', 'anon-key'),
    );

    final context = _contextWithBiometrics({
      'age': 32,
      'sex': 'male',
      'height_ft': 5,
      'height_in': 11,
      'weight_lb': 185.0,
      'build_type': 'athletic',
    });

    final promptA = await service.buildPromptText(context);
    final promptB = await service.buildPromptText(context);
    expect(promptA, equals(promptB));
  });
}
