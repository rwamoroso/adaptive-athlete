import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'core/utils/app_providers.dart';
import 'core/utils/go_router_refresh_stream.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/training/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  var initialized = false;
  String? error;

  try {
    final usingPlaceholderConfig =
        SupabaseConfig.url.contains('<SUPABASE_URL>') ||
            SupabaseConfig.anonKey.contains('<SUPABASE_ANON_KEY>');
    if (usingPlaceholderConfig) {
      error =
          'Supabase config is using placeholders. Set real values in lib/config/supabase_config.dart.';
    } else {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      initialized = true;
    }
  } catch (e) {
    error = e.toString();
  }

  runApp(
    ProviderScope(
      overrides: [
        supabaseBootstrapProvider.overrideWithValue(
            SupabaseBootstrap(initialized: initialized, error: error)),
      ],
      child: const MyApp(),
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final settings = ref.watch(settingsProvider);
  final bootstrap = ref.watch(supabaseBootstrapProvider);

  final refresh = bootstrap.initialized
      ? GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange
          .map((event) => event.event))
      : GoRouterRefreshStream(Stream<void>.empty());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    routes: [
      GoRoute(
          path: '/auth',
          builder: (context, state) => const Scaffold(body: AuthScreen())),
      GoRoute(
          path: '/reset-password',
          builder: (context, state) =>
              const Scaffold(body: ResetPasswordScreen())),
      GoRoute(path: '/home', builder: (context, state) => const HomeShell()),
    ],
    redirect: (context, state) {
      if (settings.localOnly) {
        return state.matchedLocation == '/auth' ? '/home' : null;
      }

      final session = bootstrap.initialized
          ? Supabase.instance.client.auth.currentSession
          : null;
      final onAuth = state.matchedLocation == '/auth';
      final onResetPassword = state.matchedLocation == '/reset-password';

      if (session == null && !onAuth && !onResetPassword) {
        return '/auth';
      }
      if (session != null && onAuth) {
        return '/home';
      }
      return null;
    },
  );
});

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    final bootstrap = ref.read(supabaseBootstrapProvider);
    if (bootstrap.initialized) {
      _authSubscription =
          Supabase.instance.client.auth.onAuthStateChange.listen((event) {
        if (!mounted) {
          return;
        }
        if (event.event == AuthChangeEvent.passwordRecovery) {
          ref.read(routerProvider).go('/reset-password');
        }
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Adaptive Athlete',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E4F)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
