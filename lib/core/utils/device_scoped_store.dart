import 'package:shared_preferences/shared_preferences.dart';

class DeviceScopedStore {
  const DeviceScopedStore();

  static const _pendingInviteTokenKey =
      'adaptive_athlete.device.pending_invite_token';
  static const _legacyPendingTargetDbNameKey =
      'adaptive_athlete.device.legacy.pending_target_db_name';
  static const _legacyMigratedUserIdKey =
      'adaptive_athlete.device.legacy.migrated_user_id';
  static const _legacyMigratedAtKey =
      'adaptive_athlete.device.legacy.migrated_at_ms';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String?> getPendingInviteToken() async {
    return (await _prefs).getString(_pendingInviteTokenKey);
  }

  Future<void> setPendingInviteToken(String? token) async {
    final prefs = await _prefs;
    final normalized = token?.trim();
    if (normalized == null || normalized.isEmpty) {
      await prefs.remove(_pendingInviteTokenKey);
      return;
    }
    await prefs.setString(_pendingInviteTokenKey, normalized);
  }

  Future<String?> getLegacyMigrationPendingTargetDbName() async {
    return (await _prefs).getString(_legacyPendingTargetDbNameKey);
  }

  Future<void> markLegacyMigrationPending({
    required String targetDbName,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_legacyPendingTargetDbNameKey, targetDbName);
  }

  Future<void> completeLegacyMigration({
    required String targetDbName,
    String? migratedUserId,
  }) async {
    final prefs = await _prefs;
    final pendingTarget = prefs.getString(_legacyPendingTargetDbNameKey);
    if (pendingTarget == targetDbName) {
      await prefs.remove(_legacyPendingTargetDbNameKey);
    }
    if (migratedUserId != null && migratedUserId.isNotEmpty) {
      await prefs.setString(_legacyMigratedUserIdKey, migratedUserId);
    }
    await prefs.setInt(
      _legacyMigratedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<String?> getLegacyMigratedUserId() async {
    return (await _prefs).getString(_legacyMigratedUserIdKey);
  }

  Future<int?> getLegacyMigratedAtMs() async {
    return (await _prefs).getInt(_legacyMigratedAtKey);
  }
}
