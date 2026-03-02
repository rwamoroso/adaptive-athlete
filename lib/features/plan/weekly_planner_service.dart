import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/date_utils.dart';
import '../../db/app_db.dart';
import 'weekly_plan_prompt_service.dart';

enum SplitType {
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

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'week_start': weekStart,
        'week_end': weekEnd,
        'split_type': splitType.code,
        'modifier': modifier.code,
        'propagate_long_term_changes': propagateLongTermChanges,
        'long_range_context_rows': longRangeContextRows,
        'recent_metrics_summary': recentMetricsSummary,
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
    );
  }

  Future<String> buildPromptText(PlannerPromptContext context) async {
    final basePrompt = await promptService.getEffectivePromptTemplate();
    final longRangeJson = context.longRangeContextRows.isEmpty
        ? '[]'
        : const JsonEncoder.withIndent('  ').convert(
            context.longRangeContextRows,
          );
    final recentMetricsJson = const JsonEncoder.withIndent('  ').convert(
      context.recentMetricsSummary,
    );

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

    return '''
$basePrompt

=== APP_CONTEXT_V1 ===
Week Start: ${context.weekStart}
Week End: ${context.weekEnd}
Requested Split Type: ${context.splitType.label} (${context.splitType.code})
Requested Modifier: ${context.modifier.label} (${context.modifier.code})
Propagate Long-term Changes: ${context.propagateLongTermChanges ? 'yes' : 'no'}

Athlete Profile:
${const JsonEncoder.withIndent('  ').convert(context.profile.toJson())}

Modifier Instructions:
$modifierInstructions

Long Range Context (JSON):
$longRangeJson

Recent Metrics Summary (JSON):
$recentMetricsJson
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
