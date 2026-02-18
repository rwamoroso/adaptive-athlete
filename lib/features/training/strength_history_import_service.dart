import 'dart:convert';
import 'dart:typed_data';

import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

class StrengthImportError {
  const StrengthImportError({required this.rowIndex, required this.reason});

  final int rowIndex;
  final String reason;

  Map<String, dynamic> toJson() => {
        'row_index': rowIndex,
        'reason': reason,
      };
}

class StrengthImportResult {
  const StrengthImportResult({
    required this.insertedCount,
    required this.skippedCount,
    required this.errorRows,
  });

  final int insertedCount;
  final int skippedCount;
  final List<StrengthImportError> errorRows;

  Map<String, dynamic> toJson() => {
        'inserted_count': insertedCount,
        'skipped_count': skippedCount,
        'error_rows': errorRows.map((e) => e.toJson()).toList(),
      };

  String pretty() => const JsonEncoder.withIndent('  ').convert(toJson());
}

class StrengthParsedSetRow {
  const StrengthParsedSetRow({
    required this.date,
    required this.exercise,
    required this.setIndex,
    required this.weightLb,
    required this.reps,
    required this.rir,
    required this.rawMap,
  });

  final DateTime date;
  final String exercise;
  final int setIndex;
  final double? weightLb;
  final int? reps;
  final int? rir;
  final Map<String, String?> rawMap;
}

class StrengthParseOutput {
  const StrengthParseOutput({
    required this.rows,
    required this.errors,
    required this.skippedCount,
  });

  final List<StrengthParsedSetRow> rows;
  final List<StrengthImportError> errors;
  final int skippedCount;
}

class StrengthHistoryImportService {
  static StrengthParseOutput parseXlsxBytes(Uint8List bytes) {
    SpreadsheetDecoder decoder;
    try {
      decoder = SpreadsheetDecoder.decodeBytes(bytes, update: false);
    } catch (e) {
      return StrengthParseOutput(
        rows: const <StrengthParsedSetRow>[],
        errors: <StrengthImportError>[
          StrengthImportError(rowIndex: 0, reason: 'workbook parse failed: $e')
        ],
        skippedCount: 0,
      );
    }

    if (decoder.tables.isEmpty) {
      return const StrengthParseOutput(
        rows: <StrengthParsedSetRow>[],
        errors: <StrengthImportError>[
          StrengthImportError(rowIndex: 0, reason: 'workbook has no sheets')
        ],
        skippedCount: 0,
      );
    }

    final table =
        decoder.tables['Strength_Log_All'] ?? decoder.tables.values.first;
    final rows = table.rows;
    if (rows.isEmpty) {
      return const StrengthParseOutput(
        rows: <StrengthParsedSetRow>[],
        errors: <StrengthImportError>[
          StrengthImportError(rowIndex: 0, reason: 'sheet is empty')
        ],
        skippedCount: 0,
      );
    }

    final headerRow = rows.first;
    final headerMap = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final key = _normalizeHeader(_asString(_cellAt(headerRow, i)));
      if (key.isNotEmpty) {
        headerMap[key] = i;
      }
    }

    final dateIdx = headerMap['date'];
    final exerciseIdx = headerMap['exercise'];
    final setIdx = headerMap['set'];
    final weightIdx = headerMap['weight_lb'];
    final repsIdx = headerMap['reps'];
    final rirIdx = headerMap['rir'];

    if (dateIdx == null || exerciseIdx == null || setIdx == null) {
      return const StrengthParseOutput(
        rows: <StrengthParsedSetRow>[],
        errors: <StrengthImportError>[
          StrengthImportError(
            rowIndex: 0,
            reason: 'required headers missing: Date/Exercise/Set',
          ),
        ],
        skippedCount: 0,
      );
    }

    final parsed = <StrengthParsedSetRow>[];
    final errors = <StrengthImportError>[];
    var skipped = 0;

    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (_isRowEmpty(row)) {
        continue;
      }

      final raw = <String, String?>{};
      for (final entry in headerMap.entries) {
        raw[entry.key] = _asString(_cellAt(row, entry.value));
      }

      final parsedDate = _parseDate(_cellAt(row, dateIdx));
      if (parsedDate == null) {
        skipped++;
        errors.add(
          StrengthImportError(
              rowIndex: r + 1, reason: 'invalid or missing Date'),
        );
        continue;
      }

      final exercise = _clean(_asString(_cellAt(row, exerciseIdx)));
      if (exercise == null) {
        skipped++;
        errors.add(
          StrengthImportError(rowIndex: r + 1, reason: 'missing Exercise'),
        );
        continue;
      }

      final parsedSetIndex = _parseInt(_cellAt(row, setIdx));
      if (parsedSetIndex == null) {
        skipped++;
        errors.add(
          StrengthImportError(
              rowIndex: r + 1, reason: 'missing or invalid Set'),
        );
        continue;
      }

      parsed.add(
        StrengthParsedSetRow(
          date: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
          exercise: exercise,
          setIndex: parsedSetIndex,
          weightLb: _parseDouble(_cellAt(row, weightIdx)),
          reps: _parseInt(_cellAt(row, repsIdx)),
          rir: _parseInt(_cellAt(row, rirIdx)),
          rawMap: raw,
        ),
      );
    }

    return StrengthParseOutput(
        rows: parsed, errors: errors, skippedCount: skipped);
  }

  static dynamic _cellAt(List row, int? index) {
    if (index == null || index < 0 || index >= row.length) {
      return null;
    }
    return row[index];
  }

  static bool _isRowEmpty(List row) {
    for (final cell in row) {
      if (_clean(_asString(cell)) != null) {
        return false;
      }
    }
    return true;
  }

  static String _normalizeHeader(String? value) {
    if (value == null) {
      return '';
    }
    return value.trim().toLowerCase().replaceAll(RegExp(r'[\s/]+'), '_');
  }

  static String? _asString(dynamic value) {
    if (value == null) {
      return null;
    }
    return value.toString().trim();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is num) {
      final millis = (value.toDouble() * 24 * 3600 * 1000).round();
      return DateTime(1899, 12, 30).add(Duration(milliseconds: millis));
    }

    final raw = _clean(value.toString());
    if (raw == null) {
      return null;
    }

    final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (parsed != null) {
      return parsed;
    }

    final slash = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2,4})$').firstMatch(raw);
    if (slash != null) {
      final m = int.parse(slash.group(1)!);
      final d = int.parse(slash.group(2)!);
      var y = int.parse(slash.group(3)!);
      if (y < 100) {
        y += 2000;
      }
      return DateTime(y, m, d);
    }

    return null;
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

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    final cleaned = _clean(value.toString());
    if (cleaned == null) {
      return null;
    }
    return double.tryParse(cleaned.replaceAll(',', ''));
  }

  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is double) {
      if (value == value.roundToDouble()) {
        return value.toInt();
      }
      return null;
    }

    final cleaned = _clean(value.toString());
    if (cleaned == null) {
      return null;
    }
    final normalized = cleaned.replaceAll(',', '');
    final direct = int.tryParse(normalized);
    if (direct != null) {
      return direct;
    }
    final decimal = double.tryParse(normalized);
    if (decimal != null && decimal == decimal.roundToDouble()) {
      return decimal.toInt();
    }
    return null;
  }
}
