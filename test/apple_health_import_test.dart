import 'dart:convert';

import 'package:adaptive_athlete/db/app_db.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDb db;

  setUp(() {
    db = AppDb.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('Apple Health workout import is stable and updates in place', () async {
    final start = DateTime(2026, 10, 29, 7, 30);
    final first = await db.upsertAppleHealthWorkout(
      healthKitUuid: 'workout-1',
      start: start,
      end: start.add(const Duration(minutes: 30)),
      activityType: 'running',
      title: 'Running',
      distanceM: 5000,
      avgHr: 145,
      maxHr: 170,
      calories: 400,
      rawMetrics: const {'source_name': 'Apple Watch'},
    );
    final second = await db.upsertAppleHealthWorkout(
      healthKitUuid: 'workout-1',
      start: start,
      end: start.add(const Duration(minutes: 32)),
      activityType: 'running',
      title: 'Running',
      distanceM: 5200,
      avgHr: 146,
      maxHr: 172,
      calories: 420,
      rawMetrics: const {'source_name': 'Apple Watch'},
    );

    expect(first.inserted, isTrue);
    expect(second.updated, isTrue);
    final rows = await db.select(db.runSessions).get();
    expect(rows, hasLength(1));
    expect(rows.single.id, 'apple_health_workout-1');
    expect(rows.single.source, 'apple_health');
    expect(rows.single.distanceM, 5200);
    expect(rows.single.durationS, 32 * 60);
  });

  test('Apple Health replaces a same-start manual entry with an audit',
      () async {
    final start = DateTime(2026, 10, 29, 18);
    final manual = await db.insertOrUpdateManualRun(
      dateString: '2026-10-29',
      startTimeMs: start.millisecondsSinceEpoch,
      durationS: 1200,
      distanceM: 3000,
      avgHr: 130,
      maxHr: 150,
      activityType: 'running',
      title: 'Evening Run',
    );
    final imported = await db.upsertAppleHealthWorkout(
      healthKitUuid: 'workout-manual-match',
      start: start,
      end: start.add(const Duration(minutes: 22)),
      activityType: 'running',
      title: 'Running',
      distanceM: 3300,
      avgHr: 135,
      maxHr: 155,
      calories: 260,
      rawMetrics: const {'source_name': 'Apple Watch'},
    );

    expect(imported.overriddenManual, isTrue);
    expect(imported.runSessionId, manual.runSessionId);
    final runs = await db.select(db.runSessions).get();
    expect(runs, hasLength(1));
    expect(runs.single.source, 'apple_health');
    expect(runs.single.sourcePriority, 90);
    final audits = await db.select(db.runOverrideAudit).get();
    expect(audits, hasLength(1));
    expect(audits.single.oldSource, 'manual');
    expect(audits.single.newSource, 'apple_health');
  });

  test('Apple Health body weight is saved without replacing manual biometrics',
      () async {
    await db.upsertAthletePlanningProfile(
      workspaceId: 'local_workspace',
      athleteProfileId: 'local_profile',
      primaryGoal: 'strength',
      goalTargetJson: '{}',
      experienceLevel: 'intermediate',
      preferredSplit: 'full_body_3d',
      daysPerWeek: 3,
      availableEquipmentJson: '[]',
      contraindicationsJson: '[]',
      scheduleConstraintsJson: '{}',
      biometricsJson: jsonEncode({'weight_lb': 180}),
    );

    final saved = await db.saveAppleHealthBodyWeight(
      workspaceId: 'local_workspace',
      athleteProfileId: 'local_profile',
      kilograms: 80,
      measuredAt: DateTime.utc(2026, 10, 30, 8),
    );
    expect(saved, isTrue);

    final profile = await db.getAthletePlanningProfile(
      workspaceId: 'local_workspace',
      athleteProfileId: 'local_profile',
    );
    final biometrics = jsonDecode(profile!.biometricsJson) as Map;
    expect(biometrics['weight_lb'], 180);
    expect(biometrics['healthkit_weight_lb'], 176.4);
    expect(biometrics['healthkit_weight_at'], '2026-10-30T08:00:00.000Z');

    await db.upsertAthletePlanningProfile(
      workspaceId: 'local_workspace',
      athleteProfileId: 'local_profile',
      primaryGoal: 'strength',
      goalTargetJson: '{}',
      experienceLevel: 'intermediate',
      preferredSplit: 'full_body_3d',
      daysPerWeek: 3,
      availableEquipmentJson: '[]',
      contraindicationsJson: '[]',
      scheduleConstraintsJson: '{}',
      biometricsJson: jsonEncode({'weight_lb': 182}),
    );
    final edited = await db.getAthletePlanningProfile(
      workspaceId: 'local_workspace',
      athleteProfileId: 'local_profile',
    );
    final editedBiometrics = jsonDecode(edited!.biometricsJson) as Map;
    expect(editedBiometrics['weight_lb'], 182);
    expect(editedBiometrics['healthkit_weight_lb'], 176.4);
  });
}
