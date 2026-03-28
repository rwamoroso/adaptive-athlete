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

Future<AppDb> _emptyDbForWorkoutDetail() async {
  return AppDb.forTesting(NativeDatabase.memory());
}

void main() {
  testWidgets('user can add an exercise to the split with initial sets',
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

    await tester.tap(find.widgetWithText(FilledButton, 'Add To Split').last);
    await tester.pumpAndSettle();

    expect(find.text('Add Exercise To Split'), findsOneWidget);

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'Kneeling Leg Curl');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kneeling Leg Curl').last);
    await tester.pumpAndSettle();
    await tester.enterText(textFields.at(1), '2');
    await tester.tap(find.widgetWithText(FilledButton, 'Add To Split').last);
    await tester.pumpAndSettle();

    final rows = await (db.select(db.planPrescribedStrengthSets)
          ..where((a) => a.planDayId.equals('day_1'))
          ..where((a) => a.exerciseCanonical.equals('Kneeling Leg Curl'))
          ..orderBy([(a) => OrderingTerm.asc(a.setIndex)]))
        .get();

    expect(rows.length, 2);
    expect(rows[0].setIndex, 1);
    expect(rows[1].setIndex, 2);
    expect(rows[0].weight, equals(null));
    expect(rows[0].reps, equals(null));
    expect(rows[0].rir, equals(null));
    expect(find.text('Kneeling Leg Curl'), findsWidgets);
  });

  testWidgets('add to split starts a split plan for the day when none exists',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 2200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const ymd = '2026-02-17';
    final db = await _emptyDbForWorkoutDetail();
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

    await tester.tap(find.widgetWithText(FilledButton, 'Add To Split').last);
    await tester.pumpAndSettle();

    expect(find.text('Add Exercise To Split'), findsOneWidget);

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'Bench Press');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench Press').last);
    await tester.pumpAndSettle();
    await tester.enterText(textFields.at(1), '3');
    await tester.tap(find.widgetWithText(FilledButton, 'Add To Split').last);
    await tester.pumpAndSettle();

    final cycles = await db.select(db.planCycles).get();
    expect(cycles.length, 1);
    expect(cycles.first.source, 'manual_ad_hoc_split');

    final planDay = await (db.select(db.planDays)
          ..where((d) => d.estimatedDate.equals(ymd)))
        .getSingle();
    final rows = await (db.select(db.planPrescribedStrengthSets)
          ..where((a) => a.planDayId.equals(planDay.id))
          ..where((a) => a.exerciseCanonical.equals('Bench Press'))
          ..orderBy([(a) => OrderingTerm.asc(a.setIndex)]))
        .get();

    expect(rows.length, 3);
    expect(rows[0].setIndex, 1);
    expect(rows[1].setIndex, 2);
    expect(rows[2].setIndex, 3);
  });
}
