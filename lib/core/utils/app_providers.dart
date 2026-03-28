import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app_storage_scope.dart';
import 'device_scoped_store.dart';
import '../../db/app_db.dart';
import '../../features/ai/ai_analyze_service.dart';
import '../../features/plan/weekly_plan_prompt_service.dart';
import '../../features/plan/weekly_planner_service.dart';
import '../../features/training/exercise_substitution_service.dart';
import '../../features/workspace/invite_service.dart';
import '../../features/workspace/workspace_models.dart';
import '../../features/workspace/workspace_service.dart';

class SupabaseBootstrap {
  const SupabaseBootstrap({required this.initialized, this.error});

  final bool initialized;
  final String? error;
}

enum UnitPreference { lb, kg }

enum AppSyncPhase { idle, syncing, success, error }

class AppSyncStatus {
  const AppSyncStatus({
    required this.phase,
    required this.label,
    this.detail,
    this.updatedAtMs,
  });

  const AppSyncStatus.idle()
      : phase = AppSyncPhase.idle,
        label = 'Idle',
        detail = null,
        updatedAtMs = null;

  final AppSyncPhase phase;
  final String label;
  final String? detail;
  final int? updatedAtMs;

  AppSyncStatus copyWith({
    AppSyncPhase? phase,
    String? label,
    String? detail,
    int? updatedAtMs,
  }) {
    return AppSyncStatus(
      phase: phase ?? this.phase,
      label: label ?? this.label,
      detail: detail ?? this.detail,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  factory AppSyncStatus.syncing({required String reason}) => AppSyncStatus(
        phase: AppSyncPhase.syncing,
        label: 'Syncing...',
        detail: 'Automatic sync ($reason)',
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      );

  factory AppSyncStatus.fromSyncResult(String result, {String? reason}) {
    final isError = result.toLowerCase().startsWith('sync failed');
    return AppSyncStatus(
      phase: isError ? AppSyncPhase.error : AppSyncPhase.success,
      label: isError ? 'Sync failed' : 'Synced',
      detail: reason == null ? result : '$result ($reason)',
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.localOnly,
    required this.unit,
    this.availableEquipment = const {
      'barbell',
      'dumbbell',
      'cable',
      'machine',
      'bodyweight',
      'bands',
    },
    this.movementContraindications = const <String>{},
  });

  final bool localOnly;
  final UnitPreference unit;
  final Set<String> availableEquipment;
  final Set<String> movementContraindications;

  AppSettings copyWith({
    bool? localOnly,
    UnitPreference? unit,
    Set<String>? availableEquipment,
    Set<String>? movementContraindications,
  }) {
    return AppSettings(
      localOnly: localOnly ?? this.localOnly,
      unit: unit ?? this.unit,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      movementContraindications:
          movementContraindications ?? this.movementContraindications,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier()
      : super(const AppSettings(localOnly: false, unit: UnitPreference.lb));

  void setLocalOnly(bool localOnly) =>
      state = state.copyWith(localOnly: localOnly);

  void setUnit(UnitPreference unit) => state = state.copyWith(unit: unit);

  void toggleEquipment(String equipment) {
    final next = <String>{...state.availableEquipment};
    if (!next.add(equipment)) {
      next.remove(equipment);
    }
    state = state.copyWith(availableEquipment: next);
  }

  void toggleContraindication(String flag) {
    final next = <String>{...state.movementContraindications};
    if (!next.add(flag)) {
      next.remove(flag);
    }
    state = state.copyWith(movementContraindications: next);
  }
}

class AppSyncStatusNotifier extends StateNotifier<AppSyncStatus> {
  AppSyncStatusNotifier() : super(const AppSyncStatus.idle());

  Timer? _hideTimer;

  void setIdle() => _setStatus(const AppSyncStatus.idle());

  void setSyncing({required String reason}) {
    _setStatus(AppSyncStatus.syncing(reason: reason));
  }

  void setResult(String result, {String? reason}) {
    _setStatus(AppSyncStatus.fromSyncResult(result, reason: reason));
  }

  void setError({
    required String label,
    required String detail,
  }) {
    _setStatus(AppSyncStatus(
      phase: AppSyncPhase.error,
      label: label,
      detail: detail,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  void _setStatus(AppSyncStatus next) {
    _hideTimer?.cancel();
    _hideTimer = null;
    state = next;

    if (next.phase == AppSyncPhase.success) {
      _hideTimer = Timer(const Duration(seconds: 20), () {
        if (!mounted) {
          return;
        }
        state = const AppSyncStatus.idle();
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }
}

class RestCountdownState {
  const RestCountdownState({
    required this.visible,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.dismissibleEpoch,
  });

  const RestCountdownState.idle()
      : visible = false,
        remainingSeconds = 0,
        totalSeconds = 0,
        dismissibleEpoch = 0;

  final bool visible;
  final int remainingSeconds;
  final int totalSeconds;
  final int dismissibleEpoch;

  bool get isRunning => visible && remainingSeconds > 0;

  RestCountdownState copyWith({
    bool? visible,
    int? remainingSeconds,
    int? totalSeconds,
    int? dismissibleEpoch,
  }) {
    return RestCountdownState(
      visible: visible ?? this.visible,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      dismissibleEpoch: dismissibleEpoch ?? this.dismissibleEpoch,
    );
  }
}

class RestCountdownNotifier extends StateNotifier<RestCountdownState> {
  RestCountdownNotifier() : super(const RestCountdownState.idle());

  Timer? _ticker;

  void start(int seconds) {
    final clamped = seconds < 1 ? 1 : seconds;
    state = RestCountdownState(
      visible: true,
      remainingSeconds: clamped,
      totalSeconds: clamped,
      dismissibleEpoch: state.dismissibleEpoch + 1,
    );
    _enableWakeLock();
    _startTicker();
  }

  void dismiss() {
    _ticker?.cancel();
    _ticker = null;
    state = const RestCountdownState.idle();
    _disableWakeLock();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.visible) {
        _ticker?.cancel();
        _ticker = null;
        return;
      }
      final remaining = state.remainingSeconds - 1;
      if (remaining <= 0) {
        _ticker?.cancel();
        _ticker = null;
        state = state.copyWith(remainingSeconds: 0);
        _disableWakeLock();
        return;
      }

      state = state.copyWith(remainingSeconds: remaining);
    });
  }

  void _enableWakeLock() {
    unawaited(_setWakeLock(enabled: true));
  }

  void _disableWakeLock() {
    unawaited(_setWakeLock(enabled: false));
  }

  Future<void> _setWakeLock({required bool enabled}) async {
    try {
      if (enabled) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {
      // Ignore wake lock failures on unsupported platforms.
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _disableWakeLock();
    super.dispose();
  }
}

final settingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
        (ref) => AppSettingsNotifier());

final supabaseBootstrapProvider = Provider<SupabaseBootstrap>(
    (_) => const SupabaseBootstrap(initialized: false));

final authUserIdProvider = StreamProvider<String?>((ref) async* {
  final bootstrap = ref.watch(supabaseBootstrapProvider);
  if (!bootstrap.initialized) {
    yield null;
    return;
  }

  final client = Supabase.instance.client;
  yield client.auth.currentUser?.id;
  yield* client.auth.onAuthStateChange.map(
    (event) => event.session?.user.id ?? client.auth.currentUser?.id,
  );
});

final currentAuthUserIdProvider = Provider<String?>((ref) {
  final bootstrap = ref.watch(supabaseBootstrapProvider);
  if (!bootstrap.initialized) {
    return null;
  }

  final authUserId = ref.watch(authUserIdProvider).valueOrNull;
  return authUserId ?? Supabase.instance.client.auth.currentUser?.id;
});

final deviceScopedStoreProvider = Provider<DeviceScopedStore>((_) {
  return const DeviceScopedStore();
});

final appStorageScopeProvider = Provider<AppStorageScope>((ref) {
  final localOnly =
      ref.watch(settingsProvider.select((settings) => settings.localOnly));
  final currentUserId = ref.watch(currentAuthUserIdProvider);
  if (localOnly || currentUserId == null || currentUserId.trim().isEmpty) {
    return const AppStorageScope.guest();
  }
  return AppStorageScope.user(currentUserId);
});

final appDbProvider = Provider<AppDb>((ref) {
  final scope = ref.watch(appStorageScopeProvider);
  final deviceStore = ref.watch(deviceScopedStoreProvider);
  final db = AppDb(
    scope: scope,
    deviceStore: deviceStore,
  );
  unawaited(db.finalizePendingLegacyMigration());
  ref.onDispose(db.close);
  return db;
});

final syncStatusProvider =
    StateNotifierProvider<AppSyncStatusNotifier, AppSyncStatus>(
  (_) => AppSyncStatusNotifier(),
);

final restCountdownProvider =
    StateNotifierProvider<RestCountdownNotifier, RestCountdownState>(
  (_) => RestCountdownNotifier(),
);

final aiWeeklyPlanResponseProvider = StateProvider<String>((_) => '');

final aiAnalyzeServiceProvider =
    Provider<AiAnalyzeService>((_) => const AiAnalyzeService());

final exerciseSubstitutionServiceProvider =
    Provider<ExerciseSubstitutionService>((ref) {
  return ExerciseSubstitutionService(db: ref.watch(appDbProvider));
});

final weeklyPlanPromptServiceProvider =
    Provider<WeeklyPlanPromptService>((ref) {
  return WeeklyPlanPromptService(db: ref.watch(appDbProvider));
});

final weeklyPlannerServiceProvider = Provider<WeeklyPlannerService>((ref) {
  return WeeklyPlannerService(
    db: ref.watch(appDbProvider),
    promptService: ref.watch(weeklyPlanPromptServiceProvider),
    client: Supabase.instance.client,
  );
});

final workspaceServiceProvider = Provider<WorkspaceService>((ref) {
  return WorkspaceService(
    db: ref.watch(appDbProvider),
    client: Supabase.instance.client,
    deviceStore: ref.watch(deviceScopedStoreProvider),
  );
});

final inviteServiceProvider = Provider<InviteService>((ref) {
  return InviteService(workspaceService: ref.watch(workspaceServiceProvider));
});

final activeWorkspaceContextProvider =
    FutureProvider<ActiveWorkspaceContext?>((ref) async {
  final bootstrap = ref.watch(supabaseBootstrapProvider);
  final localOnly =
      ref.watch(settingsProvider.select((settings) => settings.localOnly));
  final currentUserId = ref.watch(currentAuthUserIdProvider);
  if (!bootstrap.initialized) {
    return null;
  }
  if (localOnly || currentUserId == null || currentUserId.trim().isEmpty) {
    return null;
  }
  return ref.watch(workspaceServiceProvider).bootstrapAndGetContext();
});
