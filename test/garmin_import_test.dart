import 'dart:io';

import 'package:adaptive_athlete/db/app_db.dart';
import 'package:adaptive_athlete/features/training/garmin_csv_import_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

const _header =
    'Activity Type,Date,Favorite,Title,Distance,Calories,Time,Avg HR,Max HR,Aerobic TE,Avg Run Cadence,Max Run Cadence,Avg Pace,Best Pace,Total Ascent,Total Descent,Avg Stride Length,Training Stress Score®,Steps,Total Reps,Total Sets,Min Temp,Decompression,Best Lap Time,Number of Laps,Max Temp,Moving Time,Elapsed Time,Min Elevation,Max Elevation';

const _runningRow =
    'Treadmill Running,2026-02-14 11:11:40,false,"Treadmill Running","1.16","132","00:15:11","133","157","2.1","142","170","13:06","8:23","--","--","0.85","0.0","2,166","--","--","77.0","No","00:03:37.4","2","78.8","00:14:51","00:15:11","--","--"';

const _cyclingRow =
    'Cycling,2026-02-10 09:10:00,false,"Morning Ride","12.20","420","00:45:00","120","155","1.2","--","--","--","--","120","118","--","0.0","--","--","--","68.0","No","00:10:00.0","4","74.0","00:43:00","00:45:00","500","650"';

const _trailRunningRow =
    'Trail Running,2026-02-15 08:00:00,false,"Trail Run","3.00","300","00:30:00","145","171","3.0","160","180","10:00","7:30","--","--","0.90","0.0","4,000","--","--","60.0","No","00:05:00.0","3","70.0","00:29:00","00:30:00","--","--"';

String _csvWithRows(List<String> rows) => <String>[_header, ...rows].join('\n');

void main() {
  test('Garmin parser parses running row and miles -> meters', () {
    final output = GarminCsvImportService.parseCsvContent(
      _csvWithRows(const [_runningRow]),
      const GarminImportOptions(
          activityFilter: GarminActivityFilter.runningOnly),
    );

    expect(output.errors, isEmpty);
    expect(output.rows.length, 1);
    final row = output.rows.first;
    expect(row.activityType, 'Treadmill Running');
    expect(row.distanceM, closeTo(1866.839, 0.05));
    expect(row.steps, 2166);
    expect(row.totalAscent, isNull);
    expect(row.bestLapTimeS, closeTo(217.4, 0.01));
  });

  test('Activity filter controls whether non-running rows are imported', () {
    final runningOnly = GarminCsvImportService.parseCsvContent(
      _csvWithRows(const [_runningRow, _trailRunningRow, _cyclingRow]),
      const GarminImportOptions(
          activityFilter: GarminActivityFilter.runningOnly),
    );
    final allActivities = GarminCsvImportService.parseCsvContent(
      _csvWithRows(const [_runningRow, _trailRunningRow, _cyclingRow]),
      const GarminImportOptions(
          activityFilter: GarminActivityFilter.allActivities),
    );

    expect(runningOnly.rows.length, 2);
    expect(allActivities.rows.length, 3);
  });

  test('Parser handles UTF-8 BOM header and still reads running rows', () {
    final withBom = '\uFEFF$_header\n$_runningRow';
    final output = GarminCsvImportService.parseCsvContent(
      withBom,
      const GarminImportOptions(
          activityFilter: GarminActivityFilter.runningOnly),
    );
    expect(output.rows.length, 1);
    expect(output.errors, isEmpty);
  });

  test('Garmin overrides manual run with same start time and writes audit',
      () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final start = DateTime(2026, 2, 14, 11, 11, 40);
    await db.insertOrUpdateManualRun(
      dateString: '2026-02-14',
      startTimeMs: start.millisecondsSinceEpoch,
      durationS: 600,
      distanceM: 1500,
      avgHr: 120,
      maxHr: 145,
    );

    final dir = await Directory.systemTemp.createTemp('garmin-test-');
    final file = File('${dir.path}\\activities.csv');
    await file.writeAsString(_csvWithRows(const [_runningRow]));

    final result = await db.importGarminCsv(
      filePath: file.path,
      options: const GarminImportOptions(
          activityFilter: GarminActivityFilter.runningOnly),
    );

    expect(result.insertedCount, 0);
    expect(result.updatedCount, 1);
    expect(result.overriddenCount, 1);

    final runs = await db.listRunsByDate('2026-02-14');
    expect(runs.length, 1);
    expect(runs.first.source, 'garmin_import');
    expect(runs.first.maxHr, 157);

    final audits = await db.select(db.runOverrideAudit).get();
    expect(audits.length, 1);

    final detail = await db.getWorkoutDayDetail('2026-02-14');
    expect(detail.runSessions.first.overrodeManual, isTrue);
    expect(detail.runSessions.first.details, isNotNull);

    await dir.delete(recursive: true);
  });

  test('Manual input does not replace existing Garmin run with same run key',
      () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final dir = await Directory.systemTemp.createTemp('garmin-test-');
    final file = File('${dir.path}\\activities.csv');
    await file.writeAsString(_csvWithRows(const [_runningRow]));

    await db.importGarminCsv(
      filePath: file.path,
      options: const GarminImportOptions(
          activityFilter: GarminActivityFilter.runningOnly),
    );

    final start = DateTime(2026, 2, 14, 11, 11, 40);
    final outcome = await db.insertOrUpdateManualRun(
      dateString: '2026-02-14',
      startTimeMs: start.millisecondsSinceEpoch,
      durationS: 999,
      distanceM: 100,
      avgHr: 90,
      maxHr: 90,
    );

    expect(outcome.preservedGarmin, isTrue);
    final runs = await db.listRunsByDate('2026-02-14');
    expect(runs.first.source, 'garmin_import');
    expect(runs.first.durationS, 911);

    await dir.delete(recursive: true);
  });

  test('Migration v1 -> v2 backfills run_key and source_priority', () async {
    final dir = await Directory.systemTemp.createTemp('drift-migration-');
    final dbFile = File('${dir.path}\\legacy.sqlite');
    final legacy = sqlite.sqlite3.open(dbFile.path);

    legacy.execute('PRAGMA user_version = 1;');
    legacy.execute(
        'CREATE TABLE workout_days (id TEXT PRIMARY KEY, workout_date TEXT NOT NULL, created_at INTEGER NOT NULL, notes TEXT);');
    legacy.execute(
        'CREATE TABLE actual_strength_sets (id TEXT PRIMARY KEY, workout_day_id TEXT NOT NULL, performed_at INTEGER, exercise_canonical TEXT NOT NULL, set_index INTEGER NOT NULL, weight REAL, reps INTEGER, rir INTEGER, unit TEXT NOT NULL, source TEXT NOT NULL, raw_set_string TEXT, created_at INTEGER NOT NULL);');
    legacy.execute(
        'CREATE TABLE prescribed_strength_sets (id TEXT PRIMARY KEY, workout_day_id TEXT NOT NULL, exercise_canonical TEXT NOT NULL, set_index INTEGER NOT NULL, weight REAL, reps INTEGER, rir INTEGER, unit TEXT NOT NULL);');
    legacy.execute(
        'CREATE TABLE sleep_nights (id TEXT PRIMARY KEY, sleep_date TEXT NOT NULL, start_time INTEGER, end_time INTEGER, total_sleep_min INTEGER, rem_min INTEGER, deep_min INTEGER, light_min INTEGER, awake_min INTEGER, source TEXT NOT NULL);');
    legacy.execute(
        'CREATE TABLE run_sessions (id TEXT PRIMARY KEY, workout_day_id TEXT, start_time INTEGER, end_time INTEGER, duration_s INTEGER, distance_m REAL, avg_hr REAL, treadmill INTEGER, source TEXT NOT NULL);');
    legacy.execute(
        'CREATE TABLE run_segments (id TEXT PRIMARY KEY, run_session_id TEXT NOT NULL, idx INTEGER NOT NULL, duration_s INTEGER, distance_m REAL, speed_mps REAL);');
    legacy.execute(
        'CREATE TABLE rule_triggers (id TEXT PRIMARY KEY, trigger_date TEXT NOT NULL, rule_code TEXT NOT NULL, triggered INTEGER NOT NULL, details_json TEXT NOT NULL, created_at INTEGER NOT NULL);');
    legacy.execute(
        'CREATE TABLE ai_audit (id TEXT PRIMARY KEY, requested_at INTEGER NOT NULL, date_window_start TEXT, date_window_end TEXT, input_snapshot_json TEXT NOT NULL, response_json TEXT NOT NULL, schema_valid INTEGER NOT NULL, notes TEXT);');
    legacy.execute(
        "INSERT INTO workout_days (id, workout_date, created_at) VALUES ('wd1','2026-02-14',1700000000000);");
    legacy.execute(
        "INSERT INTO run_sessions (id, workout_day_id, start_time, end_time, duration_s, distance_m, avg_hr, treadmill, source) VALUES ('r1','wd1',1700000001000,1700000901000,900,1600,130,0,'manual');");
    legacy.dispose();

    final db = AppDb.forTesting(NativeDatabase(dbFile));
    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });

    final runs = await db.listRunsByDate('2026-02-14');
    expect(runs.length, 1);
    expect(runs.first.runKey, isNotEmpty);
    expect(runs.first.sourcePriority, 10);

    final columns =
        await db.customSelect("PRAGMA table_info('run_sessions')").get();
    final columnNames = columns.map((c) => c.read<String>('name')).toList();
    expect(columnNames, contains('run_key'));
    expect(columnNames, contains('max_hr'));
  });
}
