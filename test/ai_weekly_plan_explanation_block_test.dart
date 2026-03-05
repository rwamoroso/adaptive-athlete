import 'package:adaptive_athlete/db/app_db.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

String _buildWeeklyPlanWithExplanationBlock() {
  final b = StringBuffer();
  b.writeln('WEEK_PLAN_V1');
  b.writeln('WEEK_START: 2026-03-02');
  b.writeln('WEEK_END: 2026-03-08');
  b.writeln();
  for (var day = 1; day <= 7; day++) {
    b.writeln('DAY $day');
    b.writeln('SESSION_TYPE: rest');
    b.writeln('DAY_LABEL: Recovery Day $day');
    b.writeln('LIFT_FOCUS:');
    b.writeln('RUN_TYPE:');
    b.writeln('RUN_DURATION:');
    b.writeln('RUN_TARGET_PACE:');
    b.writeln('RUN_HR_GUARDRAILS:');
    b.writeln('RUN_NOTES:');
    b.writeln('END DAY $day');
    b.writeln();
  }
  b.writeln('PLAN_EXPLANATION_V1');
  b.writeln('WHY_THIS_WEEK: Recovery-focused structure to absorb prior load.');
  b.writeln(
      'ADAPTATION_OR_GROWTH: Improves recovery capacity and readiness for the next progression block.');
  b.writeln(
      'LOGIC_OVERVIEW: Low stress, maintain movement quality, protect adaptation.');
  b.writeln('END_PLAN_EXPLANATION_V1');
  return b.toString();
}

void main() {
  test('AI weekly import accepts PLAN_EXPLANATION_V1 block', () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final result = await db.importAiWeeklyPlanText(
      text: _buildWeeklyPlanWithExplanationBlock(),
      splitStartDate: DateTime(2026, 3, 2),
    );

    expect(result.insertedPlanDays, 7);
    final cycles = await db.select(db.planCycles).get();
    expect(cycles, isNotEmpty);
  });
}
