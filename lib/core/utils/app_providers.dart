import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/app_db.dart';
import '../../features/ai/ai_analyze_service.dart';

class SupabaseBootstrap {
  const SupabaseBootstrap({required this.initialized, this.error});

  final bool initialized;
  final String? error;
}

enum UnitPreference { lb, kg }

class AppSettings {
  const AppSettings({required this.localOnly, required this.unit});

  final bool localOnly;
  final UnitPreference unit;

  AppSettings copyWith({bool? localOnly, UnitPreference? unit}) {
    return AppSettings(
      localOnly: localOnly ?? this.localOnly,
      unit: unit ?? this.unit,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier()
      : super(const AppSettings(localOnly: false, unit: UnitPreference.lb));

  void setLocalOnly(bool localOnly) =>
      state = state.copyWith(localOnly: localOnly);

  void setUnit(UnitPreference unit) => state = state.copyWith(unit: unit);
}

final appDbProvider = Provider<AppDb>((ref) {
  final db = AppDb();
  ref.onDispose(db.close);
  return db;
});

final settingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
        (ref) => AppSettingsNotifier());

final supabaseBootstrapProvider = Provider<SupabaseBootstrap>(
    (_) => const SupabaseBootstrap(initialized: false));

final aiAnalyzeServiceProvider =
    Provider<AiAnalyzeService>((_) => const AiAnalyzeService());
