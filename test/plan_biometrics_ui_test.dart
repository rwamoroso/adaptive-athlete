import 'dart:convert';

import 'package:adaptive_athlete/core/utils/app_providers.dart';
import 'package:adaptive_athlete/db/app_db.dart';
import 'package:adaptive_athlete/features/plan/plan_builder_walkthrough_screen.dart';
import 'package:adaptive_athlete/features/plan/plan_screen.dart';
import 'package:adaptive_athlete/features/plan/weekly_plan_prompt_service.dart';
import 'package:adaptive_athlete/features/plan/weekly_planner_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  testWidgets('biometric profile button saves biometrics into planning profile',
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

    await tester.tap(find.widgetWithText(FilledButton, 'Biometric Profile'));
    await tester.pumpAndSettle();

    await tester.enterText(find.bySemanticsLabel('Age'), '32');
    await tester.enterText(find.bySemanticsLabel('Height (ft)'), '5');
    await tester.enterText(find.bySemanticsLabel('Height (in)'), '11');
    await tester.enterText(find.bySemanticsLabel('Weight (lb)'), '185');
    await tester.tap(find.widgetWithText(FilledButton, 'Save Biometrics'));
    await tester.pumpAndSettle();

    await _tapSaveAthleteIntake(tester);

    final row = await db.getAthletePlanningProfile(
      workspaceId: 'local_workspace',
      athleteProfileId: 'local_profile',
    );
    expect(row, isNotNull);
    final biometrics = jsonDecode(row!.biometricsJson) as Map<String, dynamic>;
    expect(biometrics['age'], 32);
    expect(biometrics['height_ft'], 5);
    expect(biometrics['height_in'], 11);
    expect(biometrics['build_type'], 'average');
  });

  testWidgets('walkthrough biometrics step updates draft via editor',
      (tester) async {
    _configureViewport(tester);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    PlanBuilderWalkthroughDraft lastDraft = PlanBuilderWalkthroughDraft(
      primaryGoal: PlanBuilderWalkthroughDraft.runGoal,
      runTargetEnabled: false,
      runDistanceMiles: '5',
      runPace: '',
      experienceLevel: 'intermediate',
      shortTermGoalText: '',
      shortTermGoalWeeks: '',
      weekStartDate: DateTime(2026, 3, 16),
      splitType: SplitType.hybridRunLift,
      trainingWeekdays: <int>{
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
      },
      availableEquipment: const {'barbell', 'dumbbell'},
      contraindications: const <String>{},
      scheduleConstraints: '',
      weeklyModifier: WeeklyPlanModifier.followLongTerm,
      propagateLongTerm: false,
      additionalInstructions: '',
      useCustomPromptText: false,
      customPromptText: '',
      biometrics: const <String, dynamic>{},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlanBuilderWalkthroughScreen(
          initialDraft: lastDraft,
          initialStep: 5,
          initialManualResponseText: '',
          onDraftChanged: (draft) => lastDraft = draft,
          onManualResponseChanged: (_) {},
          onStepChanged: (_) {},
          onCompleted: () {},
          onSaveIntakeRequested: () async => true,
          onBuildPromptRequested: () async => null,
          onApplyManualResponseRequested: (_) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester
        .tap(find.widgetWithText(FilledButton, 'Open Biometric Profile'));
    await tester.pumpAndSettle();

    await tester.enterText(find.bySemanticsLabel('Age'), '35');
    await tester.enterText(find.bySemanticsLabel('Height (ft)'), '6');
    await tester.enterText(find.bySemanticsLabel('Height (in)'), '0');
    await tester.enterText(find.bySemanticsLabel('Weight (lb)'), '190');
    await tester.tap(find.widgetWithText(FilledButton, 'Save Biometrics'));
    await tester.pumpAndSettle();

    expect(lastDraft.biometrics['age'], 35);
    expect(lastDraft.biometrics['height_ft'], 6);
    expect(lastDraft.biometrics['height_in'], 0);
    expect(lastDraft.biometrics['build_type'], 'average');
  });

  testWidgets('walkthrough run goal step captures distance and pace directly',
      (tester) async {
    _configureViewport(tester);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    PlanBuilderWalkthroughDraft lastDraft = PlanBuilderWalkthroughDraft(
      primaryGoal: PlanBuilderWalkthroughDraft.runGoal,
      runTargetEnabled: false,
      runDistanceMiles: '',
      runPace: '',
      experienceLevel: 'intermediate',
      shortTermGoalText: '',
      shortTermGoalWeeks: '',
      weekStartDate: DateTime(2026, 3, 16),
      splitType: SplitType.hybridRunLift,
      trainingWeekdays: <int>{
        DateTime.monday,
        DateTime.wednesday,
        DateTime.friday,
        DateTime.saturday,
        DateTime.sunday,
      },
      availableEquipment: const {'barbell', 'dumbbell'},
      contraindications: const <String>{},
      scheduleConstraints: '',
      weeklyModifier: WeeklyPlanModifier.followLongTerm,
      propagateLongTerm: false,
      additionalInstructions: '',
      useCustomPromptText: false,
      customPromptText: '',
      biometrics: const <String, dynamic>{},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlanBuilderWalkthroughScreen(
          initialDraft: lastDraft,
          initialStep: 1,
          initialManualResponseText: '',
          onDraftChanged: (draft) => lastDraft = draft,
          onManualResponseChanged: (_) {},
          onStepChanged: (_) {},
          onCompleted: () {},
          onSaveIntakeRequested: () async => true,
          onBuildPromptRequested: () async => null,
          onApplyManualResponseRequested: (_) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Do you have a running distance or pace target?'),
        findsNothing);
    expect(find.bySemanticsLabel('Distance (miles) *'), findsOneWidget);
    expect(find.bySemanticsLabel('Target Pace (optional)'), findsOneWidget);

    await tester.enterText(find.bySemanticsLabel('Distance (miles) *'), '5');
    await tester.enterText(
      find.bySemanticsLabel('Target Pace (optional)'),
      '8:00/mi',
    );
    await tester.pump();

    expect(lastDraft.runDistanceMiles, '5');
    expect(lastDraft.runPace, '8:00/mi');
    expect(lastDraft.runTargetEnabled, isTrue);
    expect(find.text('Current target: 5 miles @ 8:00/mi'), findsOneWidget);
  });

  testWidgets('walkthrough prompt step can save intake and copy prompt',
      (tester) async {
    _configureViewport(tester);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var saveCalls = 0;
    var buildCalls = 0;
    var applyCalls = 0;
    String? appliedResponse;
    String? syncedResponse;
    String? clipboardText;
    const promptText = 'PROMPT SNAPSHOT TEXT';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final draft = PlanBuilderWalkthroughDraft(
      primaryGoal: PlanBuilderWalkthroughDraft.runGoal,
      runTargetEnabled: true,
      runDistanceMiles: '5',
      runPace: '8:45/mi',
      experienceLevel: 'intermediate',
      shortTermGoalText: 'Train for a 10K',
      shortTermGoalWeeks: '6',
      weekStartDate: DateTime(2026, 3, 16),
      splitType: SplitType.hybridRunLift,
      trainingWeekdays: <int>{
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
      },
      availableEquipment: const {'barbell', 'dumbbell'},
      contraindications: const {'spinal_loading'},
      scheduleConstraints: 'Travel on Wednesday',
      weeklyModifier: WeeklyPlanModifier.followLongTerm,
      propagateLongTerm: true,
      additionalInstructions: 'Bias toward lower fatigue.',
      useCustomPromptText: false,
      customPromptText: '',
      biometrics: const {
        'age': 32,
        'sex': 'male',
        'height_ft': 5,
        'height_in': 11,
        'weight_lb': 185.0,
        'build_type': 'average',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlanBuilderWalkthroughScreen(
          initialDraft: draft,
          initialStep: 6,
          initialManualResponseText: '',
          onDraftChanged: (_) {},
          onManualResponseChanged: (value) => syncedResponse = value,
          onStepChanged: (_) {},
          onCompleted: () {},
          onSaveIntakeRequested: () async {
            saveCalls += 1;
            return true;
          },
          onBuildPromptRequested: () async {
            buildCalls += 1;
            return promptText;
          },
          onApplyManualResponseRequested: (responseText) async {
            applyCalls += 1;
            appliedResponse = responseText;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Week Start: 2026-03-16'), findsOneWidget);
    expect(find.text('Week End: 2026-03-22'), findsOneWidget);
    expect(find.text('Goal: 5 miles @ 8:45/mi'), findsOneWidget);
    expect(find.textContaining('10-week: Update'), findsOneWidget);
    expect(find.textContaining('Train for a 10K (6 weeks)'), findsOneWidget);
    expect(find.text('Paste Weekly AI Plan Response Here.'),
        findsAtLeastNWidgets(1));
    expect(find.text(promptText), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Save Athlete Intake'));
    await tester.pumpAndSettle();
    expect(saveCalls, 1);

    await tester
        .tap(find.widgetWithText(OutlinedButton, 'Build Prompt Snapshot'));
    await tester.pumpAndSettle();
    expect(buildCalls, 1);
    expect(find.text(promptText), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Copy Prompt'));
    await tester.pump();

    expect(clipboardText, promptText);

    final responseField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Paste Weekly AI Plan Response Here.',
    );
    await tester.enterText(
      responseField,
      'WEEKLY AI RESPONSE',
    );
    await tester.pump();
    expect(syncedResponse, 'WEEKLY AI RESPONSE');

    await tester.tap(
      find.widgetWithText(FilledButton, 'Apply Pasted Weekly Plan Text'),
    );
    await tester.pumpAndSettle();
    expect(applyCalls, 1);
    expect(appliedResponse, 'WEEKLY AI RESPONSE');

    await tester.tap(find.text('Full Prompt'));
    await tester.pumpAndSettle();
    expect(find.text(promptText), findsOneWidget);
  });
}
