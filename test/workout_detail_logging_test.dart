import 'package:adaptive_athlete/db/app_db.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _seedPlanForDate(AppDb db, String ymd) async {
  const cycleId = 'cycle_1';
  const dayId = 'day_1';
  await db.into(db.planCycles).insert(
        PlanCyclesCompanion.insert(
          id: cycleId,
          cycleKey: 'test_cycle',
          weekStart: ymd,
          weekEnd: ymd,
          source: 'test',
          createdAt: 1,
        ),
      );
  await db.into(db.planDays).insert(
        PlanDaysCompanion.insert(
          id: dayId,
          planCycleId: cycleId,
          dayNumber: 1,
          sheetName: 'Day 1 - Push',
          estimatedDate: Value(ymd),
          sessionType: const Value('push'),
          createdAt: 1,
        ),
      );
}

void main() {
  test(
      'upsertActualStrengthSetForDate writes lb and defaults missing weight to 0',
      () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const ymd = '2026-02-14';
    await _seedPlanForDate(db, ymd);

    await db.upsertActualStrengthSetForDate(
      dateYmd: ymd,
      exerciseCanonical: 'Pull Up',
      setIndex: 1,
      weight: null,
      reps: 10,
      rir: 2,
    );

    final workoutDay = await (db.select(db.workoutDays)
          ..where((d) => d.workoutDate.equals(ymd)))
        .getSingle();
    final rows = await (db.select(db.actualStrengthSets)
          ..where((a) => a.workoutDayId.equals(workoutDay.id)))
        .get();

    expect(rows.length, 1);
    expect(rows.first.unit, 'lb');
    expect(rows.first.weight, 0);
    expect(rows.first.planDayId, 'day_1');
    expect(rows.first.source, 'manual_from_prescribed');
  });

  test('upsertActualStrengthSetForDate overwrites existing same set', () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const ymd = '2026-02-14';
    await _seedPlanForDate(db, ymd);

    await db.upsertActualStrengthSetForDate(
      dateYmd: ymd,
      exerciseCanonical: 'Bench Press',
      setIndex: 2,
      weight: 200,
      reps: 5,
      rir: 2,
    );

    final workoutDay = await (db.select(db.workoutDays)
          ..where((d) => d.workoutDate.equals(ymd)))
        .getSingle();
    final first = await (db.select(db.actualStrengthSets)
          ..where((a) => a.workoutDayId.equals(workoutDay.id))
          ..where((a) => a.exerciseCanonical.equals('Bench Press'))
          ..where((a) => a.setIndex.equals(2)))
        .getSingle();

    await db.upsertActualStrengthSetForDate(
      dateYmd: ymd,
      exerciseCanonical: 'Bench Press',
      setIndex: 2,
      weight: 202.5,
      reps: 6,
      rir: 1,
    );

    final rows = await (db.select(db.actualStrengthSets)
          ..where((a) => a.workoutDayId.equals(workoutDay.id))
          ..where((a) => a.exerciseCanonical.equals('Bench Press'))
          ..where((a) => a.setIndex.equals(2)))
        .get();

    expect(rows.length, 1);
    expect(rows.first.id, first.id);
    expect(rows.first.weight, 202.5);
    expect(rows.first.reps, 6);
    expect(rows.first.rir, 1);
    expect(rows.first.unit, 'lb');
  });

  test('substituted actual logging preserves prescribed exercise anchor',
      () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const ymd = '2026-02-14';
    await _seedPlanForDate(db, ymd);

    await db.upsertExerciseSubstitutionForDate(
      dateYmd: ymd,
      prescribedExerciseCanonical: 'Bench Press',
      substituteExerciseCanonical: 'Dumbbell Bench Press',
      reasonCode: 'equipment_unavailable',
      matchScore: 88,
      matchExplanationJson: '{"tier":"strong"}',
      warningAcknowledged: false,
    );

    await db.upsertActualStrengthSetForDate(
      dateYmd: ymd,
      exerciseCanonical: 'Dumbbell Bench Press',
      prescribedExerciseCanonical: 'Bench Press',
      setIndex: 1,
      weight: 70,
      reps: 10,
      rir: 2,
      substitutionId: 'sub_1',
    );

    final workoutDay = await (db.select(db.workoutDays)
          ..where((d) => d.workoutDate.equals(ymd)))
        .getSingle();
    final row = await (db.select(db.actualStrengthSets)
          ..where((a) => a.workoutDayId.equals(workoutDay.id)))
        .getSingle();

    expect(row.exerciseCanonical, 'Dumbbell Bench Press');
    expect(row.prescribedExerciseCanonical, 'Bench Press');
    expect(row.substitutionId, 'sub_1');
  });

  test('workout detail exercise groups preserve prescribed plan order', () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const ymd = '2026-02-15';
    await _seedPlanForDate(db, ymd);

    // Intentionally use the same createdAt and a lower setIndex on the second
    // exercise to ensure setIndex does not reorder the exercise cards.
    await db.into(db.planPrescribedStrengthSets).insert(
          PlanPrescribedStrengthSetsCompanion.insert(
            id: 'pss_1',
            planDayId: 'day_1',
            exerciseCanonical: 'Bench Press',
            setIndex: 2,
            weight: const Value(185),
            reps: const Value(8),
            rir: const Value(2),
            unit: 'lb',
            rawSetString: const Value('185x8r2'),
            createdAt: 1000,
          ),
        );
    await db.into(db.planPrescribedStrengthSets).insert(
          PlanPrescribedStrengthSetsCompanion.insert(
            id: 'pss_2',
            planDayId: 'day_1',
            exerciseCanonical: 'Lat Pulldown',
            setIndex: 1,
            weight: const Value(120),
            reps: const Value(10),
            rir: const Value(2),
            unit: 'lb',
            rawSetString: const Value('120x10r2'),
            createdAt: 1000,
          ),
        );

    final detail = await db.getWorkoutDayDetail(ymd);
    expect(detail.groups.map((g) => g.exercise).toList(), [
      'Bench Press',
      'Lat Pulldown',
    ]);
  });
}
