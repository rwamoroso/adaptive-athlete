import 'package:adaptive_athlete/core/utils/app_providers.dart';
import 'package:adaptive_athlete/db/app_db.dart';
import 'package:adaptive_athlete/features/training/workout_day_detail_screen.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppDb> _seedDbForWorkoutDetail(String ymd) async {
  final db = AppDb.forTesting(NativeDatabase.memory());
  await db.into(db.planCycles).insert(
        PlanCyclesCompanion.insert(
          id: 'cycle_1',
          cycleKey: 'add_exercise_cycle',
          weekStart: ymd,
          weekEnd: ymd,
          source: 'test',
          createdAt: 1,
        ),
      );
  await db.into(db.planDays).insert(
        PlanDaysCompanion.insert(
          id: 'day_1',
          planCycleId: 'cycle_1',
          dayNumber: 1,
          sheetName: 'Day 1 - Push',
          estimatedDate: Value(ymd),
          sessionType: const Value('push'),
          createdAt: 1,
        ),
      );
  await db.into(db.planPrescribedStrengthSets).insert(
        PlanPrescribedStrengthSetsCompanion.insert(
          id: 'pss_1',
          planDayId: 'day_1',
          exerciseCanonical: 'Bench Press',
          setIndex: 1,
          weight: const Value(185),
          reps: const Value(8),
          rir: const Value(2),
          unit: 'lb',
          rawSetString: const Value('185x8r2'),
          createdAt: 1,
        ),
      );
  return db;
}

void main() {
  testWidgets('user can add a custom exercise with initial sets',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 2200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const ymd = '2026-02-16';
    final db = await _seedDbForWorkoutDetail(ymd);
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDbProvider.overrideWithValue(db)],
        child: const MaterialApp(
          home: WorkoutDayDetailScreen(date: ymd),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Add Exercise'));
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    final textFields = find.descendant(
      of: dialog,
      matching: find.byType(TextField),
    );
    await tester.enterText(textFields.at(0), 'Kneeling Leg Curl');
    await tester.enterText(textFields.at(1), '2');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    final workoutDay = await (db.select(db.workoutDays)
          ..where((d) => d.workoutDate.equals(ymd)))
        .getSingle();
    final rows = await (db.select(db.actualStrengthSets)
          ..where((a) => a.workoutDayId.equals(workoutDay.id))
          ..where(
              (a) => a.prescribedExerciseCanonical.equals('Kneeling Leg Curl'))
          ..orderBy([(a) => OrderingTerm.asc(a.setIndex)]))
        .get();

    expect(rows.length, 2);
    expect(rows[0].setIndex, 1);
    expect(rows[1].setIndex, 2);
    expect(rows[0].source, 'manual_custom_exercise');
    expect(find.text('Kneeling Leg Curl'), findsWidgets);
  });
}
