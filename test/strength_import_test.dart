import 'dart:io';
import 'dart:typed_data';

import 'package:adaptive_athlete/db/app_db.dart';
import 'package:adaptive_athlete/features/training/strength_history_import_service.dart';
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _buildWorkbookBytes({
  required List<List<String?>> rows,
  String sheetName = 'Strength_Log_All',
}) {
  final excel = Excel.createExcel();
  final defaultSheet = excel.getDefaultSheet();
  if (defaultSheet != null && defaultSheet != sheetName) {
    excel.rename(defaultSheet, sheetName);
  }
  final sheet = excel[sheetName];

  for (var r = 0; r < rows.length; r++) {
    final row = rows[r];
    for (var c = 0; c < row.length; c++) {
      final value = row[c];
      if (value == null) {
        continue;
      }
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
          .value = TextCellValue(value);
    }
  }

  final encoded = excel.encode();
  if (encoded == null) {
    throw StateError('Failed to encode workbook');
  }
  return Uint8List.fromList(encoded);
}

void main() {
  test('strength parser reads xlsx rows and keeps unknowns null', () {
    final bytes = _buildWorkbookBytes(rows: const [
      ['Date', 'Exercise', 'Set', 'Weight_lb', 'Reps', 'RIR'],
      ['2026-01-15', 'Back Squat', '1', '225', '5', '2'],
      ['2026-01-15', 'Pull Up', '2', null, '8', null],
    ]);

    final output = StrengthHistoryImportService.parseXlsxBytes(bytes);
    expect(output.errors, isEmpty);
    expect(output.rows.length, 2);

    final first = output.rows.first;
    expect(first.exercise, 'Back Squat');
    expect(first.setIndex, 1);
    expect(first.weightLb, 225);
    expect(first.reps, 5);
    expect(first.rir, 2);

    final second = output.rows.last;
    expect(second.weightLb, isNull);
    expect(second.reps, 8);
    expect(second.rir, isNull);
  });

  test('strength import is idempotent for duplicate re-import', () async {
    final bytes = _buildWorkbookBytes(rows: const [
      ['Date', 'Exercise', 'Set', 'Weight_lb', 'Reps', 'RIR'],
      ['2026-01-15', 'Back Squat', '1', '225', '5', '2'],
    ]);

    final dir = await Directory.systemTemp.createTemp('strength-import-');
    final file = File('${dir.path}\\strength.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });

    final first = await db.importStrengthHistoryXlsx(filePath: file.path);
    final second = await db.importStrengthHistoryXlsx(filePath: file.path);

    expect(first.insertedCount, 1);
    expect(first.skippedCount, 0);
    expect(second.insertedCount, 0);
    expect(second.skippedCount, 1);

    final rows = await db.select(db.actualStrengthSets).get();
    expect(rows.length, 1);
    expect(rows.first.exerciseCanonical, 'Back Squat');
    expect(rows.first.source, 'import');
    expect(rows.first.rawSetString, '225x5r2');
  });
}
