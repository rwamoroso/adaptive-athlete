import 'package:adaptive_athlete/db/app_db.dart' show AppDb;
import 'package:adaptive_athlete/features/plan/weekly_plan_prompt_service.dart';
import 'package:adaptive_athlete/features/plan/weekly_planner_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('buildPromptText includes short-term goal from goal_target JSON',
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

    final context = PlannerPromptContext(
      profile: const AthletePlanningProfile(
        workspaceId: 'local_workspace',
        athleteProfileId: 'local_profile',
        primaryGoal: 'run_goal',
        goalTarget: {
          'distance_miles': 5,
          'target_pace': '9:00/mi',
          'text': '5 miles @ 9:00/mi',
          'short_term_goal': {
            'text': 'Train for a 10K race',
            'timeline_weeks': 5,
          },
        },
        experienceLevel: 'intermediate',
        preferredSplit: SplitType.runOnly,
        daysPerWeek: 5,
        availableEquipment: {'bodyweight'},
        contraindications: <String>{},
        scheduleConstraints: {
          'notes': '',
          'preferred_training_weekdays': [1, 2, 3, 4, 5],
        },
      ),
      weekStart: '2026-03-02',
      weekEnd: '2026-03-08',
      splitType: SplitType.runOnly,
      modifier: WeeklyPlanModifier.followLongTerm,
      propagateLongTermChanges: false,
      longRangeContextRows: const <Map<String, dynamic>>[],
      recentMetricsSummary: const <String, dynamic>{},
      additionalInstructions: null,
    );

    final promptText = await service.buildPromptText(context);
    expect(promptText, contains('Goal Target (JSON):'));
    expect(promptText, contains('"short_term_goal"'));
    expect(promptText, contains('"text": "Train for a 10K race"'));
    expect(promptText, contains('"timeline_weeks": 5'));
  });

  test('buildPromptText adds cardio modality compatibility instructions',
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

    final context = PlannerPromptContext(
      profile: const AthletePlanningProfile(
        workspaceId: 'local_workspace',
        athleteProfileId: 'local_profile',
        primaryGoal: 'cardio_improvement',
        goalTarget: {
          'text': 'Improve cardio fitness without a race target',
        },
        experienceLevel: 'intermediate',
        preferredSplit: SplitType.runOnly,
        daysPerWeek: 5,
        availableEquipment: {'bodyweight', 'stair_stepper'},
        contraindications: <String>{},
        scheduleConstraints: {
          'notes': '',
          'preferred_training_weekdays': [1, 2, 3, 4, 5],
        },
      ),
      weekStart: '2026-03-09',
      weekEnd: '2026-03-15',
      splitType: SplitType.runOnly,
      modifier: WeeklyPlanModifier.followLongTerm,
      propagateLongTermChanges: false,
      longRangeContextRows: const <Map<String, dynamic>>[],
      recentMetricsSummary: const <String, dynamic>{},
      additionalInstructions: null,
    );

    final promptText = await service.buildPromptText(context);
    expect(promptText, contains('Cardio Prescription Compatibility Rules:'));
    expect(promptText, contains('stair_stepper'));
    expect(
      promptText,
      contains(
          'Use the existing `RUN_*` fields as the cardio prescription slot'),
    );
  });
}
