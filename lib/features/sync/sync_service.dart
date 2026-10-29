import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _pendingDeletes = <String, Map<String, Map<String, dynamic>>>{};

  static bool succeeded(String result) => result.startsWith('Sync complete:');

  Future<String> syncNow() {
    final running = _inFlight[db];
    if (running != null) return running;
    final future = _sync();
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
    if (refresh &&
        context.needsCloudClaim &&
        context.role.toLowerCase() == 'owner') {
      await workspaceService.claimLegacyRowsForActiveProfile(context: context);
    }
  }

  Future<String> _sync() async {
    _pendingDeletes.clear();
    _account = client.auth.currentUser?.id;
    if (_account == null) {
      return 'Sync unavailable: sign in first.';
    }
    try {
      await _initialize();
      await db.enforceWorkoutDayDateUniqueness();
      for (final name in syncedTables) {
        _step = 'syncing ${name.replaceAll('_', ' ')}';
        await _syncTable(name);
      }
      for (final name in syncedTables.reversed) {
        for (final entry in (_pendingDeletes[name] ?? {}).entries) {
          // A user may have restored a record while the sync was running.
          final current = await _localRows(name);
          if (!current.containsKey(entry.key)) {
            await _writeCloud(name, entry.key, null, entry.value);
          }
        }
      }
      final conflicts = await _conflicts();
      if (conflicts.isNotEmpty) {
        return 'Sync needs review: ${conflicts.length} conflicting record(s). '
            'Your device edits are preserved. Open Settings to review.';
      }
      if (await _hasPendingChanges()) {
        return 'Sync pending: more device edits were made during sync. Tap Sync Now to save them to cloud.';
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

  bool _same(String name, Map<String, dynamic>? a, Map<String, dynamic>? b) =>
      _json(_normalize(name, a)) == _json(_normalize(name, b));

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

  Future<void> _syncTable(String name) async {
    final cloudRows = await _remoteRows(name);
    final cloud = {
      for (final row in cloudRows) row[_keyColumn(name)].toString(): row
    };
    final deleted = await client
        .from('sync_tombstones')
        .select('row_key')
        .eq('workspace_id', _workspace)
        .eq('athlete_profile_id', _profile)
        .eq('table_name', name);
    final deletedKeys = deleted.map((r) => r['row_key'].toString()).toSet();
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
          await _saveState(name, key, baseline,
              conflict: true, local: device, cloud: remote);
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

  Future<void> _writeCloud(String name, String key, Map<String, dynamic>? next,
      Map<String, dynamic>? expected,
      {bool restore = false}) async {
    _checkAccount();
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

  Future<bool> _hasPendingChanges() async {
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
      for (final key in {...local.keys, ...baselines.keys}) {
        if (!_same(name, local[key], baselines[key])) return true;
      }
    }
    return false;
  }

  Future<List<SyncConflict>> conflicts() async {
    await _initialize(refresh: false);
    return _conflicts();
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
    await _initialize();
    await db.transaction(() async {
      final current = (await _localRows(conflict.table))[conflict.key];
      if (!_same(conflict.table, current, conflict.local)) {
        throw StateError(
            'This device record changed. Sync again to refresh the comparison.');
      }
      if (!keepDevice) {
        await _applyLocal(conflict.table, conflict.key, conflict.cloud);
      }
      // Keeping the device copy is an explicit decision against this cloud snapshot.
      // A later cloud change will produce a new conflict instead of being overwritten.
      await _saveState(conflict.table, conflict.key, conflict.cloud,
          restore: keepDevice && conflict.cloud == null);
    });
  }
}
