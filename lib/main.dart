import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'core/utils/app_providers.dart';
import 'core/utils/go_router_refresh_stream.dart';
import 'core/utils/supabase_session_storage.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/join_workspace_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/sync/sync_service.dart';
import 'features/training/home_shell.dart';

String? normalizeAdaptiveAthleteDeepLink(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  final host = uri.host.toLowerCase();
  final path = uri.path.toLowerCase();

  final isJoinDeepLink = (scheme == 'adaptiveathlete') &&
      (host == 'join' || path == '/join' || path == '/join/');
  if (isJoinDeepLink) {
    final token = uri.queryParameters['token'];
    if (token == null || token.trim().isEmpty) {
      return '/join';
    }
    return '/join?token=${Uri.encodeQueryComponent(token)}';
  }

  final isResetPasswordDeepLink = (scheme == 'adaptiveathlete') &&
      (host == 'reset-password' ||
          path == '/reset-password' ||
          path == '/reset-password/');
  if (isResetPasswordDeepLink) {
    return '/reset-password';
  }

  final needsJoinCanonicalization = path == '/join/';
  if (needsJoinCanonicalization) {
    final token = uri.queryParameters['token'];
    if (token == null || token.trim().isEmpty) {
      return '/join';
    }
    return '/join?token=${Uri.encodeQueryComponent(token)}';
  }

  final needsResetCanonicalization = path == '/reset-password/';
  if (needsResetCanonicalization) {
    return '/reset-password';
  }

  return null;
}

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
        authOptions: FlutterAuthClientOptions(
          localStorage: ResilientSupabaseLocalStorage(
            delegate: SharedPreferencesLocalStorage(
              persistSessionKey:
                  'sb-${Uri.parse(SupabaseConfig.url).host.split(".").first}-auth-token',
            ),
          ),
        ),
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
          path: '/',
          builder: (context, state) => const Scaffold(body: SizedBox.shrink())),
      GoRoute(
          path: '/auth',
          builder: (context, state) => const Scaffold(body: AuthScreen())),
      GoRoute(
          path: '/reset-password',
          builder: (context, state) =>
              const Scaffold(body: ResetPasswordScreen())),
      GoRoute(
        path: '/join',
        builder: (context, state) => Scaffold(
          body: JoinWorkspaceScreen(
            inviteToken: state.uri.queryParameters['token'],
          ),
        ),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeShell()),
    ],
    redirect: (context, state) {
      final normalizedDeepLink = normalizeAdaptiveAthleteDeepLink(state.uri);
      if (normalizedDeepLink != null) {
        final currentWithQuery = state.uri.hasQuery
            ? '${state.matchedLocation}?${state.uri.query}'
            : state.matchedLocation;
        if (normalizedDeepLink != currentWithQuery) {
          return normalizedDeepLink;
        }
      }

      if (settings.localOnly) {
        return state.matchedLocation == '/auth' ? '/home' : null;
      }

      final session = bootstrap.initialized
          ? Supabase.instance.client.auth.currentSession
          : null;
      final onRoot = state.matchedLocation == '/';
      final onAuth = state.matchedLocation == '/auth';
      final onResetPassword = state.matchedLocation == '/reset-password';
      final onJoin = state.matchedLocation == '/join';

      if (onRoot) {
        return session == null ? '/auth' : '/home';
      }

      if (session == null && !onAuth && !onResetPassword && !onJoin) {
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

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<Uri>? _deepLinkSubscription;
  Uri? _lastHandledDeepLink;
  bool _autoSyncInFlight = false;
  DateTime? _lastAutoSyncAt;

  void _refreshScopedStorage() {
    ref.invalidate(currentAuthUserIdProvider);
    ref.invalidate(appStorageScopeProvider);
    ref.invalidate(appDbProvider);
    ref.invalidate(activeWorkspaceContextProvider);
  }

  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();

    try {
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Failed to read initial deep link: $e');
    }

    _deepLinkSubscription = appLinks.uriLinkStream.listen(
      _handleIncomingDeepLink,
      onError: (Object error) {
        debugPrint('Deep link stream error: $error');
      },
    );
  }

  void _handleIncomingDeepLink(Uri uri) {
    final normalized = normalizeAdaptiveAthleteDeepLink(uri);
    if (!mounted || normalized == null) {
      return;
    }

    if (_lastHandledDeepLink?.toString() == uri.toString()) {
      return;
    }
    _lastHandledDeepLink = uri;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(routerProvider).go(normalized);
    });
  }

  void _scheduleAutoSync({
    required String reason,
    bool force = false,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_triggerAutoSync(reason: reason, force: force));
    });
  }

  void _scheduleSyncStatusReset() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(syncStatusProvider.notifier).setIdle();
    });
  }

  Future<void> _triggerAutoSync({
    required String reason,
    bool force = false,
  }) async {
    if (!mounted) {
      return;
    }
    final bootstrap = ref.read(supabaseBootstrapProvider);
    final settings = ref.read(settingsProvider);
    if (!bootstrap.initialized || settings.localOnly) {
      return;
    }

    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) {
      return;
    }

    final now = DateTime.now();
    if (!force && _lastAutoSyncAt != null) {
      final elapsed = now.difference(_lastAutoSyncAt!);
      if (elapsed < const Duration(seconds: 15)) {
        return;
      }
    }
    if (_autoSyncInFlight) {
      return;
    }

    _autoSyncInFlight = true;
    ref.read(syncStatusProvider.notifier).setSyncing(reason: reason);
    try {
      final status = await SyncService(
        db: ref.read(appDbProvider),
        client: client,
      ).syncNow();
      if (!mounted) {
        return;
      }
      ref.read(syncStatusProvider.notifier).setResult(status, reason: reason);
      _lastAutoSyncAt = DateTime.now();
      debugPrint('Auto sync ($reason): $status');
    } catch (e) {
      if (mounted) {
        ref.read(syncStatusProvider.notifier).setError(
              label: 'Sync failed',
              detail: 'Auto sync ($reason) failed: $e',
            );
      }
      debugPrint('Auto sync ($reason) failed: $e');
    } finally {
      _autoSyncInFlight = false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb) {
      unawaited(_initDeepLinks());
    }
    final bootstrap = ref.read(supabaseBootstrapProvider);
    if (bootstrap.initialized) {
      _authSubscription =
          Supabase.instance.client.auth.onAuthStateChange.listen((event) {
        if (!mounted) {
          return;
        }
        if (event.event == AuthChangeEvent.passwordRecovery) {
          ref.read(routerProvider).go('/reset-password');
          return;
        }
        if (event.event == AuthChangeEvent.signedIn) {
          _refreshScopedStorage();
          _scheduleAutoSync(reason: 'signed_in', force: true);
          return;
        }
        if (event.event == AuthChangeEvent.signedOut) {
          _refreshScopedStorage();
          _scheduleSyncStatusReset();
        }
      }, onError: (Object error, StackTrace stackTrace) {
        debugPrint('Auth state stream ignored auth error: $error');
      });

      if (Supabase.instance.client.auth.currentSession != null) {
        _scheduleAutoSync(reason: 'app_open', force: true);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleAutoSync(reason: 'resume');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _deepLinkSubscription?.cancel();
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
