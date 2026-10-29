import 'dart:convert';
import 'package:adaptive_athlete/db/app_db.dart';
import 'package:adaptive_athlete/features/training/cardio_activity.dart';
import 'package:adaptive_athlete/features/training/cardio_metrics.dart';
import 'package:drift/native.dart';
import 'package:adaptive_athlete/features/plan/weekly_planner_service.dart'
    as planner;
import 'package:adaptive_athlete/features/plan/weekly_plan_prompt_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'mileage sums multiple runs while excluding bike, walking, and stair sessions',
      () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final activities = {
      'Run': 5000.0,
      'Treadmill Run': 3000.0,
      'Outdoor Bike': 20000.0,
      'Stationary Bike': 10000.0,
      'Stair Stepper': 1000.0,
      'Treadmill Walking': 2000.0
    };
    var hour = 6;
    for (final entry in activities.entries) {
      await db.insertOrUpdateManualRun(
          dateString: '2026-10-29',
          startTimeMs: DateTime(2026, 10, 29, hour++).millisecondsSinceEpoch,
          durationS: 1800,
          distanceM: entry.value,
          avgHr: null,
          maxHr: null,
          activityType: entry.key,
          title: entry.key,
          treadmill: entry.key.startsWith('Treadmill'));
    }
    final distances =
        await runningDistanceByDate(db, '2026-10-01', '2026-10-31');
    expect(distances, {'2026-10-29': 8000.0});
    expect(
        await runningDistanceByDate(db, '2026-09-01', '2026-09-30'), isEmpty);
  });

  test('planner history separates other cardio and ignores empty workout days',
      () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final client = SupabaseClient('https://test.invalid', 'fake',
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    addTearDown(client.dispose);
    final service = planner.WeeklyPlannerService(
        db: db, promptService: WeeklyPlanPromptService(db: db), client: client);
    await WeeklyPlanPromptService(db: db)
        .savePromptOverride('Test planning context');
    final today = DateTime.now();
    String ymd(DateTime date) => date.toIso8601String().split('T').first;
    final day = ymd(today);
    await db.createOrGetWorkoutDayByDate(
        ymd(today.subtract(const Duration(days: 1))));
    for (final (index, type, distance) in [
      (0, 'Run', 5000.0),
      (1, 'Outdoor Bike', 20000.0),
      (2, 'Stair Stepper', 0.0)
    ]) {
      await db.insertOrUpdateManualRun(
          dateString: day,
          startTimeMs: DateTime(today.year, today.month, today.day, 8 + index)
              .millisecondsSinceEpoch,
          durationS: 1800,
          distanceM: distance,
          avgHr: null,
          maxHr: null,
          title: type,
          activityType: type,
          treadmill: false);
    }
    await service.upsertPlanningProfile(const planner.AthletePlanningProfile(
        workspaceId: 'local_workspace',
        athleteProfileId: 'local_profile',
        primaryGoal: 'run_goal',
        goalTarget: {'distance_miles': 5},
        experienceLevel: 'intermediate',
        preferredSplit: planner.SplitType.runOnly,
        daysPerWeek: 3,
        availableEquipment: {'bodyweight'},
        contraindications: {},
        scheduleConstraints: {}));
    await service.generatePlan(planner.WeeklyPlanBuildRequest(
        workspaceId: 'local_workspace',
        athleteProfileId: 'local_profile',
        splitStartDate: today,
        splitType: planner.SplitType.runOnly,
        modifier: planner.WeeklyPlanModifier.followLongTerm,
        mode: planner.PlannerGenerationMode.manualAssist,
        propagateLongTermChanges: false,
        additionalInstructions: null,
        overridePromptText: null));
    final saved = await db.select(db.weeklyPlanBuildRequests).getSingle();
    final metrics = (jsonDecode(saved.requestPayloadJson)
        as Map)['recent_metrics_summary'] as Map;
    expect(metrics['run']['session_count'], 1);
    expect(metrics['run']['total_distance_m'], 5000);
    expect(metrics['cardio']['session_count'], 3);
    expect(metrics['workout_dates_with_activity'], [day]);
  });

  test(
      'legacy running entries remain included; explicit other cardio stays excluded',
      () {
    expect(CardioActivity.isRunningSession(), true);
    for (final type in [
      'Running',
      'Treadmill Running',
      'Trail Running',
      'Tempo',
      'Easy'
    ]) {
      expect(CardioActivity.isRunningSession(activityType: type), true,
          reason: type);
    }
    for (final type in [
      'Row',
      'Rowing',
      'Swimming',
      'Hiking',
      'Indoor Cycling',
      'Treadmill Walking'
    ]) {
      expect(
          CardioActivity.isRunningSession(activityType: type, treadmill: true),
          false,
          reason: type);
    }
  });
}
