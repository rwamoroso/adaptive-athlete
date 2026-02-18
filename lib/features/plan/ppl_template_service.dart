import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

import '../../core/parsing/exercise_normalizer.dart';

class PplTemplateSet {
  const PplTemplateSet({
    required this.exercise,
    required this.setIndex,
    required this.weight,
    required this.reps,
    required this.rir,
    required this.unit,
  });

  final String exercise;
  final int setIndex;
  final double? weight;
  final int? reps;
  final int? rir;
  final String unit;
}

class PplTemplateDay {
  const PplTemplateDay({
    required this.dayNumber,
    required this.sheetName,
    required this.sets,
  });

  final int dayNumber;
  final String sheetName;
  final List<PplTemplateSet> sets;
}

class PplTemplateParseResult {
  const PplTemplateParseResult({
    required this.days,
    required this.errors,
  });

  final List<PplTemplateDay> days;
  final List<String> errors;
}

class PplTemplateService {
  static final RegExp _daySheetPattern =
      RegExp(r'^day\s*(\d+)\b', caseSensitive: false);

  static PplTemplateParseResult parseBytes(List<int> bytes) {
    SpreadsheetDecoder decoder;
    try {
      decoder = SpreadsheetDecoder.decodeBytes(bytes, update: false);
    } catch (e) {
      return PplTemplateParseResult(
        days: const <PplTemplateDay>[],
        errors: <String>['Workbook parse failed: $e'],
      );
    }

    final errors = <String>[];
    final parsedDays = <PplTemplateDay>[];

    for (final entry in decoder.tables.entries) {
      final match = _daySheetPattern.firstMatch(entry.key.trim());
      if (match == null) {
        continue;
      }

      final dayNumber = int.tryParse(match.group(1)!);
      if (dayNumber == null) {
        continue;
      }

      final parsed = _parseDayTable(dayNumber, entry.key, entry.value.rows);
      parsedDays.add(parsed.$1);
      errors.addAll(parsed.$2);
    }

    parsedDays.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    if (parsedDays.isEmpty) {
      errors.add('No Day sheets found (expected names like "Day 1 - Push").');
    }

    return PplTemplateParseResult(days: parsedDays, errors: errors);
  }

  static (PplTemplateDay, List<String>) _parseDayTable(
    int dayNumber,
    String sheetName,
    List<List> rows,
  ) {
    final errors = <String>[];

    var headerRowIndex = -1;
    var exerciseColumn = -1;
    final setColumns = <int>[];

    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      for (var c = 0; c < row.length; c++) {
        final value = _clean(_cellToString(_cellAt(row, c)));
        if (value?.toLowerCase() == 'exercise') {
          headerRowIndex = r;
          exerciseColumn = c;
          for (var sc = c + 1; sc < row.length; sc++) {
            final header = _clean(_cellToString(_cellAt(row, sc))) ?? '';
            if (header.toLowerCase().startsWith('set ')) {
              setColumns.add(sc);
            }
          }
          break;
        }
      }
      if (headerRowIndex != -1) {
        break;
      }
    }

    if (headerRowIndex == -1 || exerciseColumn == -1 || setColumns.isEmpty) {
      errors.add(
          '[$sheetName] missing strength header row (Exercise + Set columns).');
      return (
        PplTemplateDay(
          dayNumber: dayNumber,
          sheetName: sheetName,
          sets: const <PplTemplateSet>[],
        ),
        errors,
      );
    }

    final sets = <PplTemplateSet>[];

    for (var r = headerRowIndex + 1; r < rows.length; r++) {
      final row = rows[r];
      final exerciseRaw =
          _clean(_cellToString(_cellAt(row, exerciseColumn))) ?? '';

      if (exerciseRaw.isEmpty) {
        continue;
      }
      if (exerciseRaw.toLowerCase().contains('run results')) {
        break;
      }
      if (exerciseRaw.toLowerCase().contains('auto-progression')) {
        continue;
      }

      final exercise = ExerciseNormalizer.normalize(exerciseRaw);
      for (var i = 0; i < setColumns.length; i++) {
        final value = _clean(_cellToString(_cellAt(row, setColumns[i])));
        if (value == null) {
          continue;
        }
        final parsed = _parseSetCell(value);
        sets.add(
          PplTemplateSet(
            exercise: exercise,
            setIndex: i + 1,
            weight: parsed.weight,
            reps: parsed.reps,
            rir: parsed.rir,
            unit: parsed.unit,
          ),
        );
      }
    }

    return (
      PplTemplateDay(dayNumber: dayNumber, sheetName: sheetName, sets: sets),
      errors,
    );
  }

  static dynamic _cellAt(List row, int idx) =>
      (idx >= 0 && idx < row.length) ? row[idx] : null;

  static String? _cellToString(dynamic value) {
    if (value == null) {
      return null;
    }
    return value.toString();
  }

  static String? _clean(String? raw) {
    if (raw == null) {
      return null;
    }
    final value = raw.trim();
    if (value.isEmpty || value == '--') {
      return null;
    }
    return value;
  }

  static final RegExp _weightedPattern =
      RegExp(r'^(\d+(?:\.\d+)?)\s*x\s*(\d+)(?:\s*r\s*(\d+))?$');
  static final RegExp _bwPattern =
      RegExp(r'^bw\s*x\s*(\d+)(?:\s*r\s*(\d+))?$', caseSensitive: false);
  static final RegExp _repsOnlyPattern = RegExp(r'^(\d+)(?:\s*r\s*(\d+))?$');
  static final RegExp _slashSidePattern =
      RegExp(r'^(\d+)\s*/\s*side(?:\s*r\s*(\d+))?$', caseSensitive: false);
  static final RegExp _secondsSidePattern =
      RegExp(r'^(\d+)\s*s\s*/\s*side(?:\s*r\s*(\d+))?$', caseSensitive: false);

  static _ParsedSet _parseSetCell(String value) {
    final normalized = value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    final weighted = _weightedPattern.firstMatch(normalized);
    if (weighted != null) {
      return _ParsedSet(
        weight: double.tryParse(weighted.group(1)!),
        reps: int.tryParse(weighted.group(2)!),
        rir:
            weighted.group(3) == null ? null : int.tryParse(weighted.group(3)!),
        unit: 'lb',
      );
    }

    final bw = _bwPattern.firstMatch(normalized);
    if (bw != null) {
      return _ParsedSet(
        weight: null,
        reps: int.tryParse(bw.group(1)!),
        rir: bw.group(2) == null ? null : int.tryParse(bw.group(2)!),
        unit: 'bw',
      );
    }

    final slashSide = _slashSidePattern.firstMatch(normalized);
    if (slashSide != null) {
      return _ParsedSet(
        weight: null,
        reps: int.tryParse(slashSide.group(1)!),
        rir: slashSide.group(2) == null
            ? null
            : int.tryParse(slashSide.group(2)!),
        unit: 'unknown',
      );
    }

    final repsOnly = _repsOnlyPattern.firstMatch(normalized);
    if (repsOnly != null) {
      return _ParsedSet(
        weight: null,
        reps: int.tryParse(repsOnly.group(1)!),
        rir:
            repsOnly.group(2) == null ? null : int.tryParse(repsOnly.group(2)!),
        unit: 'unknown',
      );
    }

    final secondsSide = _secondsSidePattern.firstMatch(normalized);
    if (secondsSide != null) {
      return _ParsedSet(
        weight: null,
        reps: null,
        rir: secondsSide.group(2) == null
            ? null
            : int.tryParse(secondsSide.group(2)!),
        unit: 'unknown',
      );
    }

    return const _ParsedSet(
        weight: null, reps: null, rir: null, unit: 'unknown');
  }
}

class _ParsedSet {
  const _ParsedSet({
    required this.weight,
    required this.reps,
    required this.rir,
    required this.unit,
  });

  final double? weight;
  final int? reps;
  final int? rir;
  final String unit;
}
