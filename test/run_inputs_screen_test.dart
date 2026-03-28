import 'package:adaptive_athlete/core/utils/app_providers.dart';
import 'package:adaptive_athlete/db/app_db.dart';
import 'package:adaptive_athlete/features/training/run_inputs_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'manual cardio selector offers run, treadmill run, and stairstepper',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDbProvider.overrideWithValue(db)],
        child: const MaterialApp(home: RunInputsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Run'), findsWidgets);
    expect(find.text('Treadmill Run'), findsOneWidget);
    expect(find.text('Stairstepper'), findsOneWidget);
    expect(
      find.text('Distance is required for running entries.'),
      findsOneWidget,
    );

    final stairStepperChip = find.widgetWithText(ChoiceChip, 'Stairstepper');
    await tester.tap(stairStepperChip);
    await tester.pumpAndSettle();

    expect(
      find.text('Distance is optional for stair stepper sessions.'),
      findsOneWidget,
    );

    await tester
        .ensureVisible(find.widgetWithText(FilledButton, 'Save Manual Cardio'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save Manual Cardio'));
    await tester.pumpAndSettle();

    final runs = await db.select(db.runSessions).get();
    expect(runs.length, 1);
    expect(runs.single.title, 'Stairstepper');
    expect(runs.single.activityType, 'Stairstepper');
    expect(runs.single.treadmill, false);
    expect(runs.single.distanceM, 0);
  });
}
