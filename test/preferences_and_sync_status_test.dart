import 'package:adaptive_athlete/core/utils/app_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'all preferences survive a fresh notifier, including an empty equipment selection',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final first = AppSettingsNotifier(preferences: prefs);
    first.setLocalOnly(true);
    first.setUnit(UnitPreference.kg);
    for (final item in first.state.availableEquipment.toList()) {
      first.toggleEquipment(item);
    }
    first.toggleContraindication('avoid_overhead');
    await first.persistenceComplete;
    first.dispose();
    final reopened = AppSettingsNotifier(preferences: prefs);
    addTearDown(reopened.dispose);
    expect(reopened.state.localOnly, true);
    expect(reopened.state.unit, UnitPreference.kg);
    expect(reopened.state.availableEquipment, isEmpty);
    expect(reopened.state.movementContraindications, {'avoid_overhead'});
  });

  test('malformed saved preferences fall back to usable defaults', () async {
    SharedPreferences.setMockInitialValues(
        {AppSettingsNotifier.storageKey: 'invalid json'});
    final notifier =
        AppSettingsNotifier(preferences: await SharedPreferences.getInstance());
    addTearDown(notifier.dispose);
    expect(notifier.state.unit, UnitPreference.lb);
    expect(notifier.state.availableEquipment, isNotEmpty);
  });

  test('only completed cloud syncs count as success', () {
    for (final message in [
      'Sign in first to sync.',
      'Sync unavailable: sign in first.',
      'Sync failed during upload',
      'Sync needs review: 1 conflict',
      'Sync pending: edits changed'
    ]) {
      expect(AppSyncStatus.fromSyncResult(message).phase, AppSyncPhase.error);
    }
    expect(AppSyncStatus.fromSyncResult('Sync complete: saved').phase,
        AppSyncPhase.success);
  });

  test('last successful sync persists and a later failure cannot replace it',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final notifier =
        AppSyncStatusNotifier(preferences: prefs, account: 'user-a');
    notifier.setResult('Sync complete: saved');
    final successfulAt = notifier.state.lastSuccessAtMs;
    expect(successfulAt, isNotNull);
    notifier.setResult('Sync failed: offline');
    expect(notifier.state.lastSuccessAtMs, successfulAt);
    notifier.dispose();
    final reopened =
        AppSyncStatusNotifier(preferences: prefs, account: 'user-a');
    final other = AppSyncStatusNotifier(preferences: prefs, account: 'user-b');
    addTearDown(reopened.dispose);
    addTearDown(other.dispose);
    expect(reopened.state.lastSuccessAtMs, successfulAt);
    expect(other.state.lastSuccessAtMs, isNull);
  });
}
