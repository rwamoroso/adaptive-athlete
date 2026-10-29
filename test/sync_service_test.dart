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
  Future<void> Function(String table, String key)? beforeWrite;
  Future<void> Function(String table)? beforeRead;
  bool fail = false;
  Map<String, Map<String, dynamic>> rows(String table) =>
      tables.putIfAbsent(table, () => {});
  http.Response response(http.Request request, Object? value,
          [int status = 200]) =>
      http.Response(jsonEncode(value), status,
          request: request, headers: {'content-type': 'application/json'});

  Future<http.Response> handle(http.Request request) async {
    if (fail) return response(request, {'message': 'Network unavailable'}, 503);
    if (request.url.path.endsWith('/rpc/sync_apply_change')) {
      final params = jsonDecode(request.body) as Map<String, dynamic>;
      final table = params['p_table'] as String,
          key = params['p_key'] as String;
      await beforeWrite?.call(table, key);
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
        deleted[table]?.remove(key);
      }
      return response(request, {'applied': true, 'row': rows(table)[key]});
    }
    final table = request.url.pathSegments.last;
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

  test(
      'first sync preserves both conflicting copies and allows keeping device edits',
      () async {
    cloud.rows('workout_days')['day'] = day();
    await fixture.db.into(fixture.db.workoutDays).insert(
        WorkoutDaysCompanion.insert(
            id: 'day',
            workoutDate: '2026-10-29',
            createdAt: 1,
            notes: const Value('unsynced local edit')));
    expect(await fixture.service.syncNow(), startsWith('Sync needs review:'));
    expect(await fixture.notes, 'unsynced local edit');
    expect(cloud.rows('workout_days')['day']!['notes'], 'cloud original');
    final conflicts = await fixture.service.conflicts();
    expect(conflicts, hasLength(1));
    await fixture.service.resolve(conflicts.single, keepDevice: true);
    expect(SyncService.succeeded(await fixture.service.syncNow()), true);
    expect(cloud.rows('workout_days')['day']!['notes'], 'unsynced local edit');
  });

  test('a cloud edit replaces an unchanged local copy', () async {
    cloud.rows('workout_days')['day'] = day();
    await fixture.service.syncNow();
    cloud.rows('workout_days')['day'] = day('edited on another device');
    expect(SyncService.succeeded(await fixture.service.syncNow()), true);
    expect(await fixture.notes, 'edited on another device');
  });

  test('both devices changing a record produces a durable resolvable conflict',
      () async {
    cloud.rows('workout_days')['day'] = day();
    await fixture.service.syncNow();
    await fixture.edit('local change');
    cloud.rows('workout_days')['day'] = day('cloud change');
    expect(await fixture.service.syncNow(), startsWith('Sync needs review:'));
    expect(await fixture.notes, 'local change');
    // A new service instance sees the persisted conflict after a restart.
    final service = SyncService(
        db: fixture.db,
        client: fixture.client,
        workspaceService: _Workspace(fixture.db, fixture.client));
    final conflict = (await service.conflicts()).single;
    await service.resolve(conflict, keepDevice: false);
    expect(SyncService.succeeded(await service.syncNow()), true);
    expect(await fixture.notes, 'cloud change');
  });

  test('compare-and-set rejects a cloud edit arriving during upload', () async {
    cloud.rows('workout_days')['day'] = day();
    await fixture.service.syncNow();
    await fixture.edit('local change');
    cloud.beforeWrite = (table, key) async {
      cloud.rows(table)[key] = day('concurrent remote change');
      cloud.beforeWrite = null;
    };
    expect(await fixture.service.syncNow(), startsWith('Sync needs review:'));
    expect(await fixture.notes, 'local change');
    expect(cloud.rows('workout_days')['day']!['notes'],
        'concurrent remote change');
  });

  test('deletions sync without resurrecting stale offline copies', () async {
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
    expect(await offline.service.syncNow(), startsWith('Sync needs review:'));
    expect(cloud.rows('workout_days'), isEmpty);
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

  test('edits made during an upload stay pending and upload on the next sync',
      () async {
    cloud.rows('workout_days')['day'] = day();
    await fixture.service.syncNow();
    await fixture.edit('edit before sync');
    cloud.beforeWrite = (table, key) async {
      await fixture.edit('edit during sync');
      cloud.beforeWrite = null;
    };
    expect(await fixture.service.syncNow(), startsWith('Sync pending:'));
    expect(await fixture.notes, 'edit during sync');
    expect(SyncService.succeeded(await fixture.service.syncNow()), true);
    expect(cloud.rows('workout_days')['day']!['notes'], 'edit during sync');
  });

  test(
      'a newer device edit cannot be discarded through an outdated conflict view',
      () async {
    cloud.rows('workout_days')['day'] = day();
    await fixture.service.syncNow();
    await fixture.edit('local change');
    cloud.rows('workout_days')['day'] = day('remote change');
    await fixture.service.syncNow();
    final oldConflict = (await fixture.service.conflicts()).single;
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
        expect(result, startsWith('Sync needs review:'));
        expect((await fixture.service.conflicts()).single.table,
            'actual_strength_sets');
      } else {
        expect(SyncService.succeeded(result), true);
        expect(await fixture.service.conflicts(), isEmpty);
        // A fresh cache restores the same default instead of restoring null.
        await fixture.db.customStatement('delete from sync_state');
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
