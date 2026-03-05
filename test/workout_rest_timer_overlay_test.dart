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
          cycleKey: 'timer_test_cycle',
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
  await db.into(db.planPrescribedStrengthSets).insert(
        PlanPrescribedStrengthSetsCompanion.insert(
          id: 'pss_2',
          planDayId: 'day_1',
          exerciseCanonical: 'Bench Press',
          setIndex: 2,
          weight: const Value(175),
          reps: const Value(10),
          rir: const Value(2),
          unit: 'lb',
          rawSetString: const Value('175x10r2'),
          createdAt: 2,
        ),
      );
  return db;
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 20),
  int maxPumps = 200,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Did not find target widget: $finder');
}

Future<void> _pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 20),
  int maxPumps = 200,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(step);
    if (finder.evaluate().isEmpty) {
      return;
    }
  }
  fail('Widget remained present: $finder');
}

Finder _restCountdownDismissible() {
  return find.byWidgetPredicate((widget) {
    if (widget is! Dismissible) {
      return false;
    }
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith('rest-countdown-');
  });
}

void main() {
  testWidgets(
      'rest timer starts, resets, dismisses, reappears, and stops at zero',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 2200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const ymd = '2026-02-14';
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

    await _pumpUntilFound(tester, find.text('WORKOUT DETAIL'));

    await tester.tap(find.byIcon(Icons.expand_more).first);
    await tester.pump(const Duration(milliseconds: 180));

    const setOneConfirmKey = ValueKey<String>('confirm-actual-Bench Press-1');
    final confirmButton = find.byKey(setOneConfirmKey);
    final visibleConfirmButton = confirmButton.hitTestable();
    await _pumpUntilFound(tester, visibleConfirmButton);
    await tester.tap(visibleConfirmButton.first);
    await tester.pump();
    await _pumpUntilFound(tester, find.text('01:30'));

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('01:28'), findsOneWidget);

    await _pumpUntilFound(tester, visibleConfirmButton);
    await tester.tap(visibleConfirmButton.first);
    await tester.pump();
    await _pumpUntilFound(tester, find.text('01:30'));

    await tester.fling(
        _restCountdownDismissible(), const Offset(-700, 0), 1200);
    await tester.pump();
    await _pumpUntilGone(tester, _restCountdownDismissible());
    expect(find.text('Swipe to dismiss'), findsNothing);

    await _pumpUntilFound(tester, visibleConfirmButton);
    await tester.tap(visibleConfirmButton.first);
    await tester.pump();
    await _pumpUntilFound(tester, find.text('01:30'));

    await tester.pump(const Duration(seconds: 95));
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('Rest complete'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('Rest complete'), findsOneWidget);
  });
}
