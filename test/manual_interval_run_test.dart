import 'dart:convert';

import 'package:adaptive_athlete/db/app_db.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('insertOrUpdateManualRun stores interval/rest segments', () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const dateYmd = '2026-02-15';
    final startTime = DateTime(2026, 2, 15, 7, 0).millisecondsSinceEpoch;

    final outcome = await db.insertOrUpdateManualRun(
      dateString: dateYmd,
      startTimeMs: startTime,
      durationS: 600,
      distanceM: 2000,
      avgHr: 142,
      maxHr: 167,
      manualSegments: const <ManualRunSegmentInput>[
        ManualRunSegmentInput(
          idx: 1,
          durationS: 180,
          distanceM: 800,
          kind: 'interval',
          speedMps: 4.44,
        ),
        ManualRunSegmentInput(
          idx: 2,
          durationS: 120,
          distanceM: 0,
          kind: 'rest',
          speedMps: null,
        ),
      ],
    );

    expect(outcome.inserted, true);
    expect(outcome.updated, false);

    final run = await (db.select(db.runSessions)
          ..where((r) => r.id.equals(outcome.runSessionId)))
        .getSingle();
    final segments = await (db.select(db.runSegments)
          ..where((s) => s.runSessionId.equals(outcome.runSessionId))
          ..orderBy([(s) => drift.OrderingTerm.asc(s.idx)]))
        .get();

    expect(segments.length, 2);
    expect(segments[0].idx, 1);
    expect(segments[0].durationS, 180);
    expect(segments[0].distanceM, 800);
    expect(segments[1].idx, 2);
    expect(segments[1].durationS, 120);
    expect(segments[1].distanceM, 0);

    final metrics =
        jsonDecode(run.rawMetricsJson ?? '{}') as Map<String, dynamic>;
    final rawSegments = (metrics['manual_segments'] as List<dynamic>)
        .cast<Map<dynamic, dynamic>>();
    expect(rawSegments.length, 2);
    expect(rawSegments[0]['kind'], 'interval');
    expect(rawSegments[1]['kind'], 'rest');
  });

  test('manual run update replaces and clears interval segments', () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const dateYmd = '2026-02-15';
    final startTime = DateTime(2026, 2, 15, 8, 0).millisecondsSinceEpoch;

    final first = await db.insertOrUpdateManualRun(
      dateString: dateYmd,
      startTimeMs: startTime,
      durationS: 500,
      distanceM: 1500,
      avgHr: 139,
      maxHr: 162,
      manualSegments: const <ManualRunSegmentInput>[
        ManualRunSegmentInput(
          idx: 1,
          durationS: 120,
          distanceM: 600,
          kind: 'interval',
          speedMps: 5,
        ),
        ManualRunSegmentInput(
          idx: 2,
          durationS: 90,
          distanceM: 0,
          kind: 'rest',
          speedMps: null,
        ),
      ],
    );

    final second = await db.insertOrUpdateManualRun(
      dateString: dateYmd,
      startTimeMs: startTime,
      durationS: 420,
      distanceM: 1200,
      avgHr: 136,
      maxHr: 158,
      manualSegments: const <ManualRunSegmentInput>[
        ManualRunSegmentInput(
          idx: 1,
          durationS: 210,
          distanceM: 700,
          kind: 'interval',
          speedMps: 3.33,
        ),
      ],
    );

    expect(second.inserted, false);
    expect(second.updated, true);
    expect(second.runSessionId, first.runSessionId);

    var segments = await (db.select(db.runSegments)
          ..where((s) => s.runSessionId.equals(second.runSessionId))
          ..orderBy([(s) => drift.OrderingTerm.asc(s.idx)]))
        .get();
    expect(segments.length, 1);
    expect(segments.first.idx, 1);
    expect(segments.first.durationS, 210);
    expect(segments.first.distanceM, 700);

    await db.insertOrUpdateManualRun(
      dateString: dateYmd,
      startTimeMs: startTime,
      durationS: 300,
      distanceM: 1000,
      avgHr: 132,
      maxHr: 150,
      manualSegments: const <ManualRunSegmentInput>[],
    );

    segments = await (db.select(db.runSegments)
          ..where((s) => s.runSessionId.equals(second.runSessionId)))
        .get();
    expect(segments, isEmpty);

    final run = await (db.select(db.runSessions)
          ..where((r) => r.id.equals(second.runSessionId)))
        .getSingle();
    expect(run.rawMetricsJson, isNull);
  });

  test('insertOrUpdateManualRun stores duration-based cardio without distance',
      () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const dateYmd = '2026-02-16';
    final startTime = DateTime(2026, 2, 16, 6, 30).millisecondsSinceEpoch;

    final outcome = await db.insertOrUpdateManualRun(
      dateString: dateYmd,
      startTimeMs: startTime,
      durationS: 1500,
      distanceM: 0,
      avgHr: 138,
      maxHr: 154,
      title: 'Stair Stepper',
      activityType: 'Stair Stepper',
    );

    expect(outcome.inserted, true);

    final run = await (db.select(db.runSessions)
          ..where((r) => r.id.equals(outcome.runSessionId)))
        .getSingle();
    expect(run.distanceM, 0);
    expect(run.title, 'Stair Stepper');
    expect(run.activityType, 'Stair Stepper');
    expect(run.durationS, 1500);
  });

  test('insertOrUpdateManualRun stores treadmill manual entries', () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const dateYmd = '2026-02-17';
    final startTime = DateTime(2026, 2, 17, 6, 45).millisecondsSinceEpoch;

    final outcome = await db.insertOrUpdateManualRun(
      dateString: dateYmd,
      startTimeMs: startTime,
      durationS: 1800,
      distanceM: 3218.688,
      avgHr: 142,
      maxHr: 160,
      title: 'Treadmill Run',
      activityType: 'Treadmill Run',
      treadmill: true,
    );

    expect(outcome.inserted, true);

    final run = await (db.select(db.runSessions)
          ..where((r) => r.id.equals(outcome.runSessionId)))
        .getSingle();
    expect(run.title, 'Treadmill Run');
    expect(run.activityType, 'Treadmill Run');
    expect(run.treadmill, true);
  });
}
