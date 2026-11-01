import 'dart:convert';

import 'package:adaptive_athlete/core/utils/device_scoped_store.dart';
import 'package:adaptive_athlete/db/app_db.dart';
import 'package:adaptive_athlete/features/sync/sync_service.dart';
import 'package:adaptive_athlete/features/workspace/workspace_models.dart';
import 'package:adaptive_athlete/features/workspace/workspace_service.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
// HTTP is provided by the Supabase SDK; this fake never contacts a real service.
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const workspaceId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const profileId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

class _Workspace extends WorkspaceService {
  _Workspace(AppDb db, SupabaseClient client)
      : super(db: db, client: client, deviceStore: const DeviceScopedStore());
  @override
  Future<ActiveWorkspaceContext> requireContext() async =>
      const ActiveWorkspaceContext(
        userId: 'review-user',
        workspaceId: workspaceId,
        profileId: profileId,
        role: 'owner',
        needsCloudClaim: false,
        workspaces: [],
        memberships: [],
        profiles: [],
        assignments: [],
        invites: [],
      );
}

class FakeCloud {
  final tables = <String, Map<String, Map<String, dynamic>>>{};
  final deleted = <String, Set<String>>{};
  final _seen = <String, String>{};
  final _journal = <Map<String, dynamic>>[];
  var _changeVersion = 0;
  Future<void> Function(String table, String key)? beforeWrite;
  Future<void> Function(String table)? beforeRead;
  final readCounts = <String, int>{};
  bool fail = false;
  bool roundHeartRateOnWrite = false;
  Map<String, Map<String, dynamic>> rows(String table) =>
      tables.putIfAbsent(table, () => {});
  http.Response response(http.Request request, Object? value,
          [int status = 200]) =>
      http.Response(jsonEncode(value), status,
          request: request, headers: {'content-type': 'application/json'});

  void _recordCurrent(String table, String key) {
    final row = rows(table)[key];
    final isDeleted = deleted[table]?.contains(key) == true;
    final marker = row != null
        ? 'upsert:${_canonical(row)}'
        : isDeleted
            ? 'delete'
            : 'missing';
    _seen['$table/$key'] = marker;
    if (row == null && !isDeleted) return;
    _changeVersion++;
    _journal.add({
      'change_version': _changeVersion,
      'table_name': table,
      'row_key': key,
      'operation': row == null ? 'delete' : 'upsert',
      'row_data': row == null ? null : Map<String, dynamic>.from(row),
    });
  }

  void _captureExternalChanges() {
    final tableNames = <String>{...tables.keys, ...deleted.keys};
    for (final seenKey in _seen.keys) {
      tableNames.add(seenKey.split('/').first);
    }
    for (final table in tableNames) {
      final keys = <String>{
        ...rows(table).keys,
        ...?deleted[table],
        for (final seenKey in _seen.keys)
          if (seenKey.startsWith('$table/'))
            seenKey.substring(table.length + 1),
      };
      for (final key in keys) {
        final row = rows(table)[key];
        final isDeleted = deleted[table]?.contains(key) == true;
        final marker = row != null
            ? 'upsert:${_canonical(row)}'
            : isDeleted
                ? 'delete'
                : 'missing';
        final seenKey = '$table/$key';
        if (_seen[seenKey] == marker) continue;
        _recordCurrent(table, key);
      }
    }
  }

  Future<http.Response> handle(http.Request request) async {
    if (fail) return response(request, {'message': 'Network unavailable'}, 503);
    if (request.url.path.endsWith('/rpc/sync_change_cursor')) {
      _captureExternalChanges();
      return response(request, _changeVersion);
    }
    if (request.url.path.endsWith('/rpc/sync_changes_since')) {
      _captureExternalChanges();
      final params = jsonDecode(request.body) as Map<String, dynamic>;
      final after = (params['p_after'] as num?)?.toInt() ?? 0;
      final limit = (params['p_limit'] as num?)?.toInt() ?? 500;
      return response(
        request,
        _journal
            .where((entry) => (entry['change_version'] as int) > after)
            .take(limit)
            .toList(growable: false),
      );
    }
    if (request.url.path.endsWith('/rpc/sync_apply_change')) {
      final params = jsonDecode(request.body) as Map<String, dynamic>;
      final table = params['p_table'] as String,
          key = params['p_key'] as String;
      await beforeWrite?.call(table, key);
      _captureExternalChanges();
      final current = rows(table)[key];
      final expected = params['p_expected'];
      final matches = _canonical(current) == _canonical(expected);
      final tombstone = deleted[table]?.contains(key) == true;
      if (!matches ||
          (current == null &&
              params['p_next'] != null &&
              tombstone &&
              params['p_restore'] != true)) {
        return response(request, {'applied': false, 'row': current});
      }
      if (params['p_next'] == null) {
        rows(table).remove(key);
        (deleted[table] ??= {}).add(key);
      } else {
        rows(table)[key] = Map<String, dynamic>.from(params['p_next'] as Map);
        final avgHr = rows(table)[key]!['avg_hr'];
        if (roundHeartRateOnWrite && table == 'run_sessions' && avgHr is num) {
          rows(table)[key]!['avg_hr'] =
              double.parse(avgHr.toDouble().toStringAsPrecision(15));
        }
        deleted[table]?.remove(key);
      }
      _recordCurrent(table, key);
      return response(request, {'applied': true, 'row': rows(table)[key]});
    }
    final table = request.url.pathSegments.last;
    readCounts[table] = (readCounts[table] ?? 0) + 1;
    await beforeRead?.call(table);
    if (table == 'sync_tombstones') {
      final collection =
          request.url.queryParameters['table_name']!.substring(3);
      return response(request, [
        for (final key in deleted[collection] ?? <String>{}) {'row_key': key}
      ]);
    }
    return response(request, rows(table).values.toList());
  }
}

String _canonical(dynamic value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return '{${keys.map((key) => '$key:${_canonical(value[key])}').join(',')}}';
  }
  if (value is num) return value.toDouble().toString();
  return jsonEncode(value);
}

class Fixture {
  Fixture(this.db, this.client)
      : service = SyncService(
            db: db, client: client, workspaceService: _Workspace(db, client));
  final AppDb db;
  final SupabaseClient client;
  final SyncService service;
  static Future<Fixture> create(FakeCloud cloud) async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    final client = SupabaseClient('https://sync-test.invalid', 'fake-key',
        httpClient: MockClient(cloud.handle),
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    final payload = base64Url
        .encode(utf8.encode(jsonEncode({
          'sub': 'review-user',
          'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600
        })))
        .replaceAll('=', '');
    await client.auth.setInitialSession(jsonEncode({
      'access_token': 'eyJhbGciOiJIUzI1NiJ9.$payload.signature',
      'refresh_token': 'fake-refresh',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': {
        'id': 'review-user',
        'app_metadata': {},
        'user_metadata': {},
        'aud': 'authenticated',
        'created_at': '2026-10-29T00:00:00Z'
      }
    }));
    return Fixture(db, client);
  }

  Future<void> dispose() async {
    await db.close();
    await client.dispose();
  }

  Future<void> edit(String notes) =>
      (db.update(db.workoutDays)..where((d) => d.id.equals('day')))
          .write(WorkoutDaysCompanion(notes: Value(notes)));
  Future<String?> get notes async =>
      (await db.select(db.workoutDays).getSingle()).notes;
}

Map<String, dynamic> day([String notes = 'cloud original']) => {
      'id': 'day',
      'workout_date': '2026-10-29',
      'created_at': 1,
      'notes': notes,
      'workspace_id': workspaceId,
      'athlete_profile_id': profileId
    };

void main() {
  late FakeCloud cloud;
  late Fixture fixture;
  setUp(() async {
    cloud = FakeCloud();
    fixture = await Fixture.create(cloud);
  });
  tearDown(() => fixture.dispose());

  test('new entries upload; unsynced edits survive the next cloud pull',
      () async {
    await fixture.db.into(fixture.db.workoutDays).insert(
        WorkoutDaysCompanion.insert(
            id: 'day',
            workoutDate: '2026-10-29',
            createdAt: 1,
            notes: const Value('first')));
    expect(SyncService.succeeded(await fixture.service.syncNow()), true);
    await fixture.edit('new local edit');
    expect(SyncService.succeeded(await fixture.service.syncNow()), true);
    expect(await fixture.notes, 'new local edit');
    expect(cloud.rows('workout_days')['day']!['notes'], 'new local edit');
  });

  test('heart rate JSON precision does not cause repeated uploads', () async {
    cloud.roundHeartRateOnWrite = true;
    var runWrites = 0;
    cloud.beforeWrite = (table, _) async {
      if (table == 'run_sessions') runWrites++;
    };
    const heartRate = 138.12345678901234;
    await fixture.db.into(fixture.db.runSessions).insert(
          RunSessionsCompanion.insert(
            id: 'health-run',
            source: 'apple_health',
            avgHr: const Value(heartRate),
          ),
        );

    expect(SyncService.succeeded(await fixture.service.syncNow()), isTrue);
    expect(runWrites, 1);
    expect((await fixture.db.select(fixture.db.runSessions).getSingle()).avgHr,
        heartRate);
    expect(SyncService.succeeded(await fixture.service.syncNow()), isTrue);
    expect(runWrites, 1);

    await (fixture.db.update(fixture.db.runSessions)
          ..where((run) => run.id.equals('health-run')))
        .write(const RunSessionsCompanion(avgHr: Value(139.0)));
    expect(SyncService.succeeded(await fixture.service.syncNow()), isTrue);
    expect(runWrites, 2);
    expect(cloud.rows('run_sessions')['health-run']!['avg_hr'], 139.0);

    cloud.rows('run_sessions')['health-run']!['avg_hr'] = 140.0;
    expect(SyncService.succeeded(await fixture.service.syncNow()), isTrue);
    expect((await fixture.db.select(fixture.db.runSessions).getSingle()).avgHr,
        140.0);
  });

  test('first sync keeps device edits when both copies differ', () async {
    cloud.rows('workout_days')['day'] = day();
    await fixture.db.into(fixture.db.workoutDays).insert(
        WorkoutDaysCompanion.insert(
            id: 'day',
            workoutDate: '2026-10-29',
            createdAt: 1,
            notes: const Value('unsynced local edit')));
    expect(SyncService.succeeded(await fixture.service.syncNow()), isTrue);
    expect(await fixture.notes, 'unsynced local edit');
    expect(cloud.rows('workout_days')['day']!['notes'], 'unsynced local edit');
    expect(await fixture.service.conflicts(), isEmpty);
    expect(SyncService.succeeded(await fixture.service.syncNow()), true);
    expect(cloud.rows('workout_days')['day']!['notes'], 'unsynced local edit');
  });

  test('first sync keeps device edits across nine differing records', () async {
    for (var index = 0; index < 9; index++) {
      final id = 'day-$index';
      final date = '2026-10-${(10 + index).toString().padLeft(2, '0')}';
      cloud.rows('workout_days')[id] = {
        ...day('cloud-$index'),
        'id': id,
        'workout_date': date,
      };
      await fixture.db.into(fixture.db.workoutDays).insert(
            WorkoutDaysCompanion.insert(
              id: id,
              workoutDate: date,
              createdAt: index + 10,
              notes: Value('device-$index'),
            ),
          );
    }

    expect(SyncService.succeeded(await fixture.service.syncNow()), isTrue);
    expect(await fixture.service.conflicts(), isEmpty);
    expect(
      cloud.rows('workout_days').values.map((row) => row['notes']).toSet(),
      containsAll(List.generate(9, (index) => 'device-$index')),
    );
  });

  test('a cloud edit replaces an unchanged local copy', () async {
    cloud.rows('workout_days')['day'] = day();
    await fixture.service.syncNow();
    cloud.rows('workout_days')['day'] = day('edited on another device');
    expect(SyncService.succeeded(await fixture.service.syncNow()), true);
    expect(await fixture.notes, 'edited on another device');
  });

  test('initial sync aligns workout day IDs by date before applying cloud rows',
      () async {
    cloud.rows('workout_days')['cloud-day'] = {
      ...day(),
      'id': 'cloud-day',
      'notes': null,
    };
    await fixture.db.into(fixture.db.workoutDays).insert(
          WorkoutDaysCompanion.insert(
            id: 'device-day',
            workoutDate: '2026-10-29',
            createdAt: 2,
          ),
        );

    expect(SyncService.succeeded(await fixture.service.syncNow()), isTrue);
    final days = await fixture.db.select(fixture.db.workoutDays).get();
    expect(days, hasLength(1));
    expect(days.single.id, 'cloud-day');
  });

  test('later syncs use the change cursor instead of full table downloads',
      () async {
    cloud.rows('workout_days')['day'] = day();
    expect(SyncService.succeeded(await fixture.service.syncNow()), true);
    cloud.readCounts.clear();

    expect(SyncService.succeeded(await fixture.service.syncNow()), true);

    expect(cloud.readCounts['workout_days'] ?? 0, 0);
    expect(cloud.readCounts['sync_tombstones'] ?? 0, 0);
  });

  test('both devices changing a record keeps the local change', () async {
    cloud.rows('workout_days')['day'] = day();
    await fixture.service.syncNow();
    await fixture.edit('local change');
    cloud.rows('workout_days')['day'] = day('cloud change');
    expect(SyncService.succeeded(await fixture.service.syncNow()), isTrue);
    expect(await fixture.notes, 'local change');
    expect(cloud.rows('workout_days')['day']!['notes'], 'local change');
    final service = SyncService(
        db: fixture.db,
        client: fixture.client,
        workspaceService: _Workspace(fixture.db, fixture.client));
    expect(await service.conflicts(), isEmpty);
    expect(SyncService.succeeded(await service.syncNow()), true);
    expect(await fixture.notes, 'local change');
  });

  test('compare-and-set rejects a cloud edit arriving during upload', () async {
    cloud.rows('workout_days')['day'] = day();
    await fixture.service.syncNow();
    await fixture.edit('local change');
    cloud.beforeWrite = (table, key) async {
      cloud.rows(table)[key] = day('concurrent remote change');
      cloud.beforeWrite = null;
    };
    expect(SyncService.succeeded(await fixture.service.syncNow()), isTrue);
    expect(await fixture.notes, 'local change');
    expect(cloud.rows('workout_days')['day']!['notes'], 'local change');
    expect(await fixture.service.conflicts(), isEmpty);
  });

  test('deletions sync and a stale device copy is restored by device wins',
      () async {
    cloud.rows('workout_days')['day'] = day();
    await fixture.service.syncNow();
    await fixture.db.delete(fixture.db.workoutDays).go();
    expect(SyncService.succeeded(await fixture.service.syncNow()), true);
    expect(cloud.rows('workout_days'), isEmpty);
    expect(SyncService.succeeded(await fixture.service.syncNow()), true);
    final offline = await Fixture.create(cloud);
    addTearDown(offline.dispose);
    await offline.db.into(offline.db.workoutDays).insert(
        WorkoutDaysCompanion.insert(
            id: 'day',
            workoutDate: '2026-10-29',
            createdAt: 1,
            notes: const Value('stale offline copy')));
    expect(SyncService.succeeded(await offline.service.syncNow()), isTrue);
    expect(cloud.rows('workout_days')['day']!['notes'], 'stale offline copy');
    expect(await offline.service.conflicts(), isEmpty);
  });

  test('ten-week plan and performance restore on a fresh device', () async {
    await fixture.db.into(fixture.db.planLongRangeWeeks).insert(
        PlanLongRangeWeeksCompanion.insert(
            id: 'week',
            weekLabel: 'Week 1',
            weekStart: '2026-10-26',
            weekEnd: '2026-11-01',
            source: 'test',
            createdAt: 1,
            updatedAt: 1));
    await fixture.db.into(fixture.db.planLongRangeWeekPerformance).insert(
        PlanLongRangeWeekPerformanceCompanion.insert(
            id: 'performance',
            weekStart: '2026-10-26',
            weekEnd: '2026-11-01',
            evaluationSource: 'test',
            plannedDayCount: 7,
            completedPlanDays: 5,
            plannedRunDays: 3,
            actualRunDays: 2,
            plannedRunSessions: 3,
            actualRunSessions: 2,
            plannedStrengthExercises: 5,
            actualStrengthExercises: 4,
            plannedStrengthSets: 20,
            actualStrengthSets: 16,
            capturedAt: 2));
    expect(SyncService.succeeded(await fixture.service.syncNow()), true);
    final fresh = await Fixture.create(cloud);
    addTearDown(fresh.dispose);
    expect(SyncService.succeeded(await fresh.service.syncNow()), true);
    expect(
        (await fresh.db.select(fresh.db.planLongRangeWeeks).getSingle())
            .weekLabel,
        'Week 1');
    expect(
        (await fresh.db
                .select(fresh.db.planLongRangeWeekPerformance)
                .getSingle())
            .actualStrengthSets,
        16);
  });

  test('edits made during an upload are saved before sync completes', () async {
    cloud.rows('workout_days')['day'] = day();
    await fixture.service.syncNow();
    await fixture.edit('edit before sync');
    cloud.beforeWrite = (table, key) async {
      await fixture.edit('edit during sync');
      cloud.beforeWrite = null;
    };
    expect(SyncService.succeeded(await fixture.service.syncNow()), isTrue);
    expect(await fixture.notes, 'edit during sync');
    expect(cloud.rows('workout_days')['day']!['notes'], 'edit during sync');
  });

  test(
      'a newer device edit cannot be discarded through an outdated conflict view',
      () async {
    cloud.rows('workout_days')['day'] = day();
    await fixture.service.syncNow();
    await fixture.edit('local change');
    final oldConflict = SyncConflict(
        'workout_days', 'day', day('local change'), day('remote change'));
    await fixture.edit('newer local change');
    await expectLater(fixture.service.resolve(oldConflict, keepDevice: false),
        throwsStateError);
    expect(await fixture.notes, 'newer local change');
  });

  test(
      'changing sign-in during sync stops local writes for the previous account',
      () async {
    cloud.rows('workout_days')['day'] = day();
    cloud.beforeRead = (table) async {
      if (table != 'workout_days') return;
      cloud.beforeRead = null;
      await fixture.client.auth.signOut();
    };
    expect(await fixture.service.syncNow(), startsWith('Sync failed'));
    expect(await fixture.db.select(fixture.db.workoutDays).get(), isEmpty);
    expect(cloud.rows('workout_days')['day']!['notes'], 'cloud original');
  });

  for (final substituted in [false, true]) {
    test(
        'legacy prescription defaults compare correctly, substitution=$substituted',
        () async {
      await fixture.db.into(fixture.db.actualStrengthSets).insert(
          ActualStrengthSetsCompanion.insert(
              id: 'strength',
              workoutDayId: 'day',
              exerciseCanonical: 'bench_press',
              setIndex: 1,
              unit: 'lb',
              source: 'manual',
              createdAt: 1,
              prescribedExerciseCanonical:
                  Value(substituted ? 'push_up' : 'bench_press')));
      final local = (await fixture.db
              .customSelect('select * from actual_strength_sets')
              .getSingle())
          .data;
      cloud.rows('actual_strength_sets')['strength'] = {
        ...local,
        'prescribed_exercise_canonical': null,
        'workspace_id': workspaceId,
        'athlete_profile_id': profileId
      };
      final result = await fixture.service.syncNow();
      if (substituted) {
        expect(SyncService.succeeded(result), true);
        expect(await fixture.service.conflicts(), isEmpty);
        expect(
            cloud.rows('actual_strength_sets')['strength']![
                'prescribed_exercise_canonical'],
            'push_up');
      } else {
        expect(SyncService.succeeded(result), true);
        expect(await fixture.service.conflicts(), isEmpty);
        // A fresh cache restores the same default instead of restoring null.
        await fixture.db.customStatement('delete from sync_state');
        await fixture.db.customStatement('delete from sync_cursor');
        await fixture.db.delete(fixture.db.actualStrengthSets).go();
        expect(SyncService.succeeded(await fixture.service.syncNow()), true);
        expect(
            (await fixture.db.select(fixture.db.actualStrengthSets).getSingle())
                .prescribedExerciseCanonical,
            'bench_press');
      }
    });
  }

  test('failed network calls keep edits saved locally', () async {
    cloud.rows('workout_days')['day'] = day();
    await fixture.service.syncNow();
    await fixture.edit('saved offline');
    cloud.fail = true;
    expect(await fixture.service.syncNow(), startsWith('Sync failed'));
    expect(await fixture.notes, 'saved offline');
  });
}
