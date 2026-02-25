import 'dart:io';
import 'dart:typed_data';

import 'package:adaptive_athlete/db/app_db.dart';
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

Uint8List _buildStandardWorkbookBytes({bool runConflict = false}) {
  final excel = Excel.createExcel();
  final defaultSheet = excel.getDefaultSheet();
  if (defaultSheet != null && defaultSheet != 'Strength Data') {
    excel.rename(defaultSheet, 'Strength Data');
  }

  final strengthData = excel['Strength Data'];
  strengthData.cell(CellIndex.indexByString('A1')).value =
      TextCellValue('Workout Date');
  final runData = excel['Run Data'];
  runData.cell(CellIndex.indexByString('A1')).value =
      TextCellValue('Workout Date');
  final tenWeekPlan = excel['10 Week Plan'];
  tenWeekPlan.cell(CellIndex.indexByString('A1')).value = TextCellValue('Week');
  tenWeekPlan.cell(CellIndex.indexByString('B1')).value =
      TextCellValue('Week Start');
  tenWeekPlan.cell(CellIndex.indexByString('C1')).value = TextCellValue('Week End');
  tenWeekPlan.cell(CellIndex.indexByString('A2')).value = TextCellValue('Week 1');
  tenWeekPlan.cell(CellIndex.indexByString('B2')).value =
      TextCellValue('2026-02-09');
  tenWeekPlan.cell(CellIndex.indexByString('C2')).value =
      TextCellValue('2026-02-15');

  final strengthSummary = excel['5-Day Push Pull Plan'];
  strengthSummary.cell(CellIndex.indexByString('A1')).value =
      TextCellValue('Day');
  strengthSummary.cell(CellIndex.indexByString('C1')).value =
      TextCellValue('Exercise');
  strengthSummary.cell(CellIndex.indexByString('A2')).value =
      TextCellValue('Day 1');
  strengthSummary.cell(CellIndex.indexByString('C2')).value =
      TextCellValue('Bench Press');

  final runSummary = excel['Run Plan - 5mi @ 8 min'];
  runSummary.cell(CellIndex.indexByString('A1')).value = TextCellValue('Day');
  runSummary.cell(CellIndex.indexByString('C1')).value =
      TextCellValue('Run Type');
  runSummary.cell(CellIndex.indexByString('A2')).value = TextCellValue('Day 1');
  runSummary.cell(CellIndex.indexByString('C2')).value = TextCellValue(
    runConflict ? 'Tempo' : 'Easy Aerobic',
  );

  for (var dayNumber = 1; dayNumber <= 7; dayNumber++) {
    final daySheet = excel['Day $dayNumber - Plan'];
    daySheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Date');
    daySheet.cell(CellIndex.indexByString('B1')).value = TextCellValue(
      DateTime(2026, 2, 9).add(Duration(days: dayNumber - 1)).toIso8601String(),
    );
    daySheet.cell(CellIndex.indexByString('A3')).value =
        TextCellValue('Day $dayNumber');
    daySheet.cell(CellIndex.indexByString('C3')).value = TextCellValue(
      dayNumber == 1 ? 'Easy Aerobic' : 'Recovery',
    );
    daySheet.cell(CellIndex.indexByString('D3')).value =
        TextCellValue('30 min');
    daySheet.cell(CellIndex.indexByString('E3')).value = TextCellValue('Easy');
    daySheet.cell(CellIndex.indexByString('F3')).value = TextCellValue('RPE 3');
    daySheet.cell(CellIndex.indexByString('G3')).value =
        TextCellValue('Prescribed run');

    daySheet.cell(CellIndex.indexByString('A5')).value =
        TextCellValue('Exercise');
    daySheet.cell(CellIndex.indexByString('B5')).value =
        TextCellValue('Set 1 (Wt x Reps)');
    if (dayNumber == 1) {
      daySheet.cell(CellIndex.indexByString('A6')).value =
          TextCellValue('Bench Press');
      daySheet.cell(CellIndex.indexByString('B6')).value =
          TextCellValue('205x6r2');
      daySheet.cell(CellIndex.indexByString('A8')).value = TextCellValue(
        'Exercise Alternatives (Substitute Suggestions)',
      );
      daySheet.cell(CellIndex.indexByString('A9')).value =
          TextCellValue('Prescribed Exercise');
      daySheet.cell(CellIndex.indexByString('B9')).value = TextCellValue('Rank');
      daySheet.cell(CellIndex.indexByString('C9')).value =
          TextCellValue('Alternative Exercise');
      daySheet.cell(CellIndex.indexByString('D9')).value = TextCellValue('Tier');
      daySheet.cell(CellIndex.indexByString('E9')).value =
          TextCellValue('Rationale');
      daySheet.cell(CellIndex.indexByString('F9')).value = TextCellValue('Notes');
      daySheet.cell(CellIndex.indexByString('A10')).value =
          TextCellValue('Bench Press');
      daySheet.cell(CellIndex.indexByString('B10')).value = IntCellValue(1);
      daySheet.cell(CellIndex.indexByString('C10')).value =
          TextCellValue('Dumbbell Bench Press');
      daySheet.cell(CellIndex.indexByString('D10')).value = TextCellValue('strong');
      daySheet.cell(CellIndex.indexByString('E10')).value =
          TextCellValue('Preserves horizontal press pattern');
      daySheet.cell(CellIndex.indexByString('F10')).value =
          TextCellValue('dumbbells available');
      daySheet.cell(CellIndex.indexByString('A11')).value =
          TextCellValue('Bench Press');
      daySheet.cell(CellIndex.indexByString('B11')).value = IntCellValue(2);
      daySheet.cell(CellIndex.indexByString('C11')).value =
          TextCellValue('Push-Up');
      daySheet.cell(CellIndex.indexByString('D11')).value =
          TextCellValue('acceptable');
      daySheet.cell(CellIndex.indexByString('E11')).value =
          TextCellValue('Bodyweight fallback');
    }
  }

  final encoded = excel.encode();
  if (encoded == null) {
    throw StateError('failed to encode workbook');
  }
  return Uint8List.fromList(encoded);
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
  if (value is BoolCellValue) {
    return value.value.toString();
  }
  if (value is DateCellValue) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
  return value.toString();
}

List<String> _columnValues(Excel workbook, String sheetName, int col) {
  final sheet = workbook.tables[sheetName];
  if (sheet == null) {
    return const <String>[];
  }
  final values = <String>[];
  for (final row in sheet.rows.skip(1)) {
    if (row.length <= col) {
      continue;
    }
    final text = _cellText(row[col]).trim();
    if (text.isNotEmpty) {
      values.add(text);
    }
  }
  return values;
}

List<List<String>> _sheetTextRows(Excel workbook, String sheetName) {
  final sheet = workbook.tables[sheetName];
  if (sheet == null) {
    return const <List<String>>[];
  }
  return sheet.rows
      .map((row) => row.map((cell) => _cellText(cell).trim()).toList())
      .toList();
}

void main() {
  test('standard workbook import succeeds and populates plan tables', () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    final dir = await Directory.systemTemp.createTemp('standard-import-');
    final file = File('${dir.path}\\standard.xlsx');
    await file.writeAsBytes(_buildStandardWorkbookBytes(), flush: true);

    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });

    final result = await db.importStandardWorkbookXlsx(
      filePath: file.path,
      splitStartDate: DateTime(2026, 2, 16),
    );
    expect(result.insertedPlanDays, 7);
    expect(result.insertedRunPlans, 7);
    expect(result.insertedStrengthSets, 1);
    expect(result.insertedAlternatives, 2);

    final cycles = await db.select(db.planCycles).get();
    expect(cycles.length, 1);
    final days = await db.select(db.planDays).get();
    expect(days.length, 7);
    final day1 = days.firstWhere((d) => d.dayNumber == 1);
    expect(day1.estimatedDate, '2026-02-16');
    final runPlans = await db.select(db.planPrescribedRuns).get();
    expect(runPlans.length, 7);
    final strengthSets = await db.select(db.planPrescribedStrengthSets).get();
    expect(strengthSets.length, 1);
    expect(strengthSets.first.exerciseCanonical, 'Bench Press');
    final alternatives = await db.select(db.planExerciseAlternatives).get();
    expect(alternatives.length, 2);
    expect(
      alternatives.any((a) =>
          a.prescribedExerciseCanonical == 'Bench Press' &&
          a.alternativeExerciseCanonical == 'Dumbbell Bench Press'),
      true,
    );
    final longRangeWeeks = await db.select(db.planLongRangeWeeks).get();
    expect(longRangeWeeks.length, 1);
    expect(longRangeWeeks.single.weekLabel, 'Week 1');
    expect(longRangeWeeks.single.weekStart, '2026-02-09');
  });

  test('standard workbook import rejects summary/daily conflicts', () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    final dir = await Directory.systemTemp.createTemp('standard-conflict-');
    final file = File('${dir.path}\\standard_conflict.xlsx');
    await file.writeAsBytes(
      _buildStandardWorkbookBytes(runConflict: true),
      flush: true,
    );

    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });

    expect(
      () => db.importStandardWorkbookXlsx(
        filePath: file.path,
        splitStartDate: DateTime(2026, 2, 9),
      ),
      throwsA(isA<StateError>()),
    );

    final audits = await db.select(db.planImportAudit).get();
    if (audits.isNotEmpty) {
      expect(audits.first.success, false);
    }
  });

  test('standard workbook export uses canonical tab order', () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    final dir = await Directory.systemTemp.createTemp('standard-export-');
    final importFile = File('${dir.path}\\seed.xlsx');
    await importFile.writeAsBytes(_buildStandardWorkbookBytes(), flush: true);
    await db.importStandardWorkbookXlsx(
      filePath: importFile.path,
      splitStartDate: DateTime(2026, 2, 9),
    );

    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });

    final exportPath = await db.exportStandardWorkbookXlsx(
      anchorDate: DateTime(2026, 2, 18),
      outputDirectoryPath: dir.path,
    );
    expect(File(exportPath).existsSync(), true);
    expect(
      p.basename(exportPath),
      contains('WeeklyExecution_wk_2026-02-09_to_2026-02-15'),
    );

    final exported = Excel.decodeBytes(await File(exportPath).readAsBytes());
    final names = exported.tables.keys.toList();
    expect(names.take(4).toList(), [
      'Strength Data',
      'Run Data',
      '10 Week Plan',
      '5-Day Push Pull Plan',
    ]);
    expect(names[4], 'Run Plan - 5mi @ 8 min');
    expect(names[5].toLowerCase().startsWith('day 1'), true);
    expect(names[11].toLowerCase().startsWith('day 7'), true);

    final day1SheetName =
        names.firstWhere((n) => n.toLowerCase().startsWith('day 1'));
    final day1Rows = _sheetTextRows(exported, day1SheetName);
    final flattened = day1Rows.expand((r) => r).toList();
    expect(flattened, contains('Exercise Alternatives (Substitute Suggestions)'));
    expect(flattened, contains('Prescribed Exercise'));
    expect(flattened, contains('Alternative Exercise'));
    expect(flattened, contains('Dumbbell Bench Press'));
    final tenWeekRows = _sheetTextRows(exported, '10 Week Plan');
    final tenWeekFlat = tenWeekRows.expand((r) => r).toList();
    expect(tenWeekFlat, contains('Export Context'));
    expect(tenWeekFlat, contains('Exported Week Number'));
    final perfRows = await db.select(db.planLongRangeWeekPerformance).get();
    expect(perfRows.length, 1);
  });

  test('standard workbook export includes history through export date',
      () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    final dir = await Directory.systemTemp.createTemp('standard-history-');

    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });

    await db.upsertActualStrengthSetForDate(
      dateYmd: '2026-02-18',
      exerciseCanonical: 'Back Squat',
      setIndex: 1,
      weight: 225,
      reps: 5,
      rir: 2,
    );
    await db.upsertActualStrengthSetForDate(
      dateYmd: '2026-01-31',
      exerciseCanonical: 'Bench Press',
      setIndex: 1,
      weight: 205,
      reps: 6,
      rir: 2,
    );

    await db.insertOrUpdateManualRun(
      dateString: '2026-02-18',
      startTimeMs: DateTime(2026, 2, 18, 7, 30).millisecondsSinceEpoch,
      durationS: 1800,
      distanceM: 5000,
      avgHr: 142,
      maxHr: 166,
    );
    await db.insertOrUpdateManualRun(
      dateString: '2026-01-31',
      startTimeMs: DateTime(2026, 1, 31, 7, 30).millisecondsSinceEpoch,
      durationS: 1200,
      distanceM: 3200,
      avgHr: 135,
      maxHr: 150,
    );

    final exportPath = await db.exportStandardWorkbookXlsx(
      anchorDate: DateTime(2026, 2, 21),
      outputDirectoryPath: dir.path,
    );
    final exported = Excel.decodeBytes(await File(exportPath).readAsBytes());
    final tenWeekRows = _sheetTextRows(exported, '10 Week Plan');
    expect(
      tenWeekRows.isNotEmpty ? tenWeekRows.first : const <String>[],
      contains('Strength Progression Expectation'),
    );

    final strengthDates = _columnValues(exported, 'Strength Data', 0);
    final runDates = _columnValues(exported, 'Run Data', 0);
    expect(strengthDates, contains('2026-02-18'));
    expect(strengthDates, isNot(contains('2026-01-31')));
    expect(runDates, contains('2026-02-18'));
    expect(runDates, isNot(contains('2026-01-31')));
    expect(
      p.basename(exportPath),
      contains(
          '__strength_2026-02-01_to_2026-02-21__run_2026-02-01_to_2026-02-21'),
    );
  });
}
