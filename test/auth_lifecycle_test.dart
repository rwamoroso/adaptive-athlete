import 'dart:async';

import 'package:adaptive_athlete/core/utils/app_providers.dart';
import 'package:adaptive_athlete/features/auth/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('a delayed sign-in failure is safe after leaving the auth screen',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final pending = Completer<http.Response>();
    await tester.runAsync(() => Supabase.initialize(
        url: 'https://test.invalid',
        anonKey: 'fake',
        debug: false,
        httpClient: MockClient((request) async => pending.future),
        authOptions: const FlutterAuthClientOptions(
            autoRefreshToken: false,
            detectSessionInUri: false,
            localStorage: EmptyLocalStorage())));
    addTearDown(() => tester.runAsync(Supabase.instance.dispose));
    await tester.pumpWidget(ProviderScope(overrides: [
      supabaseBootstrapProvider
          .overrideWithValue(const SupabaseBootstrap(initialized: true))
    ], child: const MaterialApp(home: Scaffold(body: AuthScreen()))));
    await tester.enterText(
        find.widgetWithText(TextField, 'Email'), 'test@example.invalid');
    await tester.enterText(
        find.widgetWithText(TextField, 'Password'), 'test-only-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(http.Response('{"msg":"Test request rejected"}', 400,
        headers: {'content-type': 'application/json'}));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
