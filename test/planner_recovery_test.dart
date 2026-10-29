import 'package:adaptive_athlete/db/app_db.dart' show AppDb;
import 'package:adaptive_athlete/features/plan/planner_issue.dart';
import 'package:adaptive_athlete/features/plan/weekly_plan_prompt_service.dart';
import 'package:adaptive_athlete/features/plan/weekly_planner_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String recoveryWeek() {
  final text = StringBuffer(
      'WEEK_PLAN_V1\nWEEK_START: 2026-10-26\nWEEK_END: 2026-11-01\n');
  for (var day = 1; day <= 7; day++) {
    text.writeln(
        'DAY $day\nSESSION_TYPE: rest\nDAY_LABEL: Recovery\nLIFT_FOCUS:\nRUN_TYPE:\nRUN_DURATION:\nRUN_TARGET_PACE:\nRUN_HR_GUARDRAILS:\nRUN_NOTES:\nEND DAY $day');
  }
  return text.toString();
}

WeeklyPlanBuildRequest request({bool propagate = false}) =>
    WeeklyPlanBuildRequest(
        workspaceId: 'local_workspace',
        athleteProfileId: 'local_profile',
        splitStartDate: DateTime(2026, 10, 26),
        splitType: SplitType.runOnly,
        modifier: WeeklyPlanModifier.followLongTerm,
        mode: PlannerGenerationMode.manualAssist,
        propagateLongTermChanges: propagate,
        additionalInstructions: null,
        overridePromptText: null);

void main() {
  test(
      'response checks validate dates and propagation without changing a saved plan',
      () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final client = SupabaseClient('https://test.invalid', 'fake',
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    addTearDown(client.dispose);
    final service = WeeklyPlannerService(
        db: db, promptService: WeeklyPlanPromptService(db: db), client: client);
    await db.importAiWeeklyPlanText(
        text: recoveryWeek(), splitStartDate: DateTime(2026, 10, 26));
    final before = (await db.select(db.planCycles).getSingle()).id;
    final audits = (await db.select(db.planImportAudit).get()).length;
    expect(service.checkResponse(request: request(), text: recoveryWeek()),
        contains('7 days checked'));
    expect(
        () => service.checkResponse(
            request: request(),
            text: recoveryWeek().replaceFirst('2026-10-26', '2026-10-27')),
        throwsStateError);
    expect(
        () => service.checkResponse(
            request: request(propagate: true), text: recoveryWeek()),
        throwsStateError);
    expect((await db.select(db.planCycles).getSingle()).id, before);
    expect((await db.select(db.planImportAudit).get()).length, audits);
  });

  test('planner failures provide useful recovery actions', () {
    expect(
        PlannerIssue.from(StateError('TEN_WEEK_PLAN_UPDATE_V1 missing'))
            .recovery,
        contains('Propagate'));
    expect(PlannerIssue.from(StateError('WEEK_START mismatch')).recovery,
        contains('matching week'));
    expect(
        PlannerIssue.from(StateError('502 No AI provider available')).retryable,
        true);
    expect(PlannerIssue.from(StateError('401 Invalid JWT')).recovery,
        contains('Sign in'));
    expect(PlannerIssue.from(StateError('unexpected field RULE')).retryable,
        false);
  });
}
