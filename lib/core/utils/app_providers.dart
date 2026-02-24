import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/app_db.dart';
import '../../features/ai/ai_analyze_service.dart';
import '../../features/plan/weekly_plan_prompt_service.dart';
import '../../features/training/exercise_substitution_service.dart';

class SupabaseBootstrap {
  const SupabaseBootstrap({required this.initialized, this.error});

  final bool initialized;
  final String? error;
}

enum UnitPreference { lb, kg }

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

final exerciseSubstitutionServiceProvider =
    Provider<ExerciseSubstitutionService>((ref) {
  return ExerciseSubstitutionService(db: ref.read(appDbProvider));
});

final weeklyPlanPromptServiceProvider = Provider<WeeklyPlanPromptService>((ref) {
  return WeeklyPlanPromptService(db: ref.read(appDbProvider));
});
