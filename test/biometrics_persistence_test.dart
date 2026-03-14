import 'dart:convert';

import 'package:adaptive_athlete/db/app_db.dart' show AppDb;
import 'package:adaptive_athlete/features/plan/weekly_plan_prompt_service.dart';
import 'package:adaptive_athlete/features/plan/weekly_planner_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

WeeklyPlannerService _service(AppDb db) => WeeklyPlannerService(
      db: db,
      promptService: WeeklyPlanPromptService(db: db),
      client: SupabaseClient('https://example.supabase.co', 'anon-key'),
    );

void main() {
  test('planning profile biometrics_json round-trips through db + service',
      () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final service = _service(db);

    final profile = AthletePlanningProfile(
      workspaceId: 'local_workspace',
      athleteProfileId: 'local_profile',
      primaryGoal: 'run_goal',
      goalTarget: const {'text': '5 miles'},
      experienceLevel: 'intermediate',
      preferredSplit: SplitType.hybridRunLift,
      daysPerWeek: 5,
      availableEquipment: const {'barbell'},
      contraindications: const <String>{},
      scheduleConstraints: const {'notes': ''},
      biometrics: const {
        'age': 32,
        'sex': 'male',
        'height_ft': 5,
        'height_in': 11,
        'weight_lb': 185.0,
        'build_type': 'athletic',
      },
    );

    await service.upsertPlanningProfile(profile);
    final loaded = await service.getPlanningProfile(
      workspaceId: profile.workspaceId,
      athleteProfileId: profile.athleteProfileId,
    );

    expect(loaded, isNotNull);
    expect(loaded!.biometrics['build_type'], 'athletic');
    expect(loaded.biometrics['height_ft'], 5);
  });

  test('legacy inserts without biometrics_json default to empty map', () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final service = _service(db);

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.customStatement(
      '''
      insert into athlete_planning_profiles (
        id, workspace_id, athlete_profile_id, primary_goal, goal_target_json,
        experience_level, preferred_split, days_per_week, available_equipment_json,
        contraindications_json, schedule_constraints_json, created_at, updated_at
      ) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        'legacy_profile_row',
        'local_workspace',
        'legacy_profile',
        'run_goal',
        jsonEncode({'text': '5 miles'}),
        'intermediate',
        'hybrid_run_lift',
        5,
        jsonEncode(['barbell']),
        jsonEncode([]),
        jsonEncode({'notes': ''}),
        now,
        now,
      ],
    );

    final loaded = await service.getPlanningProfile(
      workspaceId: 'local_workspace',
      athleteProfileId: 'legacy_profile',
    );
    expect(loaded, isNotNull);
    expect(loaded!.biometrics, isEmpty);
  });
}
