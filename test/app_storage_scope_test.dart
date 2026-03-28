import 'package:adaptive_athlete/core/utils/app_providers.dart';
import 'package:adaptive_athlete/core/utils/app_storage_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guest scope uses guest database name', () {
    const scope = AppStorageScope.guest();

    expect(scope.isGuest, isTrue);
    expect(scope.databaseName, 'adaptive_athlete_guest.db');
  });

  test('user scope includes sanitized user id in database name', () {
    const scope = AppStorageScope.user('user:abc-123');

    expect(scope.isUser, isTrue);
    expect(
      scope.databaseName,
      'adaptive_athlete_user_user_abc-123.db',
    );
  });

  test('app storage scope uses user database when signed in', () {
    final container = ProviderContainer(
      overrides: [
        currentAuthUserIdProvider.overrideWith((_) => 'user-a'),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(appStorageScopeProvider),
      const AppStorageScope.user('user-a'),
    );
  });

  test('app storage scope falls back to guest in local-only mode', () {
    final container = ProviderContainer(
      overrides: [
        currentAuthUserIdProvider.overrideWith((_) => 'user-a'),
      ],
    );
    addTearDown(container.dispose);

    container.read(settingsProvider.notifier).setLocalOnly(true);

    expect(
        container.read(appStorageScopeProvider), const AppStorageScope.guest());
  });
}
