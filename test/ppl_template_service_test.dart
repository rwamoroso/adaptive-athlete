import 'dart:typed_data';

import 'package:adaptive_athlete/features/plan/ppl_template_service.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _buildTemplateWorkbook() {
  final excel = Excel.createExcel();
  final defaultSheet = excel.getDefaultSheet();
  if (defaultSheet != null && defaultSheet != 'Day 1 - Push + Core') {
    excel.rename(defaultSheet, 'Day 1 - Push + Core');
  }

  final day1 = excel['Day 1 - Push + Core'];
  day1.cell(CellIndex.indexByString('A5')).value = TextCellValue('Exercise');
  day1.cell(CellIndex.indexByString('B5')).value =
      TextCellValue('Set 1 (Wt x Reps)');
  day1.cell(CellIndex.indexByString('C5')).value =
      TextCellValue('Set 2 (Wt x Reps)');
  day1.cell(CellIndex.indexByString('A6')).value = TextCellValue('Bench Press');
  day1.cell(CellIndex.indexByString('B6')).value = TextCellValue('210x10r2');
  day1.cell(CellIndex.indexByString('C6')).value = TextCellValue('230x8r1');
  day1.cell(CellIndex.indexByString('A7')).value =
      TextCellValue('CORE: Pallof Press');
  day1.cell(CellIndex.indexByString('B7')).value = TextCellValue('10/side r2');

  final day2 = excel['Day 2 - Pull + Core'];
  day2.cell(CellIndex.indexByString('A5')).value = TextCellValue('Exercise');
  day2.cell(CellIndex.indexByString('B5')).value =
      TextCellValue('Set 1 (Wt x Reps)');
  day2.cell(CellIndex.indexByString('A6')).value =
      TextCellValue('Pull-Ups (weighted/assisted)');
  day2.cell(CellIndex.indexByString('B6')).value = TextCellValue('7r2');

  final encoded = excel.encode();
  if (encoded == null) {
    throw StateError('Failed to encode workbook');
  }
  return Uint8List.fromList(encoded);
}

void main() {
  test('parses Day sheets and set prescriptions', () {
    final bytes = _buildTemplateWorkbook();
    final parsed = PplTemplateService.parseBytes(bytes);

    expect(parsed.errors, isEmpty);
    expect(parsed.days.length, 2);

    final day1 = parsed.days.first;
    expect(day1.dayNumber, 1);
    expect(day1.sets.length, 3);
    expect(day1.sets[0].exercise, 'Bench Press');
    expect(day1.sets[0].weight, 210);
    expect(day1.sets[0].reps, 10);
    expect(day1.sets[0].rir, 2);

    final coreSet = day1.sets[2];
    expect(coreSet.exercise, 'Core: Pallof Press');
    expect(coreSet.weight, isNull);
    expect(coreSet.reps, 10);
    expect(coreSet.rir, 2);

    final day2 = parsed.days[1];
    expect(day2.dayNumber, 2);
    expect(day2.sets.single.reps, 7);
    expect(day2.sets.single.rir, 2);
  });
}
