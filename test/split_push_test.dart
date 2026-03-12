import 'dart:io';
import 'dart:typed_data';

import 'package:adaptive_athlete/db/app_db.dart';
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _buildWorkbookBytesWithSessionTypes(List<String> sessionTypes) {
  if (sessionTypes.length != 7) {
    throw ArgumentError('Expected exactly 7 session types.');
  }

  final excel = Excel.createExcel();
  final defaultSheet = excel.getDefaultSheet();
  if (defaultSheet != null && defaultSheet != 'Strength Data') {
    excel.rename(defaultSheet, 'Strength Data');
  }
  excel['Run Data'];

  final strengthSummary = excel['5-Day Push Pull Plan'];
  strengthSummary.cell(CellIndex.indexByString('A1')).value =
      TextCellValue('Day');
  strengthSummary.cell(CellIndex.indexByString('B1')).value =
      TextCellValue('Session');
  strengthSummary.cell(CellIndex.indexByString('C1')).value =
      TextCellValue('Exercise');

  final runSummary = excel['Run Plan - 5mi @ 8 min'];
  runSummary.cell(CellIndex.indexByString('A1')).value = TextCellValue('Day');
  runSummary.cell(CellIndex.indexByString('C1')).value =
      TextCellValue('Run Type');

  for (var dayNumber = 1; dayNumber <= 7; dayNumber++) {
    final type = sessionTypes[dayNumber - 1];
    final typeLabel =
        type[0].toUpperCase() + (type.length > 1 ? type.substring(1) : '');
    final exercise = 'Exercise $dayNumber';
    final daySheet = excel['Day $dayNumber - $typeLabel'];

    strengthSummary.cell(CellIndex.indexByString('A${dayNumber + 1}')).value =
        TextCellValue('Day $dayNumber');
    strengthSummary.cell(CellIndex.indexByString('B${dayNumber + 1}')).value =
        TextCellValue(typeLabel);
    strengthSummary.cell(CellIndex.indexByString('C${dayNumber + 1}')).value =
        TextCellValue(exercise);

    runSummary.cell(CellIndex.indexByString('A${dayNumber + 1}')).value =
        TextCellValue('Day $dayNumber');
    runSummary.cell(CellIndex.indexByString('C${dayNumber + 1}')).value =
        TextCellValue('Easy');

    daySheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Date');
    daySheet.cell(CellIndex.indexByString('B1')).value = TextCellValue(
      DateTime(2026, 2, 9).add(Duration(days: dayNumber - 1)).toIso8601String(),
    );
    daySheet.cell(CellIndex.indexByString('A3')).value =
        TextCellValue('Day $dayNumber');
    daySheet.cell(CellIndex.indexByString('B3')).value =
        TextCellValue(typeLabel);
    daySheet.cell(CellIndex.indexByString('C3')).value = TextCellValue('Easy');
    daySheet.cell(CellIndex.indexByString('D3')).value =
        TextCellValue('30 min');
    daySheet.cell(CellIndex.indexByString('E3')).value = TextCellValue('Easy');
    daySheet.cell(CellIndex.indexByString('F3')).value = TextCellValue('RPE 3');

    daySheet.cell(CellIndex.indexByString('A5')).value =
        TextCellValue('Exercise');
    daySheet.cell(CellIndex.indexByString('B5')).value =
        TextCellValue('Set 1 (Wt x Reps)');
    daySheet.cell(CellIndex.indexByString('A6')).value =
        TextCellValue(exercise);
    daySheet.cell(CellIndex.indexByString('B6')).value =
        TextCellValue('100x5r2');
  }

  final encoded = excel.encode();
  if (encoded == null) {
    throw StateError('failed to encode workbook');
  }
  return Uint8List.fromList(encoded);
}

Future<AppDb> _seedDbWithSplit(List<String> sessionTypes) async {
  final db = AppDb.forTesting(NativeDatabase.memory());
  final dir = await Directory.systemTemp.createTemp('split-push-');
  final file = File('${dir.path}\\seed.xlsx');
  await file.writeAsBytes(
    _buildWorkbookBytesWithSessionTypes(sessionTypes),
    flush: true,
  );
  await db.importStandardWorkbookXlsx(
    filePath: file.path,
    splitStartDate: DateTime(2026, 2, 9),
  );
  await dir.delete(recursive: true);
  return db;
}

void main() {
  test('push split consumes nearest future rest day first', () async {
    final db = await _seedDbWithSplit([
      'push',
      'pull',
      'rest',
      'legs',
      'push',
      'pull',
      'legs',
    ]);
    addTearDown(db.close);

    await db.markRestDayAndPushSplit(dateYmd: '2026-02-10');
    final days = await db.select(db.planDays).get()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    expect(
      days.map((d) => d.sessionType).toList(),
      ['push', 'rest', 'pull', 'legs', 'push', 'pull', 'legs'],
    );
    expect(days[1].shiftReason, 'manual_rest');
  });

  test('manual rest is blocked when no future rest day exists', () async {
    final db = await _seedDbWithSplit([
      'push',
      'pull',
      'legs',
      'push',
      'pull',
      'legs',
      'push',
    ]);
    addTearDown(db.close);

    expect(
      () => db.markRestDayAndPushSplit(dateYmd: '2026-02-10'),
      throwsA(
        isA<StateError>().having(
          (e) => e.message.toString(),
          'message',
          contains('not optimal'),
        ),
      ),
    );
    expect(
      () => db.markRestDayAndPushSplit(
        dateYmd: '2026-02-10',
        skipSessionType: 'push',
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message.toString(),
          'message',
          contains('not optimal'),
        ),
      ),
    );
  });

  test('illness can eliminate selected day type when no future rest exists',
      () async {
    final db = await _seedDbWithSplit([
      'push',
      'pull',
      'legs',
      'push',
      'pull',
      'legs',
      'push',
    ]);
    addTearDown(db.close);

    await db.markRestDayAndPushSplit(
      dateYmd: '2026-02-10',
      skipSessionType: 'push',
      shiftReason: 'illness',
    );
    final days = await db.select(db.planDays).get()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    expect(
      days.map((d) => d.sessionType).toList(),
      ['push', 'rest', 'pull', 'legs', 'pull', 'legs', 'push'],
    );
    expect(days[1].shiftReason, 'illness');
  });

  test('push split can mark an illness day and shift prescribed run days',
      () async {
    final db = await _seedDbWithSplit([
      'push',
      'pull',
      'rest',
      'legs',
      'push',
      'pull',
      'legs',
    ]);
    addTearDown(db.close);

    await db.markRestDayAndPushSplit(
      dateYmd: '2026-02-10',
      shiftReason: 'illness',
    );
    final days = await db.select(db.planDays).get()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    expect(days[1].shiftReason, 'illness');

    final runs = await db.select(db.planPrescribedRuns).get();
    final dayNumberByPlanDayId = <String, int>{
      for (final day in days) day.id: day.dayNumber,
    };
    final runDayLabelByNumber = <int, String?>{
      for (final run in runs)
        if (dayNumberByPlanDayId[run.planDayId] != null)
          dayNumberByPlanDayId[run.planDayId]!: run.dayLabel,
    };
    expect(runDayLabelByNumber[2], isNull);
    expect(runDayLabelByNumber[3], 'Day 2');
  });

  test('push split can mark an injury day when skipping a future day type',
      () async {
    final db = await _seedDbWithSplit([
      'push',
      'pull',
      'legs',
      'push',
      'pull',
      'legs',
      'push',
    ]);
    addTearDown(db.close);

    await db.markRestDayAndPushSplit(
      dateYmd: '2026-02-10',
      skipSessionType: 'push',
      shiftReason: 'injury',
    );
    final days = await db.select(db.planDays).get()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    expect(days[1].shiftReason, 'injury');
  });

  test('push split rejects unsupported shift reason', () async {
    final db = await _seedDbWithSplit([
      'push',
      'pull',
      'rest',
      'legs',
      'push',
      'pull',
      'legs',
    ]);
    addTearDown(db.close);

    expect(
      () => db.markRestDayAndPushSplit(
        dateYmd: '2026-02-10',
        shiftReason: 'vacation',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('push split is a no-op when selected day is already rest', () async {
    final db = await _seedDbWithSplit([
      'push',
      'rest',
      'pull',
      'legs',
      'push',
      'pull',
      'legs',
    ]);
    addTearDown(db.close);

    final before = await db.select(db.planDays).get()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    await db.markRestDayAndPushSplit(dateYmd: '2026-02-10');
    final after = await db.select(db.planDays).get()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    expect(
      before.map((d) => d.sessionType).toList(),
      after.map((d) => d.sessionType).toList(),
    );
  });

  test('push split does not mutate existing actual logs', () async {
    final db = await _seedDbWithSplit([
      'push',
      'pull',
      'rest',
      'legs',
      'push',
      'pull',
      'legs',
    ]);
    addTearDown(db.close);

    final workoutDayId = await db.createOrGetWorkoutDayByDate('2026-02-12');
    await db.insertActualStrengthSet(
      workoutDayId: workoutDayId,
      exercise: 'Bench Press',
      setIndex: 1,
      weight: 185,
      reps: 5,
      rir: 2,
      unit: 'lb',
      source: 'manual',
      rawSetString: '185x5r2',
    );

    final before = await db.select(db.actualStrengthSets).get();
    expect(before.length, 1);
    expect(before.first.workoutDayId, workoutDayId);

    await db.markRestDayAndPushSplit(dateYmd: '2026-02-10');

    final after = await db.select(db.actualStrengthSets).get();
    expect(after.length, 1);
    expect(after.first.workoutDayId, workoutDayId);
  });

  test('undo rest day push removes selected rest and appends rest to end',
      () async {
    final db = await _seedDbWithSplit([
      'push',
      'pull',
      'rest',
      'legs',
      'push',
      'pull',
      'legs',
    ]);
    addTearDown(db.close);

    await db.markRestDayAndPushSplit(
      dateYmd: '2026-02-10',
      shiftReason: 'illness',
    );
    await db.undoRestDayAndPullSplit(dateYmd: '2026-02-10');

    final days = await db.select(db.planDays).get()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    expect(
      days.map((d) => d.sessionType).toList(),
      ['push', 'pull', 'legs', 'push', 'pull', 'legs', 'rest'],
    );
    expect(days.last.shiftReason, isNull);
    expect(days.where((d) => d.shiftReason != null), isEmpty);
  });

  test('workout detail resolves day number and corrected split type after push',
      () async {
    final db = await _seedDbWithSplit([
      'push',
      'pull',
      'rest',
      'legs',
      'push',
      'pull',
      'legs',
    ]);
    addTearDown(db.close);

    await db.markRestDayAndPushSplit(dateYmd: '2026-02-10');

    final detail = await db.getWorkoutDayDetail('2026-02-11');
    expect(detail.planDayNumber, 3);
    expect(detail.planSessionType, 'pull');
  });
}
