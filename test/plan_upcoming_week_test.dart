import 'package:adaptive_athlete/core/utils/app_providers.dart';
import 'package:adaptive_athlete/core/utils/date_utils.dart';
import 'package:adaptive_athlete/db/app_db.dart';
import 'package:adaptive_athlete/features/plan/plan_screen.dart';
import 'package:adaptive_athlete/features/plan/weekly_plan_prompt_service.dart';
import 'package:adaptive_athlete/features/plan/weekly_planner_service.dart';
import 'package:drift/drift.dart' show Value;
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

void main() {
  testWidgets('Plan shows the upcoming week schedule', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 2200);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final nowMs = today.millisecondsSinceEpoch;

    await db.into(db.planCycles).insert(
          PlanCyclesCompanion.insert(
            id: 'cycle',
            cycleKey: 'upcoming-week',
            weekStart: toYmd(start),
            weekEnd: toYmd(start.add(const Duration(days: 6))),
            source: 'test',
            createdAt: nowMs,
          ),
        );
    await db.into(db.planDays).insert(
          PlanDaysCompanion.insert(
            id: 'day-1',
            planCycleId: 'cycle',
            dayNumber: 1,
            sheetName: 'Push',
            estimatedDate: Value(toYmd(start)),
            sessionType: const Value('push'),
            createdAt: nowMs,
          ),
        );
    await db.into(db.planPrescribedRuns).insert(
          PlanPrescribedRunsCompanion.insert(
            id: 'run-1',
            planDayId: 'day-1',
            runType: const Value('Easy Run'),
            durationText: const Value('30 minutes'),
            createdAt: nowMs,
          ),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDbProvider.overrideWithValue(db),
          weeklyPlannerServiceProvider
              .overrideWithValue(_plannerServiceForTesting(db)),
        ],
        child: const MaterialApp(home: Scaffold(body: PlanScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Upcoming Week'), findsOneWidget);
    expect(find.text('Cardio: Easy Run • 30 minutes'), findsOneWidget);
    expect(find.text('Strength: Push Focus'), findsOneWidget);
    expect(find.byTooltip('Refresh upcoming week'), findsOneWidget);
  });
}
