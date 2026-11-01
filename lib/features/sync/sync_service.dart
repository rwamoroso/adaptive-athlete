import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_db_operation_gate.dart';
import '../../core/utils/device_scoped_store.dart';
import '../../db/app_db.dart';
import '../workspace/workspace_service.dart';

/// Parent records precede their children. Deletes run in the reverse order.
const syncedTables = <String>[
  'workout_days',
  'plan_cycles',
  'plan_days',
  'exercise_substitutions',
  'actual_strength_sets',
  'prescribed_strength_sets',
  'sleep_nights',
  'run_sessions',
  'run_segments',
  'run_session_details',
  'run_override_audit',
  'rule_triggers',
  'ai_audit',
  'plan_prescribed_strength_sets',
  'plan_prescribed_runs',
  'plan_exercise_alternatives',
  'plan_summary_snapshots',
  'plan_import_audit',
  'athlete_planning_profiles',
  'weekly_plan_build_requests',
  'plan_long_range_weeks',
  'plan_long_range_week_performance',
];

class SyncConflict {
  const SyncConflict(this.table, this.key, this.local, this.cloud);
  final String table;
  final String key;
  final Map<String, dynamic>? local;
  final Map<String, dynamic>? cloud;

  String get label {
    final row = local ?? cloud ?? {};
    final date = row['workout_date'] ??
        row['estimated_date'] ??
        row['week_start'] ??
        row['sleep_date'] ??
        '';
    final title = row['title'] ??
        row['exercise_canonical'] ??
        row['week_label'] ??
        table.replaceAll('_', ' ');
    return '$title $date'.trim();
  }

  String describe(Map<String, dynamic>? row) {
    if (row == null) return 'Deleted';
    final fields = <String, dynamic>{
      for (final entry in row.entries)
        if (!entry.key.endsWith('_id') &&
            entry.key != 'id' &&
            !entry.key.endsWith('_json') &&
            entry.value != null)
          entry.key.replaceAll('_', ' '): entry.value,
    };
    return fields.entries
        .map((e) =>
            '${e.key}: ${e.value.toString().length > 250 ? '${e.value.toString().substring(0, 250)}…' : e.value}')
        .join('\n');
  }
}

class _RemoteChange {
  const _RemoteChange({
    required this.deleted,
    required this.row,
  });

  final bool deleted;
  final Map<String, dynamic>? row;
}

class _RemoteChangeBatch {
  const _RemoteChangeBatch(this.cursor, this.byTable);

  final int cursor;
  final Map<String, Map<String, _RemoteChange>> byTable;
}

/// A durable three-way merge. No network request runs inside a SQLite transaction.
/// Cloud writes use an atomic compare-and-set RPC, never a blind upsert.
class SyncService {
  SyncService(
      {required this.db,
      required this.client,
      WorkspaceService? workspaceService})
      : workspaceService = workspaceService ??
            WorkspaceService(
                db: db, client: client, deviceStore: const DeviceScopedStore());

  final AppDb db;
  final SupabaseClient client;
  final WorkspaceService workspaceService;
  static final _inFlight = Expando<Future<String>>();
  String? _account;
  String _scope = '';
  String _workspace = '';
  String _profile = '';
  String _step = 'loading workspace';
  int _runSessionWriteAttempts = 0;
  int _runSessionWritesApplied = 0;
  int _runSessionWriteRetries = 0;
  final _pendingDeletes = <String, Map<String, Map<String, dynamic>>>{};

  static bool succeeded(String result) => result.startsWith('Sync complete:');

  Future<String> syncNow() {
    final running = _inFlight[db];
    if (running != null) return running;
    final future = AppDbOperationGate.run(db, _sync);
    _inFlight[db] = future;
    unawaited(future.whenComplete(() {
      _inFlight[db] = null;
    }));
    return future;
  }

  Future<void> _initialize({bool refresh = true}) async {
    final context = !refresh
        ? (await workspaceService.getCachedContext() ??
            await workspaceService.requireContext())
        : await workspaceService.requireContext();
    _workspace = context.workspaceId;
    _profile = context.profileId;
    _scope = '$_workspace/$_profile';
    await db.customStatement("""
      CREATE TABLE IF NOT EXISTS sync_state (
        scope TEXT NOT NULL, table_name TEXT NOT NULL, row_key TEXT NOT NULL,
        baseline_json TEXT, conflict INTEGER NOT NULL DEFAULT 0,
        local_json TEXT, cloud_json TEXT, restore INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY(scope, table_name, row_key)
      )
    """);
    await db.customStatement("""
      CREATE TABLE IF NOT EXISTS sync_cursor (
        scope TEXT NOT NULL PRIMARY KEY,
        change_version INTEGER NOT NULL
      )
    """);
    if (refresh &&
        context.needsCloudClaim &&
        context.role.toLowerCase() == 'owner') {
      await workspaceService.claimLegacyRowsForActiveProfile(context: context);
    }
  }

  Future<String> _sync() async {
    _pendingDeletes.clear();
    _runSessionWriteAttempts = 0;
    _runSessionWritesApplied = 0;
    _runSessionWriteRetries = 0;
    _account = client.auth.currentUser?.id;
    if (_account == null) {
      return 'Sync unavailable: sign in first.';
    }
    try {
      await _initialize();
      // Conflicts written by an earlier app version (or a concurrent cloud
      // write that beat our compare-and-set) follow the device-wins policy.
      await _resolveDeviceConflicts();
      await db.enforceWorkoutDayDateUniqueness();
      final savedCursor = await _loadCursor();
      if (savedCursor == null) {
        _step = 'starting incremental sync';
        final snapshotCursor = await _remoteCursor();
        for (final name in syncedTables) {
          _step = 'initial sync of ${name.replaceAll('_', ' ')}';
          await _syncTableFull(name);
        }
        await _flushPendingDeletes();
        await _saveCursor(snapshotCursor);
        await _syncIncremental(snapshotCursor);
      } else {
        await _syncIncremental(savedCursor);
      }

      // Local writers such as HealthKit can finish while cloud rows are being
      // uploaded. Drain those edits here instead of asking the user to start
      // the same sync again. Bound retries so a continuously edited device
      // cannot keep one sync request alive indefinitely.
      var pendingTables = await _pendingChangeTables();
      for (var attempt = 0;
          attempt < 3 && pendingTables.isNotEmpty;
          attempt++) {
        await _resolveDeviceConflicts();
        if ((await _conflicts()).isNotEmpty) break;
        final cursor = await _loadCursor();
        if (cursor == null) break;
        _step = 'saving edits made during sync';
        await _syncIncremental(cursor);
        pendingTables = await _pendingChangeTables();
      }

      // A compare-and-set can discover a newer cloud row while applying a
      // device edit. Resolve ordinary conflicts against the refreshed row.
      await _resolveDeviceConflicts();
      final conflicts = await _conflicts();
      if (conflicts.isNotEmpty) {
        return 'Sync needs review: ${conflicts.length} conflicting record(s). '
            'Your device edits are preserved. Open Settings to review.';
      }
      pendingTables = await _pendingChangeTables();
      if (pendingTables.isNotEmpty) {
        final runSessionsPending = pendingTables.firstWhere(
          (table) => table.startsWith('run_sessions '),
          orElse: () => '',
        );
        final runDiagnostics = runSessionsPending.isEmpty
            ? ''
            : ' Run-session cloud writes: $_runSessionWriteAttempts attempted, '
                '$_runSessionWritesApplied accepted, $_runSessionWriteRetries retried.';
        return 'Sync pending: device changes could not be fully saved to the cloud in ${pendingTables.join(', ')} after several save passes. '
            'Keep the app open and try Sync Now again.$runDiagnostics';
      }
      return 'Sync complete: device and cloud changes saved.';
    } catch (e) {
      return 'Sync failed during $_step: $e. Device changes remain saved locally.';
    }
  }

  void _checkAccount() {
    if (client.auth.currentUser?.id != _account) {
      throw StateError('Sign-in changed during sync. Retry after signing in.');
    }
  }

  TableInfo getTable(String name) =>
      db.allTables.firstWhere((table) => table.actualTableName == name);

  String _keyColumn(String name) =>
      name == 'run_session_details' ? 'run_session_id' : 'id';

  Map<String, dynamic>? _normalize(String name, Map<String, dynamic>? row) {
    if (row == null) return null;
    final table = getTable(name);
    final normalized = <String, dynamic>{
      for (final col in table.$columns)
        col.$name: col.type == DriftSqlType.bool && row[col.$name] is num
            ? row[col.$name] != 0
            : row[col.$name],
      'workspace_id': _workspace,
      'athlete_profile_id': _profile,
    };
    // Older cloud rows predate this field. Its existing app default is the
    // performed exercise; an actual substitution still remains distinct.
    if (name == 'actual_strength_sets') {
      normalized['prescribed_exercise_canonical'] ??=
          normalized['exercise_canonical'];
    }
    return normalized;
  }

  String _json(Object? value) {
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return '{${keys.map((k) => '${jsonEncode(k)}:${_json(value[k])}').join(',')}}';
    }
    if (value is List) return '[${value.map(_json).join(',')}]';
    // SQLite's integer representation and PostgreSQL's real representation agree.
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return jsonEncode(value);
  }

  bool _sameField(String name, String field, Object? a, Object? b) {
    if (a is num && b is num && a.isFinite && b.isFinite) {
      final isRealColumn = getTable(name).$columns.any(
            (column) =>
                column.$name == field && column.type == DriftSqlType.double,
          );
      if (isRealColumn) {
        final left = a.toDouble();
        final right = b.toDouble();
        // PostgreSQL can serialize a float with fewer digits than SQLite's
        // double holds. Ignore only the resulting representation noise.
        return left == right ||
            (left - right).abs() <= math.max(left.abs(), right.abs()) * 1e-14;
      }
    }
    return _json(a) == _json(b);
  }

  bool _same(String name, Map<String, dynamic>? a, Map<String, dynamic>? b) {
    final left = _normalize(name, a);
    final right = _normalize(name, b);
    if (left == null || right == null) return left == null && right == null;
    for (final field in {...left.keys, ...right.keys}) {
      if (!_sameField(name, field, left[field], right[field])) return false;
    }
    return true;
  }

  Future<Map<String, Map<String, dynamic>>> _localRows(String name) async {
    final scoped = name == 'athlete_planning_profiles' ||
        name == 'weekly_plan_build_requests';
    final rows = await db.customSelect(
      'SELECT * FROM "$name"${scoped ? ' WHERE workspace_id = ? AND athlete_profile_id = ?' : ''}',
      variables: scoped
          ? [Variable.withString(_workspace), Variable.withString(_profile)]
          : [],
      readsFrom: {getTable(name)},
    ).get();
    return {
      for (final row in rows)
        row.data[_keyColumn(name)].toString(): _normalize(name, row.data)!
    };
  }

  Future<List<Map<String, dynamic>>> _remoteRows(String name) async {
    final rows = <Map<String, dynamic>>[];
    for (var start = 0;; start += 500) {
      _checkAccount();
      final page = await client
          .from(name)
          .select()
          .eq('workspace_id', _workspace)
          .eq('athlete_profile_id', _profile)
          .order(_keyColumn(name))
          .range(start, start + 499);
      rows.addAll(page.map((row) => Map<String, dynamic>.from(row)));
      if (page.length < 500) return rows;
    }
  }

  Future<int?> _loadCursor() async {
    final row = await db.customSelect(
      'SELECT change_version FROM sync_cursor WHERE scope=?',
      variables: [Variable.withString(_scope)],
    ).getSingleOrNull();
    return (row?.data['change_version'] as num?)?.toInt();
  }

  Future<void> _saveCursor(int cursor) async {
    await db.customStatement(
      'INSERT INTO sync_cursor(scope,change_version) VALUES(?,?) '
      'ON CONFLICT(scope) DO UPDATE SET change_version=excluded.change_version',
      [_scope, cursor],
    );
  }

  Future<int> _remoteCursor() async {
    _checkAccount();
    final value = await client.rpc('sync_change_cursor', params: {
      'p_workspace': _workspace,
      'p_profile': _profile,
    });
    _checkAccount();
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<_RemoteChangeBatch> _pullRemoteChanges(int after) async {
    var cursor = after;
    final byTable = <String, Map<String, _RemoteChange>>{};
    // A bounded loop keeps one sync responsive even after a very stale device.
    // Any remaining pages are picked up safely by the next sync from this cursor.
    for (var pageNumber = 0; pageNumber < 100; pageNumber++) {
      _checkAccount();
      final payload = await client.rpc('sync_changes_since', params: {
        'p_workspace': _workspace,
        'p_profile': _profile,
        'p_after': cursor,
        'p_limit': 500,
      });
      _checkAccount();
      final rows = payload is List ? payload : const <dynamic>[];
      for (final value in rows) {
        final data = Map<String, dynamic>.from(value as Map);
        final version = (data['change_version'] as num).toInt();
        final table = data['table_name'].toString();
        final key = data['row_key'].toString();
        if (!syncedTables.contains(table)) {
          throw StateError(
              'Cloud returned unsupported sync collection $table.');
        }
        final deleted =
            data['operation'] == 'delete' || data['row_data'] == null;
        final row =
            deleted ? null : Map<String, dynamic>.from(data['row_data'] as Map);
        (byTable[table] ??= {})[key] = _RemoteChange(
          deleted: deleted,
          row: row,
        );
        if (version > cursor) cursor = version;
      }
      if (rows.length < 500) break;
    }
    return _RemoteChangeBatch(cursor, byTable);
  }

  Future<void> _syncIncremental(int cursor) async {
    _step = 'checking cloud changes';
    final batch = await _pullRemoteChanges(cursor);
    for (final name in syncedTables) {
      _step = 'syncing ${name.replaceAll('_', ' ')}';
      await _syncTableIncremental(
        name,
        batch.byTable[name] ?? const <String, _RemoteChange>{},
      );
    }
    await _flushPendingDeletes();
    await _saveCursor(batch.cursor);
  }

  Future<void> _flushPendingDeletes() async {
    for (final name in syncedTables.reversed) {
      final deletes = Map<String, Map<String, dynamic>>.from(
        _pendingDeletes[name] ?? const <String, Map<String, dynamic>>{},
      );
      for (final entry in deletes.entries) {
        // A user may have restored a record while the sync was running.
        final current = await _localRows(name);
        if (!current.containsKey(entry.key)) {
          await _writeCloud(name, entry.key, null, entry.value);
        }
      }
      _pendingDeletes.remove(name);
    }
  }

  Future<void> _saveState(
      String name, String key, Map<String, dynamic>? baseline,
      {bool conflict = false,
      Map<String, dynamic>? local,
      Map<String, dynamic>? cloud,
      bool restore = false}) async {
    await db.customStatement(
      'INSERT INTO sync_state(scope,table_name,row_key,baseline_json,conflict,local_json,cloud_json,restore) '
      'VALUES(?,?,?,?,?,?,?,?) ON CONFLICT(scope,table_name,row_key) DO UPDATE SET '
      'baseline_json=excluded.baseline_json, conflict=excluded.conflict, '
      'local_json=excluded.local_json, cloud_json=excluded.cloud_json, restore=excluded.restore',
      [
        _scope,
        name,
        key,
        _json(_normalize(name, baseline)),
        conflict ? 1 : 0,
        _json(_normalize(name, local)),
        _json(_normalize(name, cloud)),
        restore ? 1 : 0
      ],
    );
  }

  Future<void> _applyLocal(
      String name, String key, Map<String, dynamic>? row) async {
    final table = getTable(name);
    if (row == null) {
      await db.customStatement(
          'DELETE FROM "$name" WHERE "${_keyColumn(name)}" = ?', [key]);
    } else {
      final cols = table.$columns.map((c) => c.$name).toList();
      final normalized = _normalize(name, row)!;
      if (name == 'workout_days') {
        final dateCollision = await db.customSelect(
          'SELECT id, notes FROM workout_days WHERE workout_date=? AND id<>? LIMIT 1',
          variables: [
            Variable.withString(normalized['workout_date'].toString()),
            Variable.withString(normalized['id'].toString()),
          ],
          readsFrom: {db.workoutDays},
        ).getSingleOrNull();
        if (dateCollision != null) {
          // A legacy/out-of-band local day may have the same natural date but
          // a different UUID. Repoint its references before applying the cloud
          // identity so SQLite's unique-date index cannot abort initial sync.
          await _alignWorkoutDays([normalized]);
          normalized['notes'] ??= dateCollision.data['notes'];
        }
      }
      final values = cols
          .map((c) => normalized[c] is bool
              ? (normalized[c] == true ? 1 : 0)
              : normalized[c])
          .toList();
      await db.customStatement(
        'INSERT INTO "$name" (${cols.map((c) => '"$c"').join(',')}) '
        'VALUES (${cols.map((_) => '?').join(',')}) ON CONFLICT("${_keyColumn(name)}") '
        'DO UPDATE SET ${cols.where((c) => c != _keyColumn(name)).map((c) => '"$c"=excluded."$c"').join(',')}',
        values,
      );
    }
    db.markTablesUpdated({table});
  }

  Future<void> _alignWorkoutDays(List<Map<String, dynamic>> cloud) async {
    final local = await _localRows('workout_days');
    final byDate = {for (final row in cloud) row['workout_date']: row};
    for (final row in local.values) {
      final remote = byDate[row['workout_date']];
      if (remote == null || remote['id'] == row['id']) continue;
      for (final table in db.allTables) {
        if (table.$columns.any((c) => c.$name == 'workout_day_id')) {
          await db.customStatement(
              'UPDATE "${table.actualTableName}" SET workout_day_id=? WHERE workout_day_id=?',
              [remote['id'], row['id']]);
          db.markTablesUpdated({table});
        }
      }
      await db.customStatement(
          'UPDATE workout_days SET id=?, created_at=? WHERE id=?',
          [remote['id'], remote['created_at'], row['id']]);
      await db.customStatement(
          'DELETE FROM sync_state WHERE scope=? AND table_name=? AND row_key=?',
          [_scope, 'workout_days', row['id']]);
      db.markTablesUpdated({db.workoutDays});
    }
  }

  Future<void> _syncTableFull(String name) async {
    final cloudRows = await _remoteRows(name);
    final cloud = {
      for (final row in cloudRows) row[_keyColumn(name)].toString(): row
    };
    final deletedKeys = <String>{};
    for (var start = 0;; start += 500) {
      final deleted = await client
          .from('sync_tombstones')
          .select('row_key')
          .eq('workspace_id', _workspace)
          .eq('athlete_profile_id', _profile)
          .eq('table_name', name)
          .order('row_key')
          .range(start, start + 499);
      deletedKeys.addAll(deleted.map((r) => r['row_key'].toString()));
      if (deleted.length < 500) break;
    }
    _checkAccount();
    final uploads = <String, Map<String, dynamic>?>{};
    final restores = <String>{};
    await db.transaction(() async {
      if (name == 'workout_days') await _alignWorkoutDays(cloudRows);
      final local = await _localRows(name);
      final stateRows = await db.customSelect(
        'SELECT * FROM sync_state WHERE scope=? AND table_name=?',
        variables: [Variable.withString(_scope), Variable.withString(name)],
      ).get();
      final states = {
        for (final r in stateRows) r.data['row_key'].toString(): r.data
      };
      for (final key in {...local.keys, ...cloud.keys, ...states.keys}) {
        final device = local[key];
        final remote = cloud[key];
        final state = states[key];
        final hasBaseline = state != null;
        final baseline = state == null
            ? null
            : jsonDecode(state['baseline_json'] as String)
                as Map<String, dynamic>?;
        if (_same(name, device, remote)) {
          await _saveState(name, key, remote);
          continue;
        }
        final localChanged =
            !hasBaseline ? device != null : !_same(name, device, baseline);
        final remoteChanged = !hasBaseline
            ? remote != null || deletedKeys.contains(key)
            : !_same(name, remote, baseline);
        if (localChanged && remoteChanged) {
          // Device data is authoritative for this installation. Stage the
          // replacement and let the cloud compare-and-set protect concurrent
          // writes instead of asking the user to choose a side.
          uploads[key] = device;
          if (state?['restore'] == 1) restores.add(key);
        } else if (localChanged) {
          if (device == null) {
            (_pendingDeletes[name] ??= {})[key] = remote!;
          } else {
            uploads[key] = device;
            if (state?['restore'] == 1) restores.add(key);
          }
        } else {
          await _applyLocal(name, key, remote);
          await _saveState(name, key, remote);
        }
      }
    });
    for (final entry in uploads.entries) {
      await _writeCloud(name, entry.key, entry.value, cloud[entry.key],
          restore: restores.contains(entry.key));
    }
  }

  Future<void> _syncTableIncremental(
    String name,
    Map<String, _RemoteChange> changes,
  ) async {
    final changedCloud = <String, Map<String, dynamic>>{
      for (final entry in changes.entries)
        if (!entry.value.deleted && entry.value.row != null)
          entry.key: entry.value.row!,
    };
    final deletedKeys = {
      for (final entry in changes.entries)
        if (entry.value.deleted) entry.key,
    };
    final uploads = <String, Map<String, dynamic>?>{};
    final expectedByKey = <String, Map<String, dynamic>?>{};
    final restores = <String>{};

    await db.transaction(() async {
      if (name == 'workout_days' && changedCloud.isNotEmpty) {
        await _alignWorkoutDays(changedCloud.values.toList());
      }
      final local = await _localRows(name);
      final stateRows = await db.customSelect(
        'SELECT * FROM sync_state WHERE scope=? AND table_name=?',
        variables: [Variable.withString(_scope), Variable.withString(name)],
      ).get();
      final states = {
        for (final row in stateRows) row.data['row_key'].toString(): row.data,
      };

      for (final key in {...local.keys, ...states.keys, ...changes.keys}) {
        final device = local[key];
        final state = states[key];
        final hasBaseline = state != null;
        final baseline = state == null
            ? null
            : jsonDecode(state['baseline_json'] as String)
                as Map<String, dynamic>?;
        final hasRemoteChange = changes.containsKey(key);
        final remote = hasRemoteChange
            ? (deletedKeys.contains(key) ? null : changedCloud[key])
            : baseline;

        if (_same(name, device, remote)) {
          await _saveState(name, key, remote);
          continue;
        }
        final localChanged =
            !hasBaseline ? device != null : !_same(name, device, baseline);
        final remoteChanged = hasRemoteChange &&
            (!hasBaseline
                ? remote != null || deletedKeys.contains(key)
                : !_same(name, remote, baseline));

        if (localChanged && remoteChanged) {
          uploads[key] = device;
          expectedByKey[key] = remote;
          if (state?['restore'] == 1) restores.add(key);
        } else if (localChanged) {
          if (device == null) {
            if (remote != null) {
              (_pendingDeletes[name] ??= {})[key] = remote;
            }
          } else {
            uploads[key] = device;
            expectedByKey[key] = remote;
            if (state?['restore'] == 1) restores.add(key);
          }
        } else if (remoteChanged) {
          await _applyLocal(name, key, remote);
          await _saveState(name, key, remote);
        }
      }
    });

    for (final entry in uploads.entries) {
      await _writeCloud(
        name,
        entry.key,
        entry.value,
        expectedByKey[entry.key],
        restore: restores.contains(entry.key),
      );
    }
  }

  Future<void> _writeCloud(String name, String key, Map<String, dynamic>? next,
      Map<String, dynamic>? expected,
      {bool restore = false}) async {
    _checkAccount();
    if (name == 'run_sessions') _runSessionWriteAttempts++;
    final response = Map<String, dynamic>.from(
        await client.rpc('sync_apply_change', params: {
      'p_table': name,
      'p_key': key,
      'p_workspace': _workspace,
      'p_profile': _profile,
      'p_expected': expected,
      'p_next': next == null ? null : {...?expected, ...next},
      'p_restore': restore,
    }) as Map);
    _checkAccount();
    if (name == 'run_sessions') {
      if (response['applied'] == true) {
        _runSessionWritesApplied++;
      } else {
        _runSessionWriteRetries++;
      }
    }
    final remote = response['row'] == null
        ? null
        : Map<String, dynamic>.from(response['row'] as Map);
    await db.transaction(() async {
      if (response['applied'] == true) {
        await _saveState(name, key, remote);
      } else {
        final device = (await _localRows(name))[key];
        await _saveState(name, key, expected,
            conflict: true, local: device, cloud: remote);
      }
    });
  }

  Future<List<String>> _pendingChangeTables() async {
    final pending = <String>[];
    for (final name in syncedTables) {
      final local = await _localRows(name);
      final rows = await db.customSelect(
          'SELECT row_key,baseline_json FROM sync_state WHERE scope=? AND table_name=?',
          variables: [
            Variable.withString(_scope),
            Variable.withString(name)
          ]).get();
      final baselines = {
        for (final row in rows)
          row.data['row_key'].toString():
              jsonDecode(row.data['baseline_json'] as String)
                  as Map<String, dynamic>?
      };
      var pendingRows = 0;
      final differingFields = <String>{};
      for (final key in {...local.keys, ...baselines.keys}) {
        final device = local[key];
        final baseline = baselines[key];
        if (_same(name, device, baseline)) continue;
        pendingRows++;
        if (device == null || baseline == null) {
          differingFields.add('record presence');
          continue;
        }
        for (final field in {...device.keys, ...baseline.keys}) {
          if (!_sameField(name, field, device[field], baseline[field])) {
            differingFields.add(field);
          }
        }
      }
      if (pendingRows > 0) {
        final fields = differingFields.toList()..sort();
        final fieldSummary = fields.isEmpty
            ? ''
            : '; fields: ${fields.take(8).join(', ')}${fields.length > 8 ? ', …' : ''}';
        pending.add('$name ($pendingRows rows$fieldSummary)');
      }
    }
    return pending;
  }

  Future<List<SyncConflict>> conflicts() async {
    await _initialize(refresh: false);
    return _conflicts();
  }

  Future<void> _resolveDeviceConflicts() async {
    // A failed compare-and-set refreshes the stored cloud snapshot. Retry a
    // few times against that newer snapshot; persistent concurrent writes
    // remain visible as conflicts rather than being overwritten blindly.
    for (var attempt = 0; attempt < 5; attempt++) {
      final pending = await _conflicts();
      if (pending.isEmpty) return;
      for (final conflict in pending) {
        await _resolve(conflict, keepDevice: true);
      }
    }
  }

  Future<List<SyncConflict>> _conflicts() async {
    final rows = await db.customSelect(
        'SELECT * FROM sync_state WHERE scope=? AND conflict=1',
        variables: [Variable.withString(_scope)]).get();
    return rows
        .map((r) => SyncConflict(
            r.data['table_name'] as String,
            r.data['row_key'] as String,
            jsonDecode(r.data['local_json'] as String) as Map<String, dynamic>?,
            jsonDecode(r.data['cloud_json'] as String)
                as Map<String, dynamic>?))
        .toList();
  }

  Future<void> resolve(SyncConflict conflict,
      {required bool keepDevice}) async {
    return AppDbOperationGate.run(
      db,
      () => _resolve(conflict, keepDevice: keepDevice),
    );
  }

  Future<void> _resolve(SyncConflict conflict,
      {required bool keepDevice}) async {
    await _initialize();
    _account = client.auth.currentUser?.id;
    if (_account == null) {
      throw StateError('Sign in again before resolving sync changes.');
    }
    Map<String, dynamic>? deviceChoice;
    await db.transaction(() async {
      final current = (await _localRows(conflict.table))[conflict.key];
      if (!keepDevice && !_same(conflict.table, current, conflict.local)) {
        throw StateError(
            'This device record changed. Sync again to refresh the comparison.');
      }
      if (!keepDevice) {
        await _applyLocal(conflict.table, conflict.key, conflict.cloud);
      } else {
        // Keep the latest local row if the user continued editing after the
        // conflict snapshot was created.
        deviceChoice = current;
      }
      // Keeping the device copy is an explicit decision against this cloud snapshot.
      // A later cloud change will produce a new conflict instead of being overwritten.
      await _saveState(conflict.table, conflict.key, conflict.cloud,
          restore: keepDevice && conflict.cloud == null);
    });
    if (keepDevice) {
      // Apply the decision immediately with compare-and-set. If the cloud copy
      // changed since this conflict was displayed, _writeCloud records a fresh
      // conflict instead of making the user retry a stale choice blindly.
      await _writeCloud(
        conflict.table,
        conflict.key,
        deviceChoice,
        conflict.cloud,
        restore: conflict.cloud == null && deviceChoice != null,
      );
    }
  }
}
