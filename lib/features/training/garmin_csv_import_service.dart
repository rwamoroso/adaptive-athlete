import 'dart:convert';

import 'package:csv/csv.dart';

enum GarminActivityFilter { runningOnly, allActivities }

class GarminImportOptions {
  const GarminImportOptions({
    this.activityFilter = GarminActivityFilter.runningOnly,
  });

  final GarminActivityFilter activityFilter;
}

class GarminImportError {
  const GarminImportError({required this.rowIndex, required this.reason});

  final int rowIndex;
  final String reason;

  Map<String, dynamic> toJson() => {
        'row_index': rowIndex,
        'reason': reason,
      };
}

class GarminImportResult {
  const GarminImportResult({
    required this.insertedCount,
    required this.updatedCount,
    required this.overriddenCount,
    required this.skippedCount,
    required this.errorRows,
  });

  final int insertedCount;
  final int updatedCount;
  final int overriddenCount;
  final int skippedCount;
  final List<GarminImportError> errorRows;

  Map<String, dynamic> toJson() => {
        'inserted_count': insertedCount,
        'updated_count': updatedCount,
        'overridden_count': overriddenCount,
        'skipped_count': skippedCount,
        'error_rows': errorRows.map((e) => e.toJson()).toList(),
      };

  String pretty() => const JsonEncoder.withIndent('  ').convert(toJson());
}

class GarminParsedRunRow {
  const GarminParsedRunRow({
    required this.runKey,
    required this.activityType,
    required this.startDateTime,
    required this.favorite,
    required this.title,
    required this.distanceM,
    required this.calories,
    required this.durationS,
    required this.avgHr,
    required this.maxHr,
    required this.aerobicTe,
    required this.avgRunCadence,
    required this.maxRunCadence,
    required this.avgPaceS,
    required this.bestPaceS,
    required this.totalAscent,
    required this.totalDescent,
    required this.avgStrideLengthM,
    required this.trainingStressScore,
    required this.steps,
    required this.minTemp,
    required this.maxTemp,
    required this.decompression,
    required this.bestLapTimeS,
    required this.numberOfLaps,
    required this.movingTimeS,
    required this.elapsedTimeS,
    required this.minElevation,
    required this.maxElevation,
    required this.rawMap,
  });

  final String runKey;
  final String activityType;
  final DateTime startDateTime;
  final bool? favorite;
  final String? title;
  final double? distanceM;
  final int? calories;
  final int? durationS;
  final double? avgHr;
  final double? maxHr;
  final double? aerobicTe;
  final double? avgRunCadence;
  final double? maxRunCadence;
  final double? avgPaceS;
  final double? bestPaceS;
  final double? totalAscent;
  final double? totalDescent;
  final double? avgStrideLengthM;
  final double? trainingStressScore;
  final int? steps;
  final double? minTemp;
  final double? maxTemp;
  final String? decompression;
  final double? bestLapTimeS;
  final int? numberOfLaps;
  final int? movingTimeS;
  final int? elapsedTimeS;
  final double? minElevation;
  final double? maxElevation;
  final Map<String, String?> rawMap;
}

class GarminParseOutput {
  const GarminParseOutput({
    required this.rows,
    required this.errors,
    required this.skippedCount,
  });

  final List<GarminParsedRunRow> rows;
  final List<GarminImportError> errors;
  final int skippedCount;
}

class GarminCsvImportService {
  static const double metersPerMile = 1609.344;

  static GarminParseOutput parseCsvContent(
    String content,
    GarminImportOptions options,
  ) {
    final normalized = content.replaceAll('\r\n', '\n');
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(normalized);
    if (rows.isEmpty) {
      return const GarminParseOutput(
          rows: <GarminParsedRunRow>[],
          errors: <GarminImportError>[],
          skippedCount: 0);
    }

    final headers =
        rows.first.map((e) => _normalizeHeaderKey(e.toString())).toList();
    final output = <GarminParsedRunRow>[];
    final errors = <GarminImportError>[];
    var skipped = 0;

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final mapped = <String, String?>{};
      for (var c = 0; c < headers.length; c++) {
        final value = c < row.length ? row[c] : null;
        mapped[headers[c]] = value?.toString().trim();
      }

      try {
        String? field(String key) => mapped[_normalizeHeaderKey(key)];

        final activityType = _clean(field('Activity Type'));
        if (activityType == null) {
          skipped++;
          errors.add(GarminImportError(
              rowIndex: i + 1, reason: 'missing activity type'));
          continue;
        }

        if (options.activityFilter == GarminActivityFilter.runningOnly &&
            !_isRunningActivityType(activityType)) {
          skipped++;
          continue;
        }

        final dateRaw = _clean(field('Date'));
        final start = dateRaw == null
            ? null
            : DateTime.tryParse(dateRaw.replaceFirst(' ', 'T'));
        if (start == null) {
          skipped++;
          errors.add(GarminImportError(
              rowIndex: i + 1, reason: 'invalid or missing Date'));
          continue;
        }

        final runKey = runKeyFromDateTime(start);
        final timeS = _toInt(_parseDurationSeconds(_clean(field('Time'))));
        final movingS =
            _toInt(_parseDurationSeconds(_clean(field('Moving Time'))));
        final elapsedS =
            _toInt(_parseDurationSeconds(_clean(field('Elapsed Time'))));

        final parsed = GarminParsedRunRow(
          runKey: runKey,
          activityType: activityType,
          startDateTime: start,
          favorite: _parseBool(_clean(field('Favorite'))),
          title: _clean(field('Title')),
          distanceM: _parseDouble(_clean(field('Distance'))) == null
              ? null
              : _parseDouble(_clean(field('Distance')))! * metersPerMile,
          calories: _parseInt(_clean(field('Calories'))),
          durationS: timeS,
          avgHr: _parseDouble(_clean(field('Avg HR'))),
          maxHr: _parseDouble(_clean(field('Max HR'))),
          aerobicTe: _parseDouble(_clean(field('Aerobic TE'))),
          avgRunCadence: _parseDouble(_clean(field('Avg Run Cadence'))),
          maxRunCadence: _parseDouble(_clean(field('Max Run Cadence'))),
          avgPaceS: _parseDurationSeconds(_clean(field('Avg Pace'))),
          bestPaceS: _parseDurationSeconds(_clean(field('Best Pace'))),
          totalAscent: _parseDouble(_clean(field('Total Ascent'))),
          totalDescent: _parseDouble(_clean(field('Total Descent'))),
          avgStrideLengthM: _parseDouble(_clean(field('Avg Stride Length'))),
          trainingStressScore:
              _parseDouble(_clean(field('Training Stress Score®'))),
          steps: _parseInt(_clean(field('Steps'))),
          minTemp: _parseDouble(_clean(field('Min Temp'))),
          maxTemp: _parseDouble(_clean(field('Max Temp'))),
          decompression: _clean(field('Decompression')),
          bestLapTimeS: _parseDurationSeconds(_clean(field('Best Lap Time'))),
          numberOfLaps: _parseInt(_clean(field('Number of Laps'))),
          movingTimeS: movingS,
          elapsedTimeS: elapsedS,
          minElevation: _parseDouble(_clean(field('Min Elevation'))),
          maxElevation: _parseDouble(_clean(field('Max Elevation'))),
          rawMap: mapped,
        );

        output.add(parsed);
      } catch (e) {
        skipped++;
        errors
            .add(GarminImportError(rowIndex: i + 1, reason: 'parse error: $e'));
      }
    }

    return GarminParseOutput(
        rows: output, errors: errors, skippedCount: skipped);
  }

  static String runKeyFromDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'run_${dt.year}${two(dt.month)}${two(dt.day)}_${two(dt.hour)}${two(dt.minute)}${two(dt.second)}';
  }

  static double? parseDurationSeconds(String? raw) =>
      _parseDurationSeconds(raw);

  static bool _isRunningActivityType(String raw) {
    final value = raw.trim().toLowerCase();
    return value == 'running' ||
        value == 'trail running' ||
        value == 'treadmill running' ||
        value.endsWith(' running');
  }

  static String _normalizeHeaderKey(String raw) {
    return raw
        .replaceFirst(RegExp(r'^\uFEFF'), '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
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

  static bool? _parseBool(String? raw) {
    if (raw == null) {
      return null;
    }
    if (raw.toLowerCase() == 'true') {
      return true;
    }
    if (raw.toLowerCase() == 'false') {
      return false;
    }
    return null;
  }

  static double? _parseDouble(String? raw) {
    if (raw == null) {
      return null;
    }
    final normalized = raw.replaceAll(',', '');
    return double.tryParse(normalized);
  }

  static int? _parseInt(String? raw) {
    if (raw == null) {
      return null;
    }
    final normalized = raw.replaceAll(',', '');
    return int.tryParse(normalized);
  }

  static int? _toInt(double? value) {
    if (value == null) {
      return null;
    }
    return value.round();
  }

  static double? _parseDurationSeconds(String? raw) {
    if (raw == null) {
      return null;
    }

    final parts = raw.split(':');
    if (parts.isEmpty) {
      return null;
    }

    if (parts.length == 3) {
      final h = double.tryParse(parts[0]);
      final m = double.tryParse(parts[1]);
      final s = double.tryParse(parts[2]);
      if (h == null || m == null || s == null) {
        return null;
      }
      return (h * 3600) + (m * 60) + s;
    }

    if (parts.length == 2) {
      final m = double.tryParse(parts[0]);
      final s = double.tryParse(parts[1]);
      if (m == null || s == null) {
        return null;
      }
      return (m * 60) + s;
    }

    return double.tryParse(raw);
  }
}
