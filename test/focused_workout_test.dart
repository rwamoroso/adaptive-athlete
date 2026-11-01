import 'package:adaptive_athlete/core/utils/app_providers.dart';
import 'package:adaptive_athlete/db/app_db.dart';
import 'package:adaptive_athlete/features/training/workout_day_detail_screen.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppDb> _focusedWorkoutDb(String ymd) async {
  final db = AppDb.forTesting(NativeDatabase.memory());
  await db.into(db.planCycles).insert(
        PlanCyclesCompanion.insert(
          id: 'focused_cycle',
          cycleKey: 'focused_cycle',
          weekStart: ymd,
          weekEnd: ymd,
          source: 'test',
          createdAt: 1,
        ),
      );
  await db.into(db.planDays).insert(
        PlanDaysCompanion.insert(
          id: 'focused_day',
          planCycleId: 'focused_cycle',
          dayNumber: 1,
          sheetName: 'Day 1',
          estimatedDate: Value(ymd),
          sessionType: const Value('push'),
          createdAt: 1,
        ),
      );
  await db.into(db.planPrescribedStrengthSets).insert(
        PlanPrescribedStrengthSetsCompanion.insert(
          id: 'focused_set',
          planDayId: 'focused_day',
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

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder,
) async {
  for (var i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 30));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Did not find $finder');
}

void main() {
  testWidgets('focused workout logs direct set edits and can undo the set',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1170, 2532);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    const ymd = '2026-10-29';
    final db = await _focusedWorkoutDb(ymd);
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDbProvider.overrideWithValue(db)],
        child: const MaterialApp(
          home: WorkoutDayDetailScreen(date: ymd, startFocused: true),
        ),
      ),
    );

    await _pumpUntil(tester, find.text('Workout in progress'));
    expect(find.text('Bench Press'), findsOneWidget);
    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(3));
    await tester.enterText(fields.at(0), '190');
    await tester.enterText(fields.at(1), '9');
    await tester.enterText(fields.at(2), '1');
    await tester.tap(find.widgetWithText(FilledButton, 'Complete Set'));
    await _pumpUntil(tester, find.text('Workout complete'));

    final logged = await db.select(db.actualStrengthSets).getSingle();
    expect(logged.weight, 190);
    expect(logged.reps, 9);
    expect(logged.rir, 1);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Undo Last Set'));
    await _pumpUntil(tester, find.text('Workout in progress'));
    expect(await db.select(db.actualStrengthSets).get(), isEmpty);
  });
}
