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
    }
  }

  final encoded = excel.encode();
  if (encoded == null) {
    throw StateError('failed to encode workbook');
  }
  return Uint8List.fromList(encoded);
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
      '5-Day Push Pull Plan',
      'Run Plan - 5mi @ 8 min',
    ]);
    expect(names[4].toLowerCase().startsWith('day 1'), true);
    expect(names[10].toLowerCase().startsWith('day 7'), true);
  });
}
