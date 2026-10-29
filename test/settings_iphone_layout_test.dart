import 'package:adaptive_athlete/core/utils/app_providers.dart';
import 'package:adaptive_athlete/db/app_db.dart';
import 'package:adaptive_athlete/features/plan/weekly_plan_prompt_service.dart';
import 'package:adaptive_athlete/features/plan/weekly_planner_service.dart';
import 'package:adaptive_athlete/features/settings/settings_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  for (final scale in [1.0, 1.4]) {
    testWidgets(
        'settings shows the installed build without overflow at iPhone width, scale $scale',
        (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      PackageInfo.setMockInitialValues(
          appName: 'Adaptive Athlete',
          packageName: 'test.adaptive',
          version: '1.1.0',
          buildNumber: '4',
          buildSignature: '');
      final db = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await WeeklyPlanPromptService(db: db).savePromptOverride('Test prompt');
      final client = (await tester.runAsync(() async => SupabaseClient(
          'https://test.invalid', 'fake',
          authOptions: const AuthClientOptions(autoRefreshToken: false))))!;
      addTearDown(() => tester.runAsync(client.dispose));
      await tester.pumpWidget(ProviderScope(
          overrides: [
            appDbProvider.overrideWithValue(db),
            weeklyPlannerServiceProvider.overrideWithValue(WeeklyPlannerService(
                db: db,
                promptService: WeeklyPlanPromptService(db: db),
                client: client))
          ],
          child: MaterialApp(
              home: MediaQuery(
                  data: MediaQueryData(
                      size: const Size(402, 874),
                      textScaler: TextScaler.linear(scale)),
                  child: const Scaffold(body: SettingsScreen())))));
      await tester.pumpAndSettle();
      expect(find.text('Adaptive Athlete 1.1.0 (build 4)'), findsOneWidget);
      await tester.tap(find.text('What changed in 1.1.0'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
