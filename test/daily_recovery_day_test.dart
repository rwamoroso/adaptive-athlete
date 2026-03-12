import 'dart:io';
import 'dart:typed_data';

import 'package:adaptive_athlete/db/app_db.dart';
import 'package:adaptive_athlete/features/training/daily_screen.dart';
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
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
  final dir = await Directory.systemTemp.createTemp('daily-recovery-');
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
  testWidgets('recovery reason dialog shows manual rest warning text',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RecoveryReasonDialog(),
        ),
      ),
    );

    expect(find.text('Manual Rest (Warning)'), findsOneWidget);
    expect(find.textContaining('not optimal'), findsOneWidget);
  });

  test('manual-rest no-future-rest error does not trigger skip picker flow',
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

    try {
      await db.markRestDayAndPushSplit(dateYmd: '2026-02-10');
      fail('Expected StateError');
    } on StateError catch (e) {
      expect(shouldShowSkipTypePickerForPushError(e.message.toString()), false);
      expect(e.message.toString(), contains('not optimal'));
    }
  });

  test('illness no-future-rest error triggers skip picker flow', () async {
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

    try {
      await db.markRestDayAndPushSplit(
        dateYmd: '2026-02-10',
        shiftReason: 'illness',
      );
      fail('Expected StateError');
    } on StateError catch (e) {
      expect(shouldShowSkipTypePickerForPushError(e.message.toString()), true);
      expect(e.message.toString(), contains('Choose a day type to skip'));
    }
  });
}
