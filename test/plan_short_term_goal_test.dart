import 'dart:convert';

import 'package:adaptive_athlete/core/utils/app_providers.dart';
import 'package:adaptive_athlete/db/app_db.dart';
import 'package:adaptive_athlete/features/plan/plan_screen.dart';
import 'package:adaptive_athlete/features/plan/weekly_plan_prompt_service.dart';
import 'package:adaptive_athlete/features/plan/weekly_planner_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

WeeklyPlannerService _plannerServiceForTesting(AppDb db) {
  final client = SupabaseClient('https://example.supabase.co', 'anon-key');
  client.auth.stopAutoRefresh();
  return WeeklyPlannerService(
    db: db,
    promptService: WeeklyPlanPromptService(db: db),
    client: client,
  );
}

Future<void> _pumpPlanScreen(
  WidgetTester tester,
  AppDb db,
  WeeklyPlannerService plannerService,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDbProvider.overrideWithValue(db),
        weeklyPlannerServiceProvider.overrideWithValue(plannerService),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: PlanScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _configureViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1200, 2200);
}

Future<void> _tapSaveAthleteIntake(WidgetTester tester) async {
  final saveButton = find.widgetWithText(FilledButton, 'Save Athlete Intake');
  final visibleSaveButton = saveButton.hitTestable();
  await tester.dragUntilVisible(
    visibleSaveButton,
    find.byType(ListView).first,
    const Offset(0, -300),
  );
  await tester.tap(visibleSaveButton);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('advanced workspace tab is available in plan screen',
      (tester) async {
    _configureViewport(tester);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final plannerService = _plannerServiceForTesting(db);
    await _pumpPlanScreen(tester, db, plannerService);

    expect(find.text('Advanced Planning Tools'), findsNothing);
    final advancedTab = find.text('Advanced').last.hitTestable();
    await tester.dragUntilVisible(
      advancedTab,
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.tap(advancedTab);
    await tester.pumpAndSettle();

    expect(find.text('Advanced Planning Tools'), findsOneWidget);
  });

  testWidgets(
      'short-term goal button opens dedicated screen and applies values',
      (tester) async {
    _configureViewport(tester);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final plannerService = _plannerServiceForTesting(db);
    await _pumpPlanScreen(tester, db, plannerService);

    await tester.tap(find.widgetWithText(FilledButton, 'Short-Term Goal'));
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'Train for a 10K race');
    await tester.enterText(textFields.at(1), '5');
    await tester.tap(find.widgetWithText(FilledButton, 'Save Goal'));
    await tester.pumpAndSettle();

    await _tapSaveAthleteIntake(tester);

    final row = await db.getAthletePlanningProfile(
      workspaceId: 'local_workspace',
      athleteProfileId: 'local_profile',
    );
    expect(row, isNotNull);

    final goalTarget = jsonDecode(row!.goalTargetJson) as Map<String, dynamic>;
    final shortTerm = goalTarget['short_term_goal'] as Map<String, dynamic>;
    expect(shortTerm['text'], 'Train for a 10K race');
    expect(shortTerm['timeline_weeks'], 5);
  });

  testWidgets('saves short-term goal and timeline weeks into goal_target_json',
      (tester) async {
    _configureViewport(tester);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final plannerService = _plannerServiceForTesting(db);
    await _pumpPlanScreen(tester, db, plannerService);

    await tester.enterText(
      find.bySemanticsLabel('Short-Term Goal (optional)'),
      'Train for a 10K race',
    );
    await tester.enterText(
      find.bySemanticsLabel('Timeline (weeks)'),
      '5',
    );
    await _tapSaveAthleteIntake(tester);

    final row = await db.getAthletePlanningProfile(
      workspaceId: 'local_workspace',
      athleteProfileId: 'local_profile',
    );
    expect(row, isNotNull);

    final goalTarget = jsonDecode(row!.goalTargetJson) as Map<String, dynamic>;
    final shortTerm = goalTarget['short_term_goal'] as Map<String, dynamic>;
    expect(shortTerm['text'], 'Train for a 10K race');
    expect(shortTerm['timeline_weeks'], 5);
  });

  testWidgets('shows validation error when short-term goal text has no weeks',
      (tester) async {
    _configureViewport(tester);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final plannerService = _plannerServiceForTesting(db);
    await _pumpPlanScreen(tester, db, plannerService);

    await tester.enterText(
      find.bySemanticsLabel('Short-Term Goal (optional)'),
      'Get abs showing for a beach weekend',
    );
    await _tapSaveAthleteIntake(tester);

    expect(
      find.textContaining(
        'Timeline weeks is required when short-term goal text is provided.',
      ),
      findsOneWidget,
    );

    final row = await db.getAthletePlanningProfile(
      workspaceId: 'local_workspace',
      athleteProfileId: 'local_profile',
    );
    expect(row, isNull);
  });

  testWidgets('shows validation error for out-of-range timeline weeks',
      (tester) async {
    _configureViewport(tester);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final plannerService = _plannerServiceForTesting(db);
    await _pumpPlanScreen(tester, db, plannerService);

    await tester.enterText(
      find.bySemanticsLabel('Short-Term Goal (optional)'),
      'Train for a 10K race',
    );
    await tester.enterText(
      find.bySemanticsLabel('Timeline (weeks)'),
      '53',
    );
    await _tapSaveAthleteIntake(tester);

    expect(
      find.textContaining(
          'Timeline weeks must be a whole number between 1 and 52.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'shows validation error when weeks are provided without goal text',
      (tester) async {
    _configureViewport(tester);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final plannerService = _plannerServiceForTesting(db);
    await _pumpPlanScreen(tester, db, plannerService);

    await tester.enterText(
      find.bySemanticsLabel('Timeline (weeks)'),
      '6',
    );
    await _tapSaveAthleteIntake(tester);

    expect(
      find.textContaining(
        'Short-term goal text is required when timeline weeks is provided.',
      ),
      findsOneWidget,
    );
  });
}
