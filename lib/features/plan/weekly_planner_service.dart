import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/date_utils.dart';
import '../../db/app_db.dart';
import 'biometrics_profile.dart';
import 'weekly_plan_prompt_service.dart';

enum SplitType {
  runOnly,
  fullBody3d,
  upperLower4d,
  ppl56d,
  phul,
  arnold,
  broSplit,
  hybridRunLift,
  customHybrid,
}

extension SplitTypeX on SplitType {
  String get code => switch (this) {
        SplitType.runOnly => 'run_only',
        SplitType.fullBody3d => 'full_body_3d',
        SplitType.upperLower4d => 'upper_lower_4d',
        SplitType.ppl56d => 'ppl_5_6d',
        SplitType.phul => 'phul',
        SplitType.arnold => 'arnold',
        SplitType.broSplit => 'bro_split',
        SplitType.hybridRunLift => 'hybrid_run_lift',
        SplitType.customHybrid => 'custom_hybrid',
      };

  String get label => switch (this) {
        SplitType.runOnly => 'Run Only',
        SplitType.fullBody3d => 'Full Body (3d)',
        SplitType.upperLower4d => 'Upper/Lower (4d)',
        SplitType.ppl56d => 'Push/Pull/Legs (5-6d)',
        SplitType.phul => 'PHUL',
        SplitType.arnold => 'Arnold',
        SplitType.broSplit => 'Bro Split',
        SplitType.hybridRunLift => 'Hybrid Run+Lift',
        SplitType.customHybrid => 'Custom Hybrid',
      };

  static SplitType fromCode(String raw) {
    for (final type in SplitType.values) {
      if (type.code == raw) {
        return type;
      }
    }
    return SplitType.ppl56d;
  }
}

enum WeeklyPlanModifier {
  followLongTerm,
  lightWeek,
  vacationTravel,
}

extension WeeklyPlanModifierX on WeeklyPlanModifier {
  String get code => switch (this) {
        WeeklyPlanModifier.followLongTerm => 'follow_long_term',
        WeeklyPlanModifier.lightWeek => 'light_week',
        WeeklyPlanModifier.vacationTravel => 'vacation_travel',
      };

  String get label => switch (this) {
        WeeklyPlanModifier.followLongTerm => 'Follow long-term plan',
        WeeklyPlanModifier.lightWeek => 'Light week',
        WeeklyPlanModifier.vacationTravel => 'Vacation/Travel week',
      };

  static WeeklyPlanModifier fromCode(String raw) {
    for (final modifier in WeeklyPlanModifier.values) {
      if (modifier.code == raw) {
        return modifier;
      }
    }
    return WeeklyPlanModifier.followLongTerm;
  }
}

enum PlannerGenerationMode {
  oneTapAi,
  manualAssist,
}

extension PlannerGenerationModeX on PlannerGenerationMode {
  String get code => switch (this) {
        PlannerGenerationMode.oneTapAi => 'one_tap_ai',
        PlannerGenerationMode.manualAssist => 'manual_assist',
      };

  String get label => switch (this) {
        PlannerGenerationMode.oneTapAi => 'One-tap AI',
        PlannerGenerationMode.manualAssist => 'Manual AI Assist',
      };

  static PlannerGenerationMode fromCode(String raw) {
    for (final mode in PlannerGenerationMode.values) {
      if (mode.code == raw) {
        return mode;
      }
    }
    return PlannerGenerationMode.manualAssist;
  }
}

class AthletePlanningProfile {
  const AthletePlanningProfile({
    required this.workspaceId,
    required this.athleteProfileId,
    required this.primaryGoal,
    required this.goalTarget,
    required this.experienceLevel,
    required this.preferredSplit,
    required this.daysPerWeek,
    required this.availableEquipment,
    required this.contraindications,
    required this.scheduleConstraints,
    this.biometrics = const <String, dynamic>{},
  });

  final String workspaceId;
  final String athleteProfileId;
  final String primaryGoal;
  final Map<String, dynamic> goalTarget;
  final String experienceLevel;
  final SplitType preferredSplit;
  final int daysPerWeek;
  final Set<String> availableEquipment;
  final Set<String> contraindications;
  final Map<String, dynamic> scheduleConstraints;
  final Map<String, dynamic> biometrics;

  Map<String, dynamic> toJson() => {
        'workspace_id': workspaceId,
        'athlete_profile_id': athleteProfileId,
        'primary_goal': primaryGoal,
        'goal_target': goalTarget,
        'experience_level': experienceLevel,
        'preferred_split': preferredSplit.code,
        'days_per_week': daysPerWeek,
        'available_equipment': availableEquipment.toList()..sort(),
        'contraindications': contraindications.toList()..sort(),
        'schedule_constraints': scheduleConstraints,
        'biometrics': biometrics,
      };

  AthletePlanningProfile copyWith({
    String? primaryGoal,
    Map<String, dynamic>? goalTarget,
    String? experienceLevel,
    SplitType? preferredSplit,
    int? daysPerWeek,
    Set<String>? availableEquipment,
    Set<String>? contraindications,
    Map<String, dynamic>? scheduleConstraints,
    Map<String, dynamic>? biometrics,
  }) {
    return AthletePlanningProfile(
      workspaceId: workspaceId,
      athleteProfileId: athleteProfileId,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      goalTarget: goalTarget ?? this.goalTarget,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      preferredSplit: preferredSplit ?? this.preferredSplit,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      contraindications: contraindications ?? this.contraindications,
      scheduleConstraints: scheduleConstraints ?? this.scheduleConstraints,
      biometrics: biometrics ?? this.biometrics,
    );
  }
}

class PlannerPromptContext {
  const PlannerPromptContext({
    required this.profile,
    required this.weekStart,
    required this.weekEnd,
    required this.splitType,
    required this.modifier,
    required this.propagateLongTermChanges,
    required this.longRangeContextRows,
    required this.recentMetricsSummary,
    required this.additionalInstructions,
    this.derivedMetricsV1,
    this.performanceBaselineV1,
    this.trainingLoadV1,
    this.progressSignalsV1,
    this.adaptationHistoryV1,
  });

  final AthletePlanningProfile profile;
  final String weekStart;
  final String weekEnd;
  final SplitType splitType;
  final WeeklyPlanModifier modifier;
  final bool propagateLongTermChanges;
  final List<Map<String, dynamic>> longRangeContextRows;
  final Map<String, dynamic> recentMetricsSummary;
  final String? additionalInstructions;
  final Map<String, dynamic>? derivedMetricsV1;
  final Map<String, dynamic>? performanceBaselineV1;
  final Map<String, dynamic>? trainingLoadV1;
  final Map<String, dynamic>? progressSignalsV1;
  final Map<String, dynamic>? adaptationHistoryV1;

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'week_start': weekStart,
        'week_end': weekEnd,
        'split_type': splitType.code,
        'modifier': modifier.code,
        'propagate_long_term_changes': propagateLongTermChanges,
        'long_range_context_rows': longRangeContextRows,
        'recent_metrics_summary': recentMetricsSummary,
        if (derivedMetricsV1 != null && derivedMetricsV1!.isNotEmpty)
          'derived_metrics_v1': derivedMetricsV1,
        if (performanceBaselineV1 != null && performanceBaselineV1!.isNotEmpty)
          'performance_baseline_v1': performanceBaselineV1,
        if (trainingLoadV1 != null && trainingLoadV1!.isNotEmpty)
          'training_load_v1': trainingLoadV1,
        if (progressSignalsV1 != null && progressSignalsV1!.isNotEmpty)
          'progress_signals_v1': progressSignalsV1,
        if (adaptationHistoryV1 != null && adaptationHistoryV1!.isNotEmpty)
          'adaptation_history_v1': adaptationHistoryV1,
        'additional_instructions': additionalInstructions,
      };
}

class WeeklyPlanBuildRequest {
  const WeeklyPlanBuildRequest({
    required this.workspaceId,
    required this.athleteProfileId,
    required this.splitStartDate,
    required this.splitType,
    required this.modifier,
    required this.mode,
    required this.propagateLongTermChanges,
    required this.additionalInstructions,
    required this.overridePromptText,
  });

  final String workspaceId;
  final String athleteProfileId;
  final DateTime splitStartDate;
  final SplitType splitType;
  final WeeklyPlanModifier modifier;
  final PlannerGenerationMode mode;
  final bool propagateLongTermChanges;
  final String? additionalInstructions;
  final String? overridePromptText;

  String get weekStart => toYmd(splitStartDate);
  String get weekEnd => toYmd(splitStartDate.add(const Duration(days: 6)));
}

class WeeklyPlanBuildResult {
  const WeeklyPlanBuildResult({
    required this.promptText,
    required this.generatedText,
    required this.importResult,
    required this.mode,
    required this.serverSideRequested,
  });

  final String promptText;
  final String? generatedText;
  final AiWeeklyPlanTextImportResult? importResult;
  final PlannerGenerationMode mode;
  final bool serverSideRequested;
}

class _PromptDerivedSections {
  const _PromptDerivedSections({
    this.derivedMetricsV1,
    this.performanceBaselineV1,
    this.trainingLoadV1,
    this.progressSignalsV1,
    this.adaptationHistoryV1,
  });

  final Map<String, dynamic>? derivedMetricsV1;
  final Map<String, dynamic>? performanceBaselineV1;
  final Map<String, dynamic>? trainingLoadV1;
  final Map<String, dynamic>? progressSignalsV1;
  final Map<String, dynamic>? adaptationHistoryV1;

  bool get hasAny =>
      (derivedMetricsV1?.isNotEmpty ?? false) ||
      (performanceBaselineV1?.isNotEmpty ?? false) ||
      (trainingLoadV1?.isNotEmpty ?? false) ||
      (progressSignalsV1?.isNotEmpty ?? false) ||
      (adaptationHistoryV1?.isNotEmpty ?? false);

  Map<String, dynamic> toJson() => {
        if (derivedMetricsV1 != null && derivedMetricsV1!.isNotEmpty)
          'derived_metrics_v1': derivedMetricsV1,
        if (performanceBaselineV1 != null && performanceBaselineV1!.isNotEmpty)
          'performance_baseline_v1': performanceBaselineV1,
        if (trainingLoadV1 != null && trainingLoadV1!.isNotEmpty)
          'training_load_v1': trainingLoadV1,
        if (progressSignalsV1 != null && progressSignalsV1!.isNotEmpty)
          'progress_signals_v1': progressSignalsV1,
        if (adaptationHistoryV1 != null && adaptationHistoryV1!.isNotEmpty)
          'adaptation_history_v1': adaptationHistoryV1,
      };
}

class _WindowStats {
  const _WindowStats({
    required this.latest7RunDistanceM,
    required this.latest7RunDurationS,
    required this.latest7RunSessionCount,
    required this.latest7StrengthSetCount,
    required this.latest7ActiveDaysCount,
    required this.prior14RunDistanceM,
    required this.prior14RunDurationS,
    required this.prior14RunSessionCount,
    required this.prior14StrengthSetCount,
    required this.prior14ActiveDaysCount,
    required this.latest7SleepAvgMin,
    required this.prior14SleepAvgMin,
    required this.latest7RunPaceSecPerKm,
    required this.prior14RunPaceSecPerKm,
    required this.latest7LongRunDistanceM,
    required this.prior14LongRunDistanceWeeklyAvgM,
  });

  final double latest7RunDistanceM;
  final int latest7RunDurationS;
  final int latest7RunSessionCount;
  final int latest7StrengthSetCount;
  final int latest7ActiveDaysCount;

  final double prior14RunDistanceM;
  final int prior14RunDurationS;
  final int prior14RunSessionCount;
  final int prior14StrengthSetCount;
  final int prior14ActiveDaysCount;

  final double? latest7SleepAvgMin;
  final double? prior14SleepAvgMin;
  final double? latest7RunPaceSecPerKm;
  final double? prior14RunPaceSecPerKm;
  final double latest7LongRunDistanceM;
  final double prior14LongRunDistanceWeeklyAvgM;
}

class _RunQuality {
  const _RunQuality({
    required this.validRows,
    required this.corruptedRunsDetected,
  });

  final List<Map<String, dynamic>> validRows;
  final int corruptedRunsDetected;
}

class WeeklyPlannerService {
  WeeklyPlannerService({
    required this.db,
    required this.promptService,
    required this.client,
  });

  final AppDb db;
  final WeeklyPlanPromptService promptService;
  final SupabaseClient client;

  bool get isServerSideAiEnabled {
    final session = client.auth.currentSession;
    if (session == null) {
      return false;
    }
    return session.accessToken.isNotEmpty;
  }

  Future<AthletePlanningProfile?> getPlanningProfile({
    required String workspaceId,
    required String athleteProfileId,
  }) async {
    final row = await db.getAthletePlanningProfile(
      workspaceId: workspaceId,
      athleteProfileId: athleteProfileId,
    );
    if (row == null) {
      return null;
    }
    return AthletePlanningProfile(
      workspaceId: workspaceId,
      athleteProfileId: athleteProfileId,
      primaryGoal: row.primaryGoal,
      goalTarget: _decodeJsonMap(row.goalTargetJson),
      experienceLevel: row.experienceLevel,
      preferredSplit: SplitTypeX.fromCode(row.preferredSplit),
      daysPerWeek: row.daysPerWeek,
      availableEquipment: _decodeStringSet(row.availableEquipmentJson).toSet(),
      contraindications: _decodeStringSet(row.contraindicationsJson).toSet(),
      scheduleConstraints: _decodeJsonMap(row.scheduleConstraintsJson),
      biometrics: _decodeJsonMap(row.biometricsJson),
    );
  }

  Future<void> upsertPlanningProfile(AthletePlanningProfile profile) {
    return db.upsertAthletePlanningProfile(
      workspaceId: profile.workspaceId,
      athleteProfileId: profile.athleteProfileId,
      primaryGoal: profile.primaryGoal,
      goalTargetJson: jsonEncode(profile.goalTarget),
      experienceLevel: profile.experienceLevel,
      preferredSplit: profile.preferredSplit.code,
      daysPerWeek: profile.daysPerWeek,
      availableEquipmentJson: jsonEncode(profile.availableEquipment.toList()),
      contraindicationsJson: jsonEncode(profile.contraindications.toList()),
      scheduleConstraintsJson: jsonEncode(profile.scheduleConstraints),
      biometricsJson: jsonEncode(profile.biometrics),
    );
  }

  Future<String> buildPromptText(PlannerPromptContext context) async {
    final basePrompt = await promptService.getEffectivePromptTemplate();
    final derivedSections = _resolveDerivedSections(context);
    final derivedSectionsText = _renderDerivedSectionsBlock(derivedSections);
    final longRangeJson = context.longRangeContextRows.isEmpty
        ? '[]'
        : const JsonEncoder.withIndent('  ').convert(
            context.longRangeContextRows,
          );
    final recentMetricsJson = const JsonEncoder.withIndent('  ').convert(
      context.recentMetricsSummary,
    );
    final goalTargetJson = const JsonEncoder.withIndent('  ').convert(
      context.profile.goalTarget,
    );
    final biometricsV1 = BiometricsCalculator.computePromptPayloadFromMap(
      rawInput: context.profile.biometrics,
      daysPerWeek: context.profile.daysPerWeek,
    );
    final biometricsBlock = biometricsV1 == null
        ? ''
        : '''
BIOMETRICS_V1 (JSON):
${const JsonEncoder.withIndent('  ').convert(biometricsV1)}

''';

    final modifierInstructions = switch (context.modifier) {
      WeeklyPlanModifier.followLongTerm => '''
- Preserve long-term progression intent unless recent performance signals a necessary adjustment.
- Do not deload unless evidence supports it.''',
      WeeklyPlanModifier.lightWeek => '''
- This is a light week: reduce total volume and/or intensity by 15-35%.
- Keep technical quality and recovery high.
- Increase recovery emphasis and avoid aggressive progression.''',
      WeeklyPlanModifier.vacationTravel => '''
- This is a vacation/travel week: bias to minimal-equipment options and shorter sessions.
- Maintain movement quality and continuity while minimizing fatigue.
- Prefer bodyweight, dumbbell, cable, machine, and hotel-gym compatible options.''',
    };

    final extra = (context.additionalInstructions ?? '').trim();
    final extraBlock = extra.isEmpty ? '' : '\nAdditional Notes:\n$extra\n';
    final primaryGoal = context.profile.primaryGoal.trim().toLowerCase();
    final goalInstructionBlock = switch (primaryGoal) {
      'run_goal' || 'run_5mi_8min' => '''
Goal-Specific Instructions:
- Primary goal is run performance.
- Prioritize run prescription quality, progressive endurance development, and fatigue-aware run scheduling.
- Keep strength work supplemental unless split instructions require otherwise.''',
      'hypertrophy' => '''
Goal-Specific Instructions:
- Primary goal is hypertrophy-focused strength training.
- Bias strength prescriptions toward muscle growth while preserving run consistency.''',
      'strength' => '''
Goal-Specific Instructions:
- Primary goal is strength-focused training.
- Bias strength prescriptions toward measurable force/output progression while preserving run consistency.''',
      'cardio_improvement' || 'cardio' => '''
Goal-Specific Instructions:
- Primary goal is broad cardio improvement without a fixed race-distance target.
- Emphasize aerobic development, sustainable progression, and cardiovascular efficiency.
- Use varied cardio prescriptions as needed; avoid forcing a specific distance/pace milestone.''',
      _ => '''
Goal-Specific Instructions:
- Treat Athlete Profile primary_goal as authoritative over any generic defaults in the base prompt.''',
    };
    final splitInstructionBlock = context.splitType == SplitType.runOnly
        ? '''
Split-Specific Instructions:
- Requested split is run_only.
- Generate a run-only week: do not include any STRENGTH_SET rows.
- Because there are no strength sets, do not include ALT rows.
- Keep strength-focused fields blank or run-focused text only.
- Include only run prescriptions and recovery structure for the 7-day week.'''
        : '';
    const explanationInstructionBlock = '''
Plan Explanation Output Requirements:
- After the full WEEK_PLAN_V1 block (after END DAY 7), append:
  PLAN_EXPLANATION_V1
  WHY_THIS_WEEK: <plain-language rationale for this week structure>
  ADAPTATION_OR_GROWTH: <what this week is adapting/growing in the athlete>
  LOGIC_OVERVIEW: <brief summary of load/recovery/progression logic>
  END_PLAN_EXPLANATION_V1
- WHY_THIS_WEEK must answer: "Why am I training like this for the week?"
- ADAPTATION_OR_GROWTH must answer: "What adaptation or growth does the week provide to my body?"
- Keep explanation practical and athlete-facing, without medical claims.''';

    return '''
$basePrompt

=== APP_CONTEXT_V1 ===
Week Start: ${context.weekStart}
Week End: ${context.weekEnd}
Requested Split Type: ${context.splitType.label} (${context.splitType.code})
Requested Modifier: ${context.modifier.label} (${context.modifier.code})
Propagate Long-term Changes: ${context.propagateLongTermChanges ? 'yes' : 'no'}
Primary Goal Code: ${context.profile.primaryGoal}
Goal Target (JSON):
$goalTargetJson

Athlete Profile:
${const JsonEncoder.withIndent('  ').convert(context.profile.toJson())}

$biometricsBlock
Modifier Instructions:
$modifierInstructions
$goalInstructionBlock
$splitInstructionBlock
$explanationInstructionBlock

Long Range Context (JSON):
$longRangeJson

Recent Metrics Summary (JSON):
$recentMetricsJson
$derivedSectionsText
$extraBlock
=== END_APP_CONTEXT_V1 ===
''';
  }

  Future<WeeklyPlanBuildResult> generatePlan(
      WeeklyPlanBuildRequest request) async {
    final profile = await getPlanningProfile(
      workspaceId: request.workspaceId,
      athleteProfileId: request.athleteProfileId,
    );
    if (profile == null) {
      throw StateError(
          'Planning profile not found. Complete Athlete Intake first.');
    }

    final longRangeRows = await _loadLongRangeContext(request.weekStart);
    final recentMetricsSummary = await _loadRecentMetricsSummary(
      workspaceId: request.workspaceId,
      athleteProfileId: request.athleteProfileId,
      weekStart: request.weekStart,
    );
    final derivedSections = _derivePromptSections(
      recentMetricsSummary: recentMetricsSummary,
      goalTarget: profile.goalTarget,
    );
    final context = PlannerPromptContext(
      profile: profile,
      weekStart: request.weekStart,
      weekEnd: request.weekEnd,
      splitType: request.splitType,
      modifier: request.modifier,
      propagateLongTermChanges: request.propagateLongTermChanges,
      longRangeContextRows: longRangeRows,
      recentMetricsSummary: recentMetricsSummary,
      additionalInstructions: request.additionalInstructions,
      derivedMetricsV1: derivedSections.derivedMetricsV1,
      performanceBaselineV1: derivedSections.performanceBaselineV1,
      trainingLoadV1: derivedSections.trainingLoadV1,
      progressSignalsV1: derivedSections.progressSignalsV1,
      adaptationHistoryV1: derivedSections.adaptationHistoryV1,
    );

    final promptText = request.overridePromptText?.trim().isNotEmpty == true
        ? request.overridePromptText!.trim()
        : await buildPromptText(context);

    final requestPayload = {
      'week_start': request.weekStart,
      'week_end': request.weekEnd,
      'split_type': request.splitType.code,
      'modifier': request.modifier.code,
      'prompt_text': promptText,
      'planner_context': context.toJson(),
      'recent_metrics_summary': recentMetricsSummary,
      if (derivedSections.hasAny)
        'derived_prompt_context_v1': derivedSections.toJson(),
    };

    if (request.mode == PlannerGenerationMode.manualAssist) {
      await db.insertWeeklyPlanBuildRequest(
        workspaceId: request.workspaceId,
        athleteProfileId: request.athleteProfileId,
        weekStart: request.weekStart,
        weekEnd: request.weekEnd,
        splitType: request.splitType.code,
        modifier: request.modifier.code,
        mode: request.mode.code,
        promptSnapshot: promptText,
        requestPayloadJson: jsonEncode(requestPayload),
        responsePayloadJson: null,
        success: true,
      );
      return WeeklyPlanBuildResult(
        promptText: promptText,
        generatedText: null,
        importResult: null,
        mode: request.mode,
        serverSideRequested: false,
      );
    }

    await _ensureValidServerSession();

    String? generatedText;
    try {
      final response = await client.functions.invoke(
        'generate-weekly-plan',
        body: requestPayload,
      );
      final data = response.data;
      String? generatedBy;
      if (data is String) {
        generatedText = data.trim();
      } else if (data is Map<String, dynamic>) {
        generatedText = (data['plan_text'] as String?)?.trim();
        generatedBy = data['generated_by']?.toString();
      } else if (data is Map) {
        generatedText = (data['plan_text']?.toString())?.trim();
        generatedBy = data['generated_by']?.toString();
      }

      if ((generatedBy ?? '').toLowerCase() == 'fallback') {
        throw StateError(
          'Planner returned deterministic fallback content. AI provider is unavailable; fix OpenAI/provider config and retry.',
        );
      }

      if (generatedText == null || generatedText.isEmpty) {
        throw StateError('Edge function returned empty plan payload.');
      }

      final imported = await db.importAiWeeklyPlanText(
        text: generatedText,
        splitStartDate: request.splitStartDate,
      );
      await db.insertWeeklyPlanBuildRequest(
        workspaceId: request.workspaceId,
        athleteProfileId: request.athleteProfileId,
        weekStart: request.weekStart,
        weekEnd: request.weekEnd,
        splitType: request.splitType.code,
        modifier: request.modifier.code,
        mode: request.mode.code,
        promptSnapshot: promptText,
        requestPayloadJson: jsonEncode(requestPayload),
        responsePayloadJson: generatedText,
        success: true,
      );
      return WeeklyPlanBuildResult(
        promptText: promptText,
        generatedText: generatedText,
        importResult: imported,
        mode: request.mode,
        serverSideRequested: true,
      );
    } catch (e) {
      await db.insertWeeklyPlanBuildRequest(
        workspaceId: request.workspaceId,
        athleteProfileId: request.athleteProfileId,
        weekStart: request.weekStart,
        weekEnd: request.weekEnd,
        splitType: request.splitType.code,
        modifier: request.modifier.code,
        mode: request.mode.code,
        promptSnapshot: promptText,
        requestPayloadJson: jsonEncode(requestPayload),
        responsePayloadJson: generatedText,
        success: false,
        errorText: e.toString(),
      );
      rethrow;
    }
  }

  Future<AiWeeklyPlanTextImportResult> applyGeneratedPlanText({
    required WeeklyPlanBuildRequest request,
    required String generatedText,
  }) async {
    try {
      final imported = await db.importAiWeeklyPlanText(
        text: generatedText,
        splitStartDate: request.splitStartDate,
      );
      await db.insertWeeklyPlanBuildRequest(
        workspaceId: request.workspaceId,
        athleteProfileId: request.athleteProfileId,
        weekStart: request.weekStart,
        weekEnd: request.weekEnd,
        splitType: request.splitType.code,
        modifier: request.modifier.code,
        mode: request.mode.code,
        promptSnapshot: request.overridePromptText ?? '',
        requestPayloadJson: jsonEncode({
          'manual_apply': true,
          'week_start': request.weekStart,
          'week_end': request.weekEnd,
        }),
        responsePayloadJson: generatedText,
        success: true,
      );
      return imported;
    } catch (e) {
      await db.insertWeeklyPlanBuildRequest(
        workspaceId: request.workspaceId,
        athleteProfileId: request.athleteProfileId,
        weekStart: request.weekStart,
        weekEnd: request.weekEnd,
        splitType: request.splitType.code,
        modifier: request.modifier.code,
        mode: request.mode.code,
        promptSnapshot: request.overridePromptText ?? '',
        requestPayloadJson: jsonEncode({
          'manual_apply': true,
          'week_start': request.weekStart,
          'week_end': request.weekEnd,
        }),
        responsePayloadJson: generatedText,
        success: false,
        errorText: e.toString(),
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _loadLongRangeContext(
      String weekStart) async {
    final rows = await (db.select(db.planLongRangeWeeks)
          ..where((t) => t.weekEnd.isBiggerOrEqualValue(weekStart))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.weekStart, mode: OrderingMode.asc),
          ])
          ..limit(10))
        .get();
    return rows
        .map(
          (row) => {
            'week_label': row.weekLabel,
            'week_start': row.weekStart,
            'week_end': row.weekEnd,
            'run_focus': row.runFocus,
            'strength_focus': row.strengthFocus,
            'strength_progression_expectation':
                row.strengthProgressionExpectation,
            'primary_progression_target': row.primaryProgressionTarget,
            'recovery_emphasis': row.recoveryEmphasis,
            'deload': row.deload,
            'notes': row.notes,
          },
        )
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> _loadRecentMetricsSummary({
    required String workspaceId,
    required String athleteProfileId,
    required String weekStart,
    int lookbackDays = 21,
  }) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final todayYmd = toYmd(todayDate);
    final planWeekStartYmd = toYmd(DateTime.tryParse(weekStart) ?? todayDate);

    // Keep one-tap AI history aligned with the standard workbook export window:
    // inclusive [today - 20 days, today] => 21 days.
    final endYmd = todayYmd;
    final startYmd = toYmd(
      DateTime.parse(endYmd).subtract(Duration(days: lookbackDays - 1)),
    );

    final allDays = await db.select(db.workoutDays).get();
    final dayById = <String, String>{};
    final workoutDatesInWindow = <String>{};
    for (final day in allDays) {
      final date = day.workoutDate;
      if (date.compareTo(startYmd) < 0 || date.compareTo(endYmd) > 0) {
        continue;
      }
      dayById[day.id] = date;
      workoutDatesInWindow.add(date);
    }

    final strengthRows = await (db.select(db.actualStrengthSets)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.asc,
                ),
          ]))
        .get();
    final strengthHistory = <Map<String, dynamic>>[];
    final setsByExercise = <String, int>{};
    final strengthDaySet = <String>{};
    for (final row in strengthRows) {
      final workoutDate = dayById[row.workoutDayId];
      if (workoutDate == null) {
        continue;
      }
      strengthHistory.add({
        'workout_date': workoutDate,
        'exercise': row.exerciseCanonical,
        'set_index': row.setIndex,
        'weight': row.weight,
        'reps': row.reps,
        'rir': row.rir,
        'unit': row.unit,
        'source': row.source,
        'raw_set_string': row.rawSetString,
      });
      setsByExercise[row.exerciseCanonical] =
          (setsByExercise[row.exerciseCanonical] ?? 0) + 1;
      strengthDaySet.add(workoutDate);
    }
    final topExercises = setsByExercise.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) {
          return byCount;
        }
        return a.key.compareTo(b.key);
      });

    final runRows = await (db.select(db.runSessions)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.startTime,
                  mode: OrderingMode.asc,
                ),
          ]))
        .get();
    final runHistory = <Map<String, dynamic>>[];
    var totalRunDistanceM = 0.0;
    var totalRunDurationS = 0;
    var hrSum = 0.0;
    var hrCount = 0;
    var maxHr = 0.0;
    for (final run in runRows) {
      final workoutDate =
          run.workoutDayId == null ? null : dayById[run.workoutDayId!];
      if (workoutDate == null) {
        continue;
      }
      runHistory.add({
        'workout_date': workoutDate,
        'start_time': run.startTime,
        'duration_s': run.durationS,
        'distance_m': run.distanceM,
        'avg_hr': run.avgHr,
        'max_hr': run.maxHr,
        'activity_type': run.activityType,
        'source': run.source,
        'run_key': run.runKey,
      });
      totalRunDistanceM += run.distanceM ?? 0;
      totalRunDurationS += run.durationS ?? 0;
      if (run.avgHr != null) {
        hrSum += run.avgHr!;
        hrCount++;
      }
      if (run.maxHr != null && run.maxHr! > maxHr) {
        maxHr = run.maxHr!;
      }
    }

    final sleepRows = await (db.select(db.sleepNights)
          ..where((t) => t.sleepDate.isBetweenValues(startYmd, endYmd))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.sleepDate,
                  mode: OrderingMode.asc,
                ),
          ]))
        .get();
    final sleepHistory = <Map<String, dynamic>>[];
    var totalSleepMin = 0;
    var sleepCount = 0;
    for (final sleep in sleepRows) {
      sleepHistory.add({
        'sleep_date': sleep.sleepDate,
        'total_sleep_min': sleep.totalSleepMin,
        'deep_min': sleep.deepMin,
        'rem_min': sleep.remMin,
        'light_min': sleep.lightMin,
        'awake_min': sleep.awakeMin,
        'source': sleep.source,
      });
      if (sleep.totalSleepMin != null) {
        totalSleepMin += sleep.totalSleepMin!;
        sleepCount++;
      }
    }

    return {
      'window_basis': 'standard_workbook_export',
      'plan_week_start': planWeekStartYmd,
      'window_start': startYmd,
      'window_end': endYmd,
      'window_days': lookbackDays,
      'strength': {
        'set_count': strengthHistory.length,
        'training_days': strengthDaySet.length,
        'top_exercises': topExercises
            .take(8)
            .map((e) => {'exercise': e.key, 'set_count': e.value})
            .toList(growable: false),
        'history_rows': strengthHistory,
      },
      'run': {
        'session_count': runHistory.length,
        'total_distance_m': totalRunDistanceM,
        'total_duration_s': totalRunDurationS,
        'avg_hr': hrCount == 0 ? null : (hrSum / hrCount),
        'max_hr': maxHr == 0 ? null : maxHr,
        'history_rows': runHistory,
      },
      'sleep': {
        'nights_count': sleepHistory.length,
        'avg_total_sleep_min':
            sleepCount == 0 ? null : (totalSleepMin / sleepCount),
        'history_rows': sleepHistory,
      },
      'workout_dates_with_activity': workoutDatesInWindow.toList()..sort(),
    };
  }

  _PromptDerivedSections _resolveDerivedSections(PlannerPromptContext context) {
    final fallback = _derivePromptSections(
      recentMetricsSummary: context.recentMetricsSummary,
      goalTarget: context.profile.goalTarget,
    );
    return _PromptDerivedSections(
      derivedMetricsV1:
          _nonEmptyMap(context.derivedMetricsV1) ?? fallback.derivedMetricsV1,
      performanceBaselineV1: _nonEmptyMap(context.performanceBaselineV1) ??
          fallback.performanceBaselineV1,
      trainingLoadV1:
          _nonEmptyMap(context.trainingLoadV1) ?? fallback.trainingLoadV1,
      progressSignalsV1:
          _nonEmptyMap(context.progressSignalsV1) ?? fallback.progressSignalsV1,
      adaptationHistoryV1: _nonEmptyMap(context.adaptationHistoryV1) ??
          fallback.adaptationHistoryV1,
    );
  }

  String _renderDerivedSectionsBlock(_PromptDerivedSections sections) {
    final buffer = StringBuffer();
    _appendDerivedSection(
      buffer: buffer,
      sectionName: 'DERIVED_METRICS_V1',
      payload: sections.derivedMetricsV1,
    );
    _appendDerivedSection(
      buffer: buffer,
      sectionName: 'PERFORMANCE_BASELINE_V1',
      payload: sections.performanceBaselineV1,
    );
    _appendDerivedSection(
      buffer: buffer,
      sectionName: 'TRAINING_LOAD_V1',
      payload: sections.trainingLoadV1,
    );
    _appendDerivedSection(
      buffer: buffer,
      sectionName: 'PROGRESS_SIGNALS_V1',
      payload: sections.progressSignalsV1,
    );
    _appendDerivedSection(
      buffer: buffer,
      sectionName: 'ADAPTATION_HISTORY_V1',
      payload: sections.adaptationHistoryV1,
    );
    return buffer.toString();
  }

  void _appendDerivedSection({
    required StringBuffer buffer,
    required String sectionName,
    required Map<String, dynamic>? payload,
  }) {
    final map = _nonEmptyMap(payload);
    if (map == null) {
      return;
    }
    buffer.writeln();
    buffer.writeln('=== $sectionName ===');
    buffer.writeln(const JsonEncoder.withIndent('  ').convert(map));
    buffer.writeln('=== END_$sectionName ===');
  }

  _PromptDerivedSections _derivePromptSections({
    required Map<String, dynamic> recentMetricsSummary,
    required Map<String, dynamic> goalTarget,
  }) {
    final runData = _asMap(recentMetricsSummary['run']);
    final strengthData = _asMap(recentMetricsSummary['strength']);
    final sleepData = _asMap(recentMetricsSummary['sleep']);
    final hasSourceData =
        runData.isNotEmpty || strengthData.isNotEmpty || sleepData.isNotEmpty;
    if (!hasSourceData) {
      return const _PromptDerivedSections();
    }

    final rawRunRows = _asMapList(runData['history_rows'])
      ..sort((a, b) => _compareYmdMaps(a, b, dateKey: 'workout_date'));
    final quality = _filterCorruptedRuns(rawRunRows);
    final runRows = quality.validRows;

    final strengthRows = _asMapList(strengthData['history_rows'])
      ..sort((a, b) => _compareStrengthRows(a, b));
    final sleepRows = _asMapList(sleepData['history_rows'])
      ..sort((a, b) => _compareYmdMaps(a, b, dateKey: 'sleep_date'));

    final workoutDates = _asStringList(
      recentMetricsSummary['workout_dates_with_activity'],
    ).where(_isValidYmd).toSet().toList()
      ..sort();

    final windowDaysRaw = _asInt(recentMetricsSummary['window_days']) ?? 21;
    final windowDays = windowDaysRaw <= 0 ? 21 : windowDaysRaw;
    final windowWeeks = windowDays / 7.0;
    final fallbackEndYmd = toYmd(DateTime.now());
    final windowEndYmd =
        _normalizeYmd(recentMetricsSummary['window_end']) ?? fallbackEndYmd;

    final runSessions = runRows.length;
    final totalRunDistanceM = _sumDouble(runRows, 'distance_m');
    final totalRunDurationS = _sumInt(runRows, 'duration_s');
    final overallRunPaceSecPerKm = _paceSecPerKm(
      distanceM: totalRunDistanceM,
      durationS: totalRunDurationS,
    );

    final strengthSetCount = strengthRows.length;
    final strengthDaySet = <String>{};
    final exerciseCounts = <String, int>{};
    final strengthRowsByExercise = <String, List<Map<String, dynamic>>>{};
    final reps = <int>[];
    final rirs = <int>[];
    for (final row in strengthRows) {
      final workoutDate = _normalizeYmd(row['workout_date']);
      if (workoutDate != null) {
        strengthDaySet.add(workoutDate);
      }
      final exercise = _asText(row['exercise']);
      if (exercise.isNotEmpty) {
        exerciseCounts[exercise] = (exerciseCounts[exercise] ?? 0) + 1;
        strengthRowsByExercise
            .putIfAbsent(
              exercise,
              () => <Map<String, dynamic>>[],
            )
            .add(row);
      }
      final rep = _asInt(row['reps']);
      if (rep != null) {
        reps.add(rep);
      }
      final rir = _asInt(row['rir']);
      if (rir != null) {
        rirs.add(rir);
      }
    }
    for (final rows in strengthRowsByExercise.values) {
      rows.sort(_compareStrengthRows);
    }

    final sleepMinutes = sleepRows
        .map((row) => _asInt(row['total_sleep_min']))
        .whereType<int>()
        .toList(growable: false);
    final nightsLogged = sleepMinutes.length;
    final avgSleepHours = nightsLogged == 0
        ? null
        : _round(
            (sleepMinutes.fold<int>(0, (a, b) => a + b) / nightsLogged) / 60,
            precision: 3);
    final lowSleepNights =
        sleepMinutes.where((minutes) => minutes < 360).length;
    final adequateSleepNights =
        sleepMinutes.where((minutes) => minutes >= 420).length;

    final windowStats = _computeWindowStats(
      runRows: runRows,
      strengthRows: strengthRows,
      sleepRows: sleepRows,
      workoutDates: workoutDates,
      windowEndYmd: windowEndYmd,
    );

    final derivedMetricsV1 = _buildDerivedMetricsV1(
      windowDays: windowDays,
      windowWeeks: windowWeeks,
      activeDaysCount: workoutDates.length,
      runSessions: runSessions,
      totalRunDistanceM: totalRunDistanceM,
      totalRunDurationS: totalRunDurationS,
      overallRunPaceSecPerKm: overallRunPaceSecPerKm,
      totalStrengthSets: strengthSetCount,
      strengthTrainingDays: strengthDaySet.length,
      uniqueExerciseCount: exerciseCounts.length,
      avgReps: reps.isEmpty
          ? null
          : _round(reps.fold<int>(0, (a, b) => a + b) / reps.length,
              precision: 2),
      avgRir: rirs.isEmpty
          ? null
          : _round(rirs.fold<int>(0, (a, b) => a + b) / rirs.length,
              precision: 2),
      nightsLogged: nightsLogged,
      avgSleepHours: avgSleepHours,
      lowSleepNights: lowSleepNights,
      adequateSleepNights: adequateSleepNights,
      runDataValid: quality.corruptedRunsDetected == 0,
      corruptedRunsDetected: quality.corruptedRunsDetected,
    );

    final performanceBaselineV1 = _buildPerformanceBaselineV1(
      runRows: runRows,
      totalRunDistanceM: totalRunDistanceM,
      totalRunDurationS: totalRunDurationS,
      topExercisesFromSummary: _asMapList(strengthData['top_exercises']),
      exerciseCounts: exerciseCounts,
      strengthRowsByExercise: strengthRowsByExercise,
      sleepMinutes: sleepMinutes,
      avgSleepHours: avgSleepHours,
      goalTarget: goalTarget,
    );

    final trainingLoadV1 = _buildTrainingLoadV1(
      windowStats: windowStats,
    );
    final progressSignalsV1 = _buildProgressSignalsV1(
      windowStats: windowStats,
      activeDaysPerWeek: windowWeeks == 0
          ? null
          : _round(workoutDates.length / windowWeeks, precision: 3),
      avgSleepHours: avgSleepHours,
      acuteRunRatio: _acuteRatio(
        latest: windowStats.latest7RunDistanceM,
        prior14Total: windowStats.prior14RunDistanceM,
      ),
    );
    final adaptationHistoryV1 = _buildAdaptationHistoryV1(
      windowStats: windowStats,
    );

    return _PromptDerivedSections(
      derivedMetricsV1: derivedMetricsV1,
      performanceBaselineV1: performanceBaselineV1,
      trainingLoadV1: trainingLoadV1,
      progressSignalsV1: progressSignalsV1,
      adaptationHistoryV1: adaptationHistoryV1,
    );
  }

  Map<String, dynamic>? _buildDerivedMetricsV1({
    required int windowDays,
    required double windowWeeks,
    required int activeDaysCount,
    required int runSessions,
    required double totalRunDistanceM,
    required int totalRunDurationS,
    required double? overallRunPaceSecPerKm,
    required int totalStrengthSets,
    required int strengthTrainingDays,
    required int uniqueExerciseCount,
    required double? avgReps,
    required double? avgRir,
    required int nightsLogged,
    required double? avgSleepHours,
    required int lowSleepNights,
    required int adequateSleepNights,
    required bool runDataValid,
    required int corruptedRunsDetected,
  }) {
    final hasAnyData = activeDaysCount > 0 ||
        runSessions > 0 ||
        totalStrengthSets > 0 ||
        nightsLogged > 0 ||
        corruptedRunsDetected > 0;
    if (!hasAnyData) {
      return null;
    }

    final map = <String, dynamic>{
      'window_days': windowDays,
      'active_days_count': activeDaysCount,
      'active_days_per_week': _round(
          windowWeeks == 0 ? 0 : activeDaysCount / windowWeeks,
          precision: 3),
      'run_sessions': runSessions,
      'run_sessions_per_week': _round(
          windowWeeks == 0 ? 0 : runSessions / windowWeeks,
          precision: 3),
      'total_run_distance_m': _round(totalRunDistanceM, precision: 2),
      'total_run_duration_s': totalRunDurationS,
      'total_strength_sets': totalStrengthSets,
      'sets_per_week': _round(
        windowWeeks == 0 ? 0 : totalStrengthSets / windowWeeks,
        precision: 3,
      ),
      'unique_exercise_count': uniqueExerciseCount,
      'nights_logged': nightsLogged,
      'nights_per_week': _round(
          windowWeeks == 0 ? 0 : nightsLogged / windowWeeks,
          precision: 3),
      'low_sleep_nights': lowSleepNights,
      'adequate_sleep_nights': adequateSleepNights,
      'data_quality': {
        'run_data_valid': runDataValid,
        'corrupted_runs_detected': corruptedRunsDetected,
      },
    };
    if (runSessions > 0) {
      map['avg_run_distance_m'] =
          _round(totalRunDistanceM / runSessions, precision: 2);
      map['avg_run_duration_s'] =
          _round(totalRunDurationS / runSessions, precision: 2);
    }
    if (overallRunPaceSecPerKm != null) {
      map['overall_run_pace_sec_per_km'] = overallRunPaceSecPerKm;
    }
    if (strengthTrainingDays > 0) {
      map['avg_sets_per_training_day'] =
          _round(totalStrengthSets / strengthTrainingDays, precision: 3);
    }
    if (avgReps != null) {
      map['avg_reps'] = avgReps;
    }
    if (avgRir != null) {
      map['avg_rir'] = avgRir;
    }
    if (avgSleepHours != null) {
      map['avg_sleep_hours'] = avgSleepHours;
    }
    return map;
  }

  Map<String, dynamic>? _buildPerformanceBaselineV1({
    required List<Map<String, dynamic>> runRows,
    required double totalRunDistanceM,
    required int totalRunDurationS,
    required List<Map<String, dynamic>> topExercisesFromSummary,
    required Map<String, int> exerciseCounts,
    required Map<String, List<Map<String, dynamic>>> strengthRowsByExercise,
    required List<int> sleepMinutes,
    required double? avgSleepHours,
    required Map<String, dynamic> goalTarget,
  }) {
    final runSessions = runRows.length;
    final map = <String, dynamic>{};

    if (runSessions > 0) {
      map['avg_run_distance_m'] =
          _round(totalRunDistanceM / runSessions, precision: 2);
      map['avg_run_duration_s'] =
          _round(totalRunDurationS / runSessions, precision: 2);
      final baselinePaceSecPerKm = _paceSecPerKm(
        distanceM: totalRunDistanceM,
        durationS: totalRunDurationS,
      );
      if (baselinePaceSecPerKm != null) {
        map['baseline_pace_sec_per_km'] = baselinePaceSecPerKm;
      }
      final hrRows = runRows
          .where((row) => _asDouble(row['avg_hr']) != null)
          .toList(growable: false);
      if (hrRows.isNotEmpty) {
        final avgRunHr = hrRows
                .map((row) => _asDouble(row['avg_hr'])!)
                .fold<double>(0.0, (a, b) => a + b) /
            hrRows.length;
        map['avg_run_hr'] = _round(avgRunHr, precision: 2);
        final hrDistanceM = hrRows
            .map((row) => _asDouble(row['distance_m']) ?? 0.0)
            .fold<double>(0.0, (a, b) => a + b);
        final hrDurationS = hrRows
            .map((row) => _asInt(row['duration_s']) ?? 0)
            .fold<int>(0, (a, b) => a + b);
        final paceAtAvgHr = _paceSecPerKm(
          distanceM: hrDistanceM,
          durationS: hrDurationS,
        );
        if (paceAtAvgHr != null) {
          map['pace_at_avg_hr'] = paceAtAvgHr;
        }
      }

      final estimatedCurrentPacePerMile = _paceSecPerMile(
        distanceM: totalRunDistanceM,
        durationS: totalRunDurationS,
      );
      final targetPacePerMile = _parseGoalTargetPaceSecPerMile(goalTarget);
      if (estimatedCurrentPacePerMile != null) {
        map['estimated_current_pace_per_mile'] = estimatedCurrentPacePerMile;
      }
      if (estimatedCurrentPacePerMile != null &&
          targetPacePerMile != null &&
          targetPacePerMile > 0) {
        map['goal_progress_percent'] = _round(
          ((targetPacePerMile - estimatedCurrentPacePerMile) /
                  targetPacePerMile) *
              100,
          precision: 2,
        );
      }
    }

    final topExercises = _topExerciseCounts(
      fromSummary: topExercisesFromSummary,
      fallbackCounts: exerciseCounts,
      limit: 5,
    );
    if (topExercises.isNotEmpty) {
      final rows = <Map<String, dynamic>>[];
      for (final exerciseRow in topExercises) {
        final exercise = _asText(exerciseRow['exercise']);
        if (exercise.isEmpty) {
          continue;
        }
        final history = strengthRowsByExercise[exercise] ?? const [];
        if (history.isEmpty) {
          continue;
        }
        final latest = history.last;
        final weight = _asDouble(latest['weight']);
        final reps = _asInt(latest['reps']);
        final baselineRow = <String, dynamic>{
          'exercise': exercise,
        };
        if (weight != null) {
          baselineRow['most_recent_weight'] = _round(weight, precision: 2);
        }
        if (reps != null) {
          baselineRow['most_recent_reps'] = reps;
        }
        if (weight != null && reps != null && reps > 0 && reps <= 12) {
          baselineRow['estimated_1rm'] =
              _round(weight * (1 + (reps / 30.0)), precision: 2);
        }
        rows.add(baselineRow);
      }
      if (rows.isNotEmpty) {
        map['strength_top_5_exercises'] = rows;
      }
    }

    if (avgSleepHours != null) {
      map['avg_sleep_hours'] = avgSleepHours;
    }
    if (sleepMinutes.length >= 5) {
      final sdHours =
          _stdDev(sleepMinutes.map((e) => e / 60.0).toList(growable: false));
      if (sdHours != null) {
        map['sleep_variability_sd'] = sdHours;
      }
    }

    return map.isEmpty ? null : map;
  }

  Map<String, dynamic>? _buildTrainingLoadV1({
    required _WindowStats windowStats,
  }) {
    final map = <String, dynamic>{
      'run_distance_last_7d':
          _round(windowStats.latest7RunDistanceM, precision: 2),
      'run_distance_prior_14d_weekly_avg':
          _round(windowStats.prior14RunDistanceM / 2, precision: 2),
      'strength_sets_last_7d': windowStats.latest7StrengthSetCount,
      'strength_sets_prior_14d_weekly_avg':
          _round(windowStats.prior14StrengthSetCount / 2, precision: 3),
      'active_days_last_7d': windowStats.latest7ActiveDaysCount,
    };
    final acuteRunRatio = _acuteRatio(
      latest: windowStats.latest7RunDistanceM,
      prior14Total: windowStats.prior14RunDistanceM,
    );
    if (acuteRunRatio != null) {
      map['acute_run_ratio'] = acuteRunRatio;
    }
    final acuteStrengthRatio = _acuteRatio(
      latest: windowStats.latest7StrengthSetCount.toDouble(),
      prior14Total: windowStats.prior14StrengthSetCount.toDouble(),
    );
    if (acuteStrengthRatio != null) {
      map['acute_strength_ratio'] = acuteStrengthRatio;
    }
    final hasAnyData = windowStats.latest7RunSessionCount > 0 ||
        windowStats.prior14RunSessionCount > 0 ||
        windowStats.latest7StrengthSetCount > 0 ||
        windowStats.prior14StrengthSetCount > 0 ||
        windowStats.latest7ActiveDaysCount > 0;
    return hasAnyData ? map : null;
  }

  Map<String, dynamic>? _buildProgressSignalsV1({
    required _WindowStats windowStats,
    required double? activeDaysPerWeek,
    required double? avgSleepHours,
    required double? acuteRunRatio,
  }) {
    final map = <String, dynamic>{};
    if (windowStats.latest7RunSessionCount > 0 ||
        windowStats.prior14RunSessionCount > 0) {
      map['run_volume_trend'] = _trendFromLatestVsWeeklyBaseline(
        latest: windowStats.latest7RunDistanceM,
        prior14Total: windowStats.prior14RunDistanceM,
        thresholdPct: 10,
      );
    }
    if (windowStats.latest7StrengthSetCount > 0 ||
        windowStats.prior14StrengthSetCount > 0) {
      map['strength_set_trend'] = _trendFromLatestVsWeeklyBaseline(
        latest: windowStats.latest7StrengthSetCount.toDouble(),
        prior14Total: windowStats.prior14StrengthSetCount.toDouble(),
        thresholdPct: 10,
      );
    }
    if (windowStats.latest7SleepAvgMin != null &&
        windowStats.prior14SleepAvgMin != null) {
      final deltaMin =
          windowStats.latest7SleepAvgMin! - windowStats.prior14SleepAvgMin!;
      map['sleep_trend'] = deltaMin > 20
          ? 'improving'
          : deltaMin < -20
              ? 'worsening'
              : 'flat';
    }
    if (activeDaysPerWeek != null && activeDaysPerWeek > 0) {
      map['training_consistency'] = activeDaysPerWeek >= 4
          ? 'high'
          : activeDaysPerWeek >= 2.5
              ? 'moderate'
              : 'low';
    }

    final fatigueRisk = _fatigueRisk(
      avgSleepHours: avgSleepHours,
      acuteRunRatio: acuteRunRatio,
    );
    if (fatigueRisk != null) {
      map['fatigue_risk'] = fatigueRisk;
    }
    return map.isEmpty ? null : map;
  }

  Map<String, dynamic>? _buildAdaptationHistoryV1({
    required _WindowStats windowStats,
  }) {
    final map = <String, dynamic>{};
    if (windowStats.latest7RunPaceSecPerKm != null &&
        windowStats.prior14RunPaceSecPerKm != null &&
        windowStats.prior14RunPaceSecPerKm! > 0) {
      final deltaPct = ((windowStats.latest7RunPaceSecPerKm! -
                  windowStats.prior14RunPaceSecPerKm!) /
              windowStats.prior14RunPaceSecPerKm!) *
          100;
      map['run_pace_trend'] = deltaPct <= -3
          ? 'improving'
          : deltaPct >= 3
              ? 'worsening'
              : 'flat';
    }

    if (windowStats.latest7LongRunDistanceM > 0 ||
        windowStats.prior14LongRunDistanceWeeklyAvgM > 0) {
      final longRunTrend = _trendFromLatestVsBaseline(
        latest: windowStats.latest7LongRunDistanceM,
        baseline: windowStats.prior14LongRunDistanceWeeklyAvgM,
        thresholdPct: 10,
      );
      if (longRunTrend != null) {
        map['long_run_distance_trend'] = longRunTrend;
      }
    }

    if (windowStats.latest7StrengthSetCount > 0 ||
        windowStats.prior14StrengthSetCount > 0) {
      map['strength_load_trend'] = _trendFromLatestVsWeeklyBaseline(
        latest: windowStats.latest7StrengthSetCount.toDouble(),
        prior14Total: windowStats.prior14StrengthSetCount.toDouble(),
        thresholdPct: 10,
      );
    }

    if (windowStats.latest7ActiveDaysCount > 0 ||
        windowStats.prior14ActiveDaysCount > 0) {
      map['training_density'] = windowStats.latest7ActiveDaysCount >= 5
          ? 'high'
          : windowStats.latest7ActiveDaysCount >= 3
              ? 'moderate'
              : 'low';
    }
    return map.isEmpty ? null : map;
  }

  _WindowStats _computeWindowStats({
    required List<Map<String, dynamic>> runRows,
    required List<Map<String, dynamic>> strengthRows,
    required List<Map<String, dynamic>> sleepRows,
    required List<String> workoutDates,
    required String windowEndYmd,
  }) {
    final normalizedEnd = _normalizeYmd(windowEndYmd) ?? toYmd(DateTime.now());
    final endDate = parseYmd(normalizedEnd);
    final latestStart = toYmd(endDate.subtract(const Duration(days: 6)));
    final priorStart = toYmd(endDate.subtract(const Duration(days: 20)));
    final priorEnd = toYmd(endDate.subtract(const Duration(days: 7)));

    double latest7RunDistanceM = 0;
    int latest7RunDurationS = 0;
    int latest7RunSessionCount = 0;
    double prior14RunDistanceM = 0;
    int prior14RunDurationS = 0;
    int prior14RunSessionCount = 0;
    double latest7LongRunDistanceM = 0;
    double prior14LongRunWeekA = 0;
    double prior14LongRunWeekB = 0;
    final weekACutoff =
        toYmd(parseYmd(priorStart).add(const Duration(days: 6)));
    final weekBStart = toYmd(parseYmd(priorStart).add(const Duration(days: 7)));

    for (final row in runRows) {
      final date = _normalizeYmd(row['workout_date']);
      if (date == null) {
        continue;
      }
      final distanceM = _asDouble(row['distance_m']) ?? 0;
      final durationS = _asInt(row['duration_s']) ?? 0;
      if (_ymdInRange(date, latestStart, normalizedEnd)) {
        latest7RunDistanceM += distanceM;
        latest7RunDurationS += durationS;
        latest7RunSessionCount++;
        if (distanceM > latest7LongRunDistanceM) {
          latest7LongRunDistanceM = distanceM;
        }
      } else if (_ymdInRange(date, priorStart, priorEnd)) {
        prior14RunDistanceM += distanceM;
        prior14RunDurationS += durationS;
        prior14RunSessionCount++;
        if (_ymdInRange(date, priorStart, weekACutoff)) {
          if (distanceM > prior14LongRunWeekA) {
            prior14LongRunWeekA = distanceM;
          }
        } else if (_ymdInRange(date, weekBStart, priorEnd)) {
          if (distanceM > prior14LongRunWeekB) {
            prior14LongRunWeekB = distanceM;
          }
        }
      }
    }

    int latest7StrengthSetCount = 0;
    int prior14StrengthSetCount = 0;
    for (final row in strengthRows) {
      final date = _normalizeYmd(row['workout_date']);
      if (date == null) {
        continue;
      }
      if (_ymdInRange(date, latestStart, normalizedEnd)) {
        latest7StrengthSetCount++;
      } else if (_ymdInRange(date, priorStart, priorEnd)) {
        prior14StrengthSetCount++;
      }
    }

    int latest7ActiveDaysCount = 0;
    int prior14ActiveDaysCount = 0;
    for (final date in workoutDates) {
      if (_ymdInRange(date, latestStart, normalizedEnd)) {
        latest7ActiveDaysCount++;
      } else if (_ymdInRange(date, priorStart, priorEnd)) {
        prior14ActiveDaysCount++;
      }
    }

    final latest7SleepValues = <double>[];
    final prior14SleepValues = <double>[];
    for (final row in sleepRows) {
      final date = _normalizeYmd(row['sleep_date']);
      final minutes = _asInt(row['total_sleep_min']);
      if (date == null || minutes == null) {
        continue;
      }
      if (_ymdInRange(date, latestStart, normalizedEnd)) {
        latest7SleepValues.add(minutes.toDouble());
      } else if (_ymdInRange(date, priorStart, priorEnd)) {
        prior14SleepValues.add(minutes.toDouble());
      }
    }

    return _WindowStats(
      latest7RunDistanceM: latest7RunDistanceM,
      latest7RunDurationS: latest7RunDurationS,
      latest7RunSessionCount: latest7RunSessionCount,
      latest7StrengthSetCount: latest7StrengthSetCount,
      latest7ActiveDaysCount: latest7ActiveDaysCount,
      prior14RunDistanceM: prior14RunDistanceM,
      prior14RunDurationS: prior14RunDurationS,
      prior14RunSessionCount: prior14RunSessionCount,
      prior14StrengthSetCount: prior14StrengthSetCount,
      prior14ActiveDaysCount: prior14ActiveDaysCount,
      latest7SleepAvgMin: latest7SleepValues.isEmpty
          ? null
          : _round(
              latest7SleepValues.fold<double>(0, (a, b) => a + b) /
                  latest7SleepValues.length,
              precision: 2,
            ),
      prior14SleepAvgMin: prior14SleepValues.isEmpty
          ? null
          : _round(
              prior14SleepValues.fold<double>(0, (a, b) => a + b) /
                  prior14SleepValues.length,
              precision: 2,
            ),
      latest7RunPaceSecPerKm: _paceSecPerKm(
        distanceM: latest7RunDistanceM,
        durationS: latest7RunDurationS,
      ),
      prior14RunPaceSecPerKm: _paceSecPerKm(
        distanceM: prior14RunDistanceM,
        durationS: prior14RunDurationS,
      ),
      latest7LongRunDistanceM: latest7LongRunDistanceM,
      prior14LongRunDistanceWeeklyAvgM:
          _round((prior14LongRunWeekA + prior14LongRunWeekB) / 2, precision: 2),
    );
  }

  _RunQuality _filterCorruptedRuns(List<Map<String, dynamic>> runRows) {
    final validRows = <Map<String, dynamic>>[];
    var corrupted = 0;
    for (final row in runRows) {
      final distanceM = _asDouble(row['distance_m']);
      final durationS = _asInt(row['duration_s']);
      var isCorrupted = false;
      if (distanceM != null &&
          distanceM > 0 &&
          durationS != null &&
          durationS > 0) {
        final paceSecPerMile = (durationS / (distanceM / 1609.344));
        if (paceSecPerMile < 210) {
          isCorrupted = true;
        }
      }
      if (distanceM != null &&
          durationS != null &&
          distanceM > 20000 &&
          durationS < 1800) {
        isCorrupted = true;
      }
      if (isCorrupted) {
        corrupted++;
      } else {
        validRows.add(row);
      }
    }
    return _RunQuality(
      validRows: List<Map<String, dynamic>>.unmodifiable(validRows),
      corruptedRunsDetected: corrupted,
    );
  }

  double? _acuteRatio({
    required double latest,
    required double prior14Total,
  }) {
    final baseline = prior14Total / 2;
    if (baseline <= 0) {
      return null;
    }
    return _round(latest / baseline, precision: 3);
  }

  String _trendFromLatestVsWeeklyBaseline({
    required double latest,
    required double prior14Total,
    required double thresholdPct,
  }) {
    final baseline = prior14Total / 2;
    if (baseline <= 0) {
      return latest > 0 ? 'up' : 'flat';
    }
    final deltaPct = ((latest - baseline) / baseline) * 100;
    if (deltaPct > thresholdPct) {
      return 'up';
    }
    if (deltaPct < -thresholdPct) {
      return 'down';
    }
    return 'flat';
  }

  String? _trendFromLatestVsBaseline({
    required double latest,
    required double baseline,
    required double thresholdPct,
  }) {
    if (baseline <= 0) {
      return latest > 0 ? 'up' : 'flat';
    }
    final deltaPct = ((latest - baseline) / baseline) * 100;
    if (deltaPct > thresholdPct) {
      return 'up';
    }
    if (deltaPct < -thresholdPct) {
      return 'down';
    }
    return 'flat';
  }

  String? _fatigueRisk({
    required double? avgSleepHours,
    required double? acuteRunRatio,
  }) {
    if (avgSleepHours == null && acuteRunRatio == null) {
      return null;
    }
    final ratio = acuteRunRatio ?? 0;
    if (avgSleepHours != null && avgSleepHours < 6.5 && ratio > 1.3) {
      return 'high';
    }
    if ((avgSleepHours != null && avgSleepHours < 7) || ratio > 1.15) {
      return 'moderate';
    }
    return 'low';
  }

  double? _paceSecPerMile({
    required double distanceM,
    required int durationS,
  }) {
    if (distanceM <= 0 || durationS <= 0) {
      return null;
    }
    final miles = distanceM / 1609.344;
    if (miles <= 0) {
      return null;
    }
    return _round(durationS / miles, precision: 2);
  }

  double? _paceSecPerKm({
    required double distanceM,
    required int durationS,
  }) {
    if (distanceM <= 0 || durationS <= 0) {
      return null;
    }
    final km = distanceM / 1000;
    if (km <= 0) {
      return null;
    }
    return _round(durationS / km, precision: 2);
  }

  double? _parseGoalTargetPaceSecPerMile(Map<String, dynamic> goalTarget) {
    final raw = _asText(goalTarget['target_pace']);
    if (raw.isEmpty) {
      return null;
    }
    return _parsePaceTextToSecPerMile(raw);
  }

  double? _parsePaceTextToSecPerMile(String text) {
    final raw = text.trim().toLowerCase();
    if (raw.isEmpty) {
      return null;
    }
    final hasKm = raw.contains('/km') || raw.contains('per km');
    final hasMile = raw.contains('/mi') ||
        raw.contains('/mile') ||
        raw.contains('per mile');

    double? seconds;
    final minSec = RegExp(r'(\d{1,2})\s*:\s*(\d{2})').firstMatch(raw);
    if (minSec != null) {
      final min = int.tryParse(minSec.group(1)!);
      final sec = int.tryParse(minSec.group(2)!);
      if (min != null && sec != null) {
        seconds = (min * 60 + sec).toDouble();
      }
    }
    if (seconds == null) {
      final decimal = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(raw);
      if (decimal != null) {
        final value = double.tryParse(decimal.group(1)!);
        if (value != null) {
          seconds = value * 60;
        }
      }
    }
    if (seconds == null || seconds <= 0) {
      return null;
    }
    if (hasKm && !hasMile) {
      return _round(seconds * 1.609344, precision: 2);
    }
    return _round(seconds, precision: 2);
  }

  List<Map<String, dynamic>> _topExerciseCounts({
    required List<Map<String, dynamic>> fromSummary,
    required Map<String, int> fallbackCounts,
    required int limit,
  }) {
    final fromSummaryNormalized = fromSummary
        .map((row) {
          final exercise = _asText(row['exercise']);
          final setCount = _asInt(row['set_count']) ?? 0;
          return {
            'exercise': exercise,
            'set_count': setCount,
          };
        })
        .where((row) =>
            _asText(row['exercise']).isNotEmpty &&
            (_asInt(row['set_count']) ?? 0) > 0)
        .toList(growable: false);
    if (fromSummaryNormalized.isNotEmpty) {
      final rows = List<Map<String, dynamic>>.from(fromSummaryNormalized)
        ..sort((a, b) {
          final byCount = (_asInt(b['set_count']) ?? 0)
              .compareTo(_asInt(a['set_count']) ?? 0);
          if (byCount != 0) {
            return byCount;
          }
          return _asText(a['exercise']).compareTo(_asText(b['exercise']));
        });
      return rows.take(limit).toList(growable: false);
    }

    final rows = fallbackCounts.entries
        .map((entry) => {
              'exercise': entry.key,
              'set_count': entry.value,
            })
        .toList(growable: false)
      ..sort((a, b) {
        final byCount = (_asInt(b['set_count']) ?? 0)
            .compareTo(_asInt(a['set_count']) ?? 0);
        if (byCount != 0) {
          return byCount;
        }
        return _asText(a['exercise']).compareTo(_asText(b['exercise']));
      });
    return rows.take(limit).toList(growable: false);
  }

  double _round(double value, {required int precision}) =>
      double.parse(value.toStringAsFixed(precision));

  double? _stdDev(List<double> values) {
    if (values.isEmpty) {
      return null;
    }
    final mean = values.fold<double>(0.0, (sum, v) => sum + v) / values.length;
    var variance = 0.0;
    for (final value in values) {
      final diff = value - mean;
      variance += diff * diff;
    }
    variance /= values.length;
    return _round(math.sqrt(variance), precision: 2);
  }

  int _sumInt(List<Map<String, dynamic>> rows, String key) {
    var total = 0;
    for (final row in rows) {
      total += _asInt(row[key]) ?? 0;
    }
    return total;
  }

  double _sumDouble(List<Map<String, dynamic>> rows, String key) {
    var total = 0.0;
    for (final row in rows) {
      total += _asDouble(row[key]) ?? 0.0;
    }
    return total;
  }

  Map<String, dynamic>? _nonEmptyMap(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw;
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asMapList(dynamic raw) {
    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }
    return raw
        .map((item) => _asMap(item))
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> _asStringList(dynamic raw) {
    if (raw is! List) {
      return const <String>[];
    }
    return raw
        .map((item) => _asText(item))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String _asText(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  int? _asInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString().trim());
  }

  double? _asDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString().trim());
  }

  String? _normalizeYmd(dynamic value) {
    final text = _asText(value);
    if (!_isValidYmd(text)) {
      return null;
    }
    return text;
  }

  bool _isValidYmd(String ymd) {
    if (ymd.length != 10) {
      return false;
    }
    try {
      parseYmd(ymd);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _ymdInRange(String ymd, String startInclusive, String endInclusive) {
    return ymd.compareTo(startInclusive) >= 0 &&
        ymd.compareTo(endInclusive) <= 0;
  }

  int _compareYmdMaps(
    Map<String, dynamic> a,
    Map<String, dynamic> b, {
    required String dateKey,
  }) {
    final aDate = _normalizeYmd(a[dateKey]) ?? '';
    final bDate = _normalizeYmd(b[dateKey]) ?? '';
    final byDate = aDate.compareTo(bDate);
    if (byDate != 0) {
      return byDate;
    }
    return 0;
  }

  int _compareStrengthRows(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final byDate = _compareYmdMaps(a, b, dateKey: 'workout_date');
    if (byDate != 0) {
      return byDate;
    }
    final aSet = _asInt(a['set_index']) ?? 0;
    final bSet = _asInt(b['set_index']) ?? 0;
    final bySet = aSet.compareTo(bSet);
    if (bySet != 0) {
      return bySet;
    }
    return _asText(a['exercise']).compareTo(_asText(b['exercise']));
  }

  Map<String, dynamic> _decodeJsonMap(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  List<String> _decodeStringSet(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <String>[];
    }
    return decoded.map((e) => e.toString()).toList(growable: false);
  }

  Future<Session> _ensureValidServerSession() async {
    final initialSession = client.auth.currentSession;
    if (initialSession == null || initialSession.accessToken.isEmpty) {
      throw StateError(
        'Server-side AI requires a valid Supabase login session. Please sign out and sign back in.',
      );
    }
    Session session = initialSession;

    final expiresAt = session.expiresAt;
    if (expiresAt != null) {
      final expiryUtc =
          DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000, isUtc: true);
      final nowUtc = DateTime.now().toUtc();
      if (!expiryUtc.isAfter(nowUtc.add(const Duration(seconds: 30)))) {
        try {
          final refreshed = await client.auth.refreshSession();
          final refreshedSession = refreshed.session;
          if (refreshedSession != null &&
              refreshedSession.accessToken.isNotEmpty) {
            session = refreshedSession;
          }
        } catch (_) {
          // Fall through to final session validation below.
        }
      }
    }

    final activeSession = client.auth.currentSession ?? session;
    if (activeSession.accessToken.isEmpty) {
      throw StateError(
        'Server-side AI session is invalid. Please sign out and sign back in.',
      );
    }

    return activeSession;
  }
}
