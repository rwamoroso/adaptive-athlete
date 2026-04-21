import 'package:adaptive_athlete/core/utils/supabase_session_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const key = 'sb-test-auth-token';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('clears invalid persisted Supabase session strings', () async {
    SharedPreferences.setMockInitialValues({key: 'not-json'});
    final delegate = SharedPreferencesLocalStorage(persistSessionKey: key);
    final storage = ResilientSupabaseLocalStorage(delegate: delegate);

    await storage.initialize();

    expect(await storage.accessToken(), isNull);
    expect(await delegate.hasAccessToken(), isFalse);
  });

  test('keeps JSON persisted Supabase session strings', () async {
    const session = '{"access_token":"token","refresh_token":"refresh"}';
    SharedPreferences.setMockInitialValues({key: session});
    final delegate = SharedPreferencesLocalStorage(persistSessionKey: key);
    final storage = ResilientSupabaseLocalStorage(delegate: delegate);

    await storage.initialize();

    expect(await storage.accessToken(), session);
    expect(await delegate.hasAccessToken(), isTrue);
  });
}
