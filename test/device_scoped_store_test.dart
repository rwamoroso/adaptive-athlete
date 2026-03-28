import 'package:adaptive_athlete/core/utils/device_scoped_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('pending invite token is stored and cleared device-wide', () async {
    const store = DeviceScopedStore();

    expect(await store.getPendingInviteToken(), isNull);

    await store.setPendingInviteToken('invite-token');
    expect(await store.getPendingInviteToken(), 'invite-token');

    await store.setPendingInviteToken(null);
    expect(await store.getPendingInviteToken(), isNull);
  });

  test('legacy migration state is tracked device-wide', () async {
    const store = DeviceScopedStore();

    expect(await store.getLegacyMigrationPendingTargetDbName(), isNull);
    expect(await store.getLegacyMigratedUserId(), isNull);
    expect(await store.getLegacyMigratedAtMs(), isNull);

    await store.markLegacyMigrationPending(
      targetDbName: 'adaptive_athlete_user_user-a.db',
    );
    expect(
      await store.getLegacyMigrationPendingTargetDbName(),
      'adaptive_athlete_user_user-a.db',
    );

    await store.completeLegacyMigration(
      targetDbName: 'adaptive_athlete_user_user-a.db',
      migratedUserId: 'user-a',
    );

    expect(await store.getLegacyMigrationPendingTargetDbName(), isNull);
    expect(await store.getLegacyMigratedUserId(), 'user-a');
    expect(await store.getLegacyMigratedAtMs(), isNotNull);
  });
}
