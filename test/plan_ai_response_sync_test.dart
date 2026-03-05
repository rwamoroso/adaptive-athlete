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

void _configureViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1200, 2200);
}

void main() {
  testWidgets('step 3 pasted AI response syncs into shared AI state',
      (tester) async {
    _configureViewport(tester);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final plannerService = _plannerServiceForTesting(db);
    final container = ProviderContainer(
      overrides: [
        appDbProvider.overrideWithValue(db),
        weeklyPlannerServiceProvider.overrideWithValue(plannerService),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: PlanScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final responseField =
        find.bySemanticsLabel('Paste Weekly AI Plan Response Here.');
    await tester.dragUntilVisible(
      responseField.hitTestable(),
      find.byType(ListView).first,
      const Offset(0, -280),
    );

    const responseText =
        'WEEK_PLAN_V1\nPLAN_EXPLANATION_V1\nWHY_THIS_WEEK: Build base.\nEND_PLAN_EXPLANATION_V1';
    await tester.enterText(responseField, responseText);
    await tester.pumpAndSettle();

    expect(container.read(aiWeeklyPlanResponseProvider), responseText);
  });
}
