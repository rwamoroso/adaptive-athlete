import 'dart:convert';
import 'dart:io';

import 'package:adaptive_athlete/db/app_db.dart';
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

String _buildAiPlanTextWithTenWeekBlock() {
  final b = StringBuffer();
  b.writeln('TEN_WEEK_PLAN_UPDATE_V1');
  final start = DateTime(2026, 2, 9);
  for (var i = 0; i < 10; i++) {
    final weekStart = start.add(Duration(days: i * 7));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekNo = i + 1;
    final deload = (weekNo == 4 || weekNo == 8 || weekNo == 10) ? 'yes' : 'no';
    b.writeln(
      'TEN_WEEK_ROW: '
      'week=Week $weekNo | '
      'week_start=${weekStart.toIso8601String().split('T').first} | '
      'week_end=${weekEnd.toIso8601String().split('T').first} | '
      'run_focus=Week $weekNo run focus | '
      'strength_focus=Week $weekNo strength focus | '
      'strength_progression_expectation=Week $weekNo strength expectation | '
      'primary_progression_target=Week $weekNo target | '
      'recovery_emphasis=Week $weekNo recovery | '
      'deload=$deload | '
      'notes=Week $weekNo notes',
    );
  }
  b.writeln('END_TEN_WEEK_PLAN_UPDATE_V1');
  b.writeln();
  b.writeln('WEEK_PLAN_V1');
  b.writeln('WEEK_START: 2026-02-23');
  b.writeln('WEEK_END: 2026-03-01');
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
  return b.toString();
}

String _cellText(Data? cell) {
  final value = cell?.value;
  if (value == null) {
    return '';
  }
  if (value is TextCellValue) {
    return value.value.toString();
  }
  if (value is IntCellValue) {
    return value.value.toString();
  }
  if (value is DoubleCellValue) {
    return value.value.toString();
  }
  return value.toString();
}

void main() {
  test('AI weekly text import persists 10 week plan snapshot and export marks week', () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    final dir = await Directory.systemTemp.createTemp('ai-ten-week-export-');
    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });

    final text = _buildAiPlanTextWithTenWeekBlock();
    final result = await db.importAiWeeklyPlanText(
      text: text,
      splitStartDate: DateTime(2026, 2, 23),
    );
    expect(result.insertedPlanDays, 7);

    final snapshots = await (db.select(db.planSummarySnapshots)
          ..where((s) => s.tabName.equals('10 Week Plan')))
        .get();
    expect(snapshots.length, 1);
    final decoded = jsonDecode(snapshots.single.snapshotJson) as Map<String, dynamic>;
    final rows = (decoded['rows'] as List).cast<List>();
    expect(rows.length, 11);
    expect(rows.first.first, 'Week');
    expect(rows.first, contains('Strength Progression Expectation'));
    expect(rows[4][0], 'Week 4');
    final longRangeWeeks = await db.select(db.planLongRangeWeeks).get();
    expect(longRangeWeeks.length, 10);
    final wk3 = longRangeWeeks.firstWhere((w) => w.weekStart == '2026-02-23');
    expect(wk3.weekLabel, 'Week 3');
    expect(wk3.weekNumber, 3);
    expect(wk3.strengthProgressionExpectation, 'Week 3 strength expectation');

    final exportPath = await db.exportStandardWorkbookXlsx(
      anchorDate: DateTime(2026, 3, 5),
      outputDirectoryPath: dir.path,
    );
    final exported = Excel.decodeBytes(await File(exportPath).readAsBytes());
    final tenWeek = exported.tables['10 Week Plan'];
    expect(tenWeek, isNotNull);
    final sheet = tenWeek!;
    expect(_cellText(sheet.rows[0][10]), 'Export Context');
    expect(_cellText(sheet.rows[1][10]), 'Exported Week Number');
    expect(_cellText(sheet.rows[1][11]), '3');
    expect(_cellText(sheet.rows[2][11]), 'Week 3');
    expect(_cellText(sheet.rows[3][11]), '2026-02-23');
    expect(_cellText(sheet.rows[4][11]), '2026-03-01');
    final perfRows = await db.select(db.planLongRangeWeekPerformance).get();
    expect(perfRows.length, 1);
    expect(perfRows.single.weekNumber, 3);
    expect(perfRows.single.weekStart, '2026-02-23');
    expect(perfRows.single.evaluationSource, 'standard_workbook_export');
    expect(
      perfRows.single.strengthProgressionExpectation,
      'Week 3 strength expectation',
    );
    expect(
      perfRows.single.strengthProgressionEvaluation,
      'insufficient_data',
    );
  });
}
