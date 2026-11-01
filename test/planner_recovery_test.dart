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

String propagatedRecoveryPlan() {
  final text = StringBuffer('TEN_WEEK_PLAN_UPDATE_V1\n');
  final first = DateTime.utc(2026, 10, 26);
  for (var index = 0; index < 10; index++) {
    final start = first.add(Duration(days: index * 7));
    final end = start.add(const Duration(days: 6));
    final startText = start.toIso8601String().split('T').first;
    final endText = end.toIso8601String().split('T').first;
    text.writeln(
      'TEN_WEEK_ROW: week=Week ${index + 1} | week_start=$startText | '
      'week_end=$endText | run_focus=Run ${index + 1} | '
      'strength_focus=Strength ${index + 1} | '
      'strength_progression_expectation=Progress ${index + 1} | '
      'primary_progression_target=Target ${index + 1} | '
      'recovery_emphasis=Recovery ${index + 1} | deload=no | notes=',
    );
  }
  text.writeln('END_TEN_WEEK_PLAN_UPDATE_V1');
  text.write(recoveryWeek());
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
  test('selected November 1 week uses calendar end date November 7', () {
    final novemberRequest = WeeklyPlanBuildRequest(
      workspaceId: 'local_workspace',
      athleteProfileId: 'local_profile',
      splitStartDate: DateTime(2026, 11, 1),
      splitType: SplitType.customHybrid,
      modifier: WeeklyPlanModifier.followLongTerm,
      mode: PlannerGenerationMode.manualAssist,
      propagateLongTermChanges: true,
      additionalInstructions: null,
      overridePromptText: null,
    );

    expect(novemberRequest.weekStart, '2026-11-01');
    expect(novemberRequest.weekEnd, '2026-11-07');
  });

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
        throwsA(isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('TEN_WEEK_PLAN_UPDATE_V1 is missing'),
        )));
    expect((await db.select(db.planCycles).getSingle()).id, before);
    expect((await db.select(db.planImportAudit).get()).length, audits);
  });

  test('full propagated response is preserved through check and final apply',
      () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final client = SupabaseClient('https://test.invalid', 'fake',
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    addTearDown(client.dispose);
    final service = WeeklyPlannerService(
        db: db, promptService: WeeklyPlanPromptService(db: db), client: client);
    final fullText = propagatedRecoveryPlan();

    expect(fullText, startsWith('TEN_WEEK_PLAN_UPDATE_V1'));
    expect(RegExp(r'^TEN_WEEK_ROW:', multiLine: true).allMatches(fullText),
        hasLength(10));
    expect(RegExp(r'^DAY [1-7]$', multiLine: true).allMatches(fullText),
        hasLength(7));
    expect(
      service.checkResponse(request: request(propagate: true), text: fullText),
      contains('7 days checked'),
    );

    final result = await service.applyGeneratedPlanText(
      request: request(propagate: true),
      generatedText: fullText,
    );
    expect(result.insertedPlanDays, 7);
    expect(await db.select(db.planLongRangeWeeks).get(), hasLength(10));
    final audit = await db.select(db.weeklyPlanBuildRequests).getSingle();
    expect(audit.responsePayloadJson, fullText);
    expect(audit.responsePayloadJson, startsWith('TEN_WEEK_PLAN_UPDATE_V1'));
  });

  test('propagation check distinguishes a missing section from an empty one',
      () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final client = SupabaseClient('https://test.invalid', 'fake',
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    addTearDown(client.dispose);
    final service = WeeklyPlannerService(
        db: db, promptService: WeeklyPlanPromptService(db: db), client: client);

    expect(
      () => service.checkResponse(
        request: request(propagate: true),
        text: 'TEN_WEEK_PLAN_UPDATE_V1\nEND_TEN_WEEK_PLAN_UPDATE_V1\n'
            '${recoveryWeek()}',
      ),
      throwsA(isA<StateError>().having(
          (error) => error.message, 'message', contains('contains no'))),
    );
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
