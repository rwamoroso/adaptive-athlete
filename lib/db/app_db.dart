import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:uuid/uuid.dart';

import '../core/parsing/exercise_normalizer.dart';
import '../core/utils/date_utils.dart';
import '../features/plan/ppl_template_service.dart';
import '../features/training/garmin_csv_import_service.dart';
import '../features/training/strength_history_import_service.dart';
import 'tables/actual_strength_sets.dart';
import 'tables/app_prompt_templates.dart';
import 'tables/app_context_state.dart';
import 'tables/ai_audit.dart';
import 'tables/cloud_athlete_profile_assignments.dart';
import 'tables/cloud_athlete_profiles.dart';
import 'tables/cloud_workspace_invites.dart';
import 'tables/cloud_workspace_memberships.dart';
import 'tables/cloud_workspaces.dart';
import 'tables/exercise_substitutions.dart';
import 'tables/plan_cycles.dart';
import 'tables/plan_days.dart';
import 'tables/plan_exercise_alternatives.dart';
import 'tables/plan_import_audit.dart';
import 'tables/plan_long_range_week_performance.dart';
import 'tables/plan_long_range_weeks.dart';
import 'tables/plan_prescribed_runs.dart';
import 'tables/plan_prescribed_strength_sets.dart';
import 'tables/plan_summary_snapshots.dart';
import 'tables/prescribed_strength_sets.dart';
import 'tables/rule_triggers.dart';
import 'tables/run_override_audit.dart';
import 'tables/run_segments.dart';
import 'tables/run_session_details.dart';
import 'tables/run_sessions.dart';
import 'tables/sleep_nights.dart';
import 'tables/workout_days.dart';

part 'app_db.g.dart';

class ExerciseSetGroup {
  const ExerciseSetGroup({
    required this.exercise,
    required this.displayExercise,
    required this.prescribed,
    required this.substitution,
    required this.actual,
  });

  final String exercise;
  final String displayExercise;
  final List<PlannedStrengthSetView> prescribed;
  final ExerciseSubstitutionView? substitution;
  final List<ActualStrengthSet> actual;
}

class PlannedStrengthSetView {
  const PlannedStrengthSetView({
    required this.setIndex,
    required this.weight,
    required this.reps,
    required this.rir,
    required this.unit,
  });

  final int setIndex;
  final double? weight;
  final int? reps;
  final int? rir;
  final String unit;
}

class ExerciseSubstitutionView {
  const ExerciseSubstitutionView({
    required this.id,
    required this.prescribedExerciseCanonical,
    required this.substituteExerciseCanonical,
    required this.reasonCode,
    required this.reasonNotes,
    required this.matchScore,
    required this.matchExplanationJson,
    required this.warningAcknowledged,
    required this.selectedAt,
  });

  final String id;
  final String prescribedExerciseCanonical;
  final String substituteExerciseCanonical;
  final String reasonCode;
  final String? reasonNotes;
  final double? matchScore;
  final String? matchExplanationJson;
  final bool warningAcknowledged;
  final int selectedAt;
}

class PrescribedRunPlan {
  const PrescribedRunPlan({
    required this.dayLabel,
    required this.liftFocus,
    required this.runType,
    required this.durationText,
    required this.targetPace,
    required this.effortHrGuardrails,
    required this.notes,
  });

  final String? dayLabel;
  final String? liftFocus;
  final String? runType;
  final String? durationText;
  final String? targetPace;
  final String? effortHrGuardrails;
  final String? notes;
}

class PlanDayDetail {
  const PlanDayDetail({
    required this.cycle,
    required this.day,
    required this.strengthSets,
    required this.prescribedRun,
  });

  final PlanCycle cycle;
  final PlanDay day;
  final List<PlanPrescribedStrengthSet> strengthSets;
  final PlanPrescribedRun? prescribedRun;
}

class StandardWorkbookImportResult {
  const StandardWorkbookImportResult({
    required this.replacedCycle,
    required this.insertedPlanDays,
    required this.insertedStrengthSets,
    required this.insertedRunPlans,
    required this.insertedAlternatives,
    required this.warnings,
    required this.conflictReportPath,
  });

  final bool replacedCycle;
  final int insertedPlanDays;
  final int insertedStrengthSets;
  final int insertedRunPlans;
  final int insertedAlternatives;
  final List<String> warnings;
  final String? conflictReportPath;

  Map<String, dynamic> toJson() => {
        'replaced_cycle': replacedCycle,
        'inserted_plan_days': insertedPlanDays,
        'inserted_strength_sets': insertedStrengthSets,
        'inserted_run_plans': insertedRunPlans,
        'inserted_alternatives': insertedAlternatives,
        'warnings': warnings,
        'conflict_report_path': conflictReportPath,
      };

  String pretty() => const JsonEncoder.withIndent('  ').convert(toJson());
}

class AiWeeklyPlanTextImportResult {
  const AiWeeklyPlanTextImportResult({
    required this.replacedCycle,
    required this.insertedPlanDays,
    required this.insertedStrengthSets,
    required this.insertedRunPlans,
    required this.insertedAlternatives,
    required this.warnings,
  });

  final bool replacedCycle;
  final int insertedPlanDays;
  final int insertedStrengthSets;
  final int insertedRunPlans;
  final int insertedAlternatives;
  final List<String> warnings;

  Map<String, dynamic> toJson() => {
        'replaced_cycle': replacedCycle,
        'inserted_plan_days': insertedPlanDays,
        'inserted_strength_sets': insertedStrengthSets,
        'inserted_run_plans': insertedRunPlans,
        'inserted_alternatives': insertedAlternatives,
        'warnings': warnings,
      };

  String pretty() => const JsonEncoder.withIndent('  ').convert(toJson());
}

class _ParsedSetCell {
  const _ParsedSetCell({
    required this.weight,
    required this.reps,
    required this.rir,
    required this.unit,
    required this.raw,
  });

  final double? weight;
  final int? reps;
  final int? rir;
  final String unit;
  final String raw;
}

class _ParsedDailyPlan {
  const _ParsedDailyPlan({
    required this.dayNumber,
    required this.sheetName,
    required this.estimatedDate,
    required this.sessionType,
    required this.dayLabel,
    required this.liftFocus,
    required this.runType,
    required this.durationText,
    required this.targetPace,
    required this.effortHrGuardrails,
    required this.notes,
    required this.strengthRows,
    required this.alternatives,
    required this.rawRows,
  });

  final int dayNumber;
  final String sheetName;
  final String? estimatedDate;
  final String sessionType;
  final String? dayLabel;
  final String? liftFocus;
  final String? runType;
  final String? durationText;
  final String? targetPace;
  final String? effortHrGuardrails;
  final String? notes;
  final List<_ParsedPlannedStrengthRow> strengthRows;
  final List<_AiParsedPlanAlternative> alternatives;
  final List<List<dynamic>> rawRows;
}

class _ParsedPlannedStrengthRow {
  const _ParsedPlannedStrengthRow({
    required this.exerciseCanonical,
    required this.setIndex,
    required this.weight,
    required this.reps,
    required this.rir,
    required this.unit,
    required this.rawSetString,
  });

  final String exerciseCanonical;
  final int setIndex;
  final double? weight;
  final int? reps;
  final int? rir;
  final String unit;
  final String rawSetString;
}

class _AiParsedPlanAlternative {
  const _AiParsedPlanAlternative({
    required this.prescribedExerciseCanonical,
    required this.alternativeExerciseCanonical,
    required this.rank,
    required this.tier,
    required this.rationale,
    required this.notes,
  });

  final String prescribedExerciseCanonical;
  final String alternativeExerciseCanonical;
  final int rank;
  final String tier;
  final String rationale;
  final String? notes;
}

class _StoredAlternativeNoteParts {
  const _StoredAlternativeNoteParts({
    required this.tier,
    required this.rationale,
    required this.notes,
  });

  final String? tier;
  final String? rationale;
  final String? notes;
}

class _AiParsedWeeklyPlanDay {
  const _AiParsedWeeklyPlanDay({
    required this.dayNumber,
    required this.sessionType,
    required this.dayLabel,
    required this.liftFocus,
    required this.runType,
    required this.durationText,
    required this.targetPace,
    required this.effortHrGuardrails,
    required this.notes,
    required this.strengthRows,
    required this.alternatives,
  });

  final int dayNumber;
  final String sessionType;
  final String? dayLabel;
  final String? liftFocus;
  final String? runType;
  final String? durationText;
  final String? targetPace;
  final String? effortHrGuardrails;
  final String? notes;
  final List<_ParsedPlannedStrengthRow> strengthRows;
  final List<_AiParsedPlanAlternative> alternatives;
}

class _AiParsedWeeklyPlan {
  const _AiParsedWeeklyPlan({
    required this.weekStart,
    required this.weekEnd,
    required this.days,
  });

  final String weekStart;
  final String weekEnd;
  final List<_AiParsedWeeklyPlanDay> days;
}

class _AiParsedTenWeekPlanRow {
  const _AiParsedTenWeekPlanRow({
    required this.weekLabel,
    required this.weekStart,
    required this.weekEnd,
    required this.runFocus,
    required this.strengthFocus,
    required this.strengthProgressionExpectation,
    required this.primaryProgressionTarget,
    required this.recoveryEmphasis,
    required this.deload,
    required this.notes,
  });

  final String weekLabel;
  final String weekStart;
  final String weekEnd;
  final String runFocus;
  final String strengthFocus;
  final String strengthProgressionExpectation;
  final String primaryProgressionTarget;
  final String recoveryEmphasis;
  final bool deload;
  final String? notes;
}

class _AiParsedPlanImportBundle {
  const _AiParsedPlanImportBundle({
    required this.weeklyPlan,
    required this.tenWeekRows,
  });

  final _AiParsedWeeklyPlan weeklyPlan;
  final List<_AiParsedTenWeekPlanRow> tenWeekRows;
}

class _LongRangePlanWeekUpsertInput {
  const _LongRangePlanWeekUpsertInput({
    required this.weekLabel,
    required this.weekNumber,
    required this.weekStart,
    required this.weekEnd,
    required this.runFocus,
    required this.strengthFocus,
    required this.strengthProgressionExpectation,
    required this.primaryProgressionTarget,
    required this.recoveryEmphasis,
    required this.deload,
    required this.notes,
  });

  final String weekLabel;
  final int? weekNumber;
  final String weekStart;
  final String weekEnd;
  final String? runFocus;
  final String? strengthFocus;
  final String? strengthProgressionExpectation;
  final String? primaryProgressionTarget;
  final String? recoveryEmphasis;
  final bool deload;
  final String? notes;
}

class _StrengthProgressionEvaluationResult {
  const _StrengthProgressionEvaluationResult({
    required this.evaluation,
    required this.expectation,
    required this.comparedSetCount,
    required this.metSetCount,
    required this.exceededSetCount,
    required this.underSetCount,
    required this.averageScore,
    required this.expectedSetCount,
    required this.matchedSetCount,
  });

  final String? evaluation; // under | met | exceeded | insufficient_data
  final String? expectation;
  final int comparedSetCount;
  final int metSetCount;
  final int exceededSetCount;
  final int underSetCount;
  final double? averageScore;
  final int expectedSetCount;
  final int matchedSetCount;
}

class _AiParsedWeeklyPlanDayBuilder {
  _AiParsedWeeklyPlanDayBuilder(this.dayNumber);

  final int dayNumber;
  String? sessionType;
  String? dayLabel;
  String? liftFocus;
  String? runType;
  String? durationText;
  String? targetPace;
  String? effortHrGuardrails;
  String? notes;
  final List<_ParsedPlannedStrengthRow> strengthRows =
      <_ParsedPlannedStrengthRow>[];
  final List<_AiParsedPlanAlternative> alternatives =
      <_AiParsedPlanAlternative>[];

  _AiParsedWeeklyPlanDay build(AppDb db) {
    final normalizedSessionType = db._normalizeSessionType(sessionType);
    return _AiParsedWeeklyPlanDay(
      dayNumber: dayNumber,
      sessionType: normalizedSessionType,
      dayLabel: dayLabel,
      liftFocus: liftFocus,
      runType: runType,
      durationText: durationText,
      targetPace: targetPace,
      effortHrGuardrails: effortHrGuardrails,
      notes: notes,
      strengthRows: List<_ParsedPlannedStrengthRow>.unmodifiable(strengthRows),
      alternatives: List<_AiParsedPlanAlternative>.unmodifiable(alternatives),
    );
  }
}

class _PlanDaySnapshot {
  const _PlanDaySnapshot({
    required this.sheetName,
    required this.sessionType,
    required this.strengthSets,
    required this.alternatives,
    required this.runPlan,
  });

  final String sheetName;
  final String sessionType;
  final List<PlanPrescribedStrengthSet> strengthSets;
  final List<PlanExerciseAlternative> alternatives;
  final PlanPrescribedRun? runPlan;
}

class RunSessionWithSegments {
  const RunSessionWithSegments({
    required this.session,
    required this.segments,
    required this.details,
    required this.overrodeManual,
  });

  final RunSession session;
  final List<RunSegment> segments;
  final RunSessionDetail? details;
  final bool overrodeManual;
}

class WorkoutDayDetail {
  const WorkoutDayDetail({
    required this.date,
    required this.workoutDay,
    required this.planCycleId,
    required this.planDayId,
    required this.planDayNumber,
    required this.planSessionType,
    required this.prescribedRun,
    required this.sleepNights,
    required this.runSessions,
    required this.groups,
    required this.ruleTriggers,
    required this.aiAudits,
    required this.runOverrideAudits,
  });

  final String date;
  final WorkoutDay? workoutDay;
  final String? planCycleId;
  final String? planDayId;
  final int? planDayNumber;
  final String? planSessionType;
  final PrescribedRunPlan? prescribedRun;
  final List<SleepNight> sleepNights;
  final List<RunSessionWithSegments> runSessions;
  final List<ExerciseSetGroup> groups;
  final List<RuleTrigger> ruleTriggers;
  final List<AiAuditData> aiAudits;
  final List<RunOverrideAuditData> runOverrideAudits;
}

class ExerciseAlternativeChoice {
  const ExerciseAlternativeChoice({
    required this.exerciseCanonical,
    required this.priority,
    required this.notes,
  });

  final String exerciseCanonical;
  final int priority;
  final String? notes;
}

class RunUpsertOutcome {
  const RunUpsertOutcome({
    required this.runSessionId,
    required this.inserted,
    required this.updated,
    required this.overriddenManual,
    required this.preservedGarmin,
  });

  final String runSessionId;
  final bool inserted;
  final bool updated;
  final bool overriddenManual;
  final bool preservedGarmin;
}

class ManualRunSegmentInput {
  const ManualRunSegmentInput({
    required this.idx,
    required this.durationS,
    required this.distanceM,
    required this.kind,
    required this.speedMps,
  });

  final int idx;
  final int durationS;
  final double distanceM;
  final String kind;
  final double? speedMps;

  Map<String, dynamic> toJson() => {
        'idx': idx,
        'duration_s': durationS,
        'distance_m': distanceM,
        'kind': kind,
        'speed_mps': speedMps,
      };
}

@DriftDatabase(
  tables: [
    WorkoutDays,
    ActualStrengthSets,
    PrescribedStrengthSets,
    AppPromptTemplates,
    SleepNights,
    RunSessions,
    RunSegments,
    RunSessionDetails,
    RunOverrideAudit,
    RuleTriggers,
    AiAudit,
    ExerciseSubstitutions,
    PlanCycles,
    PlanDays,
    PlanExerciseAlternatives,
    PlanPrescribedStrengthSets,
    PlanPrescribedRuns,
    PlanLongRangeWeeks,
    PlanLongRangeWeekPerformance,
    PlanSummarySnapshots,
    PlanImportAudit,
    CloudWorkspaces,
    CloudWorkspaceMemberships,
    CloudAthleteProfiles,
    CloudAthleteProfileAssignments,
    CloudWorkspaceInvites,
    AppContextState,
  ],
)
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  AppDb.forTesting(super.connection);

  final Uuid _uuid = const Uuid();

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(runSessions, runSessions.runKey);
            await m.addColumn(runSessions, runSessions.maxHr);
            await m.addColumn(runSessions, runSessions.title);
            await m.addColumn(runSessions, runSessions.activityType);
            await m.addColumn(runSessions, runSessions.calories);
            await m.addColumn(runSessions, runSessions.movingTimeS);
            await m.addColumn(runSessions, runSessions.elapsedTimeS);
            await m.addColumn(runSessions, runSessions.sourcePriority);
            await m.addColumn(runSessions, runSessions.importFileName);
            await m.addColumn(runSessions, runSessions.rawMetricsJson);
            await m.createTable(runSessionDetails);
            await m.createTable(runOverrideAudit);
            await _backfillLegacyRunRows();
          }
          if (from < 3) {
            await m.createTable(planCycles);
            await m.createTable(planDays);
            await m.createTable(planPrescribedStrengthSets);
            await m.createTable(planPrescribedRuns);
            await m.createTable(planSummarySnapshots);
            await m.createTable(planImportAudit);
            await m.addColumn(actualStrengthSets, actualStrengthSets.planDayId);
            await m.addColumn(runSessions, runSessions.planDayId);
            await _backfillLegacyPrescribedPlanData();
          }
          if (from >= 3 && from < 4) {
            await m.addColumn(planDays, planDays.sessionType);
          }
          if (from < 4) {
            await _backfillPlanDaySessionTypes();
          }
          if (from < 5) {
            await m.createTable(exerciseSubstitutions);
            await m.createTable(planExerciseAlternatives);
            await m.addColumn(
              actualStrengthSets,
              actualStrengthSets.prescribedExerciseCanonical,
            );
            await m.addColumn(
              actualStrengthSets,
              actualStrengthSets.substitutionId,
            );
            await _backfillActualStrengthPrescribedExerciseCanonical();
          }
          if (from < 6) {
            await m.createTable(appPromptTemplates);
          }
          if (from < 7) {
            await m.createTable(planLongRangeWeeks);
            await m.createTable(planLongRangeWeekPerformance);
          }
          if (from >= 7 && from < 8) {
            await m.addColumn(
              planLongRangeWeeks,
              planLongRangeWeeks.strengthProgressionExpectation,
            );
          }
          if (from >= 8 && from < 9) {
            await m.addColumn(
              planLongRangeWeekPerformance,
              planLongRangeWeekPerformance.strengthProgressionExpectation,
            );
            await m.addColumn(
              planLongRangeWeekPerformance,
              planLongRangeWeekPerformance.strengthProgressionEvaluation,
            );
          }
          if (from < 10) {
            await m.createTable(cloudWorkspaces);
            await m.createTable(cloudWorkspaceMemberships);
            await m.createTable(cloudAthleteProfiles);
            await m.createTable(cloudAthleteProfileAssignments);
            await m.createTable(cloudWorkspaceInvites);
            await m.createTable(appContextState);
          }
        },
        beforeOpen: (details) async {
          await _ensurePlanDaysSessionTypeColumn();
          await _ensureExerciseSubstitutionsTable();
          await _ensurePlanExerciseAlternativesTable();
          await _ensureActualStrengthSetSubstitutionColumns();
          await _ensureAppPromptTemplatesTable();
          await _ensurePlanLongRangeWeeksTable();
          await _ensurePlanLongRangeWeeksColumns();
          await _ensurePlanLongRangeWeekPerformanceTable();
          await _ensurePlanLongRangeWeekPerformanceColumns();
          await _ensureCloudWorkspacesTable();
          await _ensureCloudWorkspaceMembershipsTable();
          await _ensureCloudAthleteProfilesTable();
          await _ensureCloudAthleteProfileAssignmentsTable();
          await _ensureCloudWorkspaceInvitesTable();
          await _ensureAppContextStateTable();
        },
      );

  Future<void> _backfillLegacyRunRows() async {
    final rows = await select(runSessions).get();
    for (final row in rows) {
      final mappedRunKey = row.runKey.isEmpty
          ? _runKeyFromStartMsOrLegacy(row.startTime, row.id)
          : row.runKey;
      final mappedPriority = row.sourcePriority == 0
          ? _sourcePriorityFor(row.source)
          : row.sourcePriority;

      await (update(runSessions)..where((r) => r.id.equals(row.id))).write(
        RunSessionsCompanion(
          runKey: Value(mappedRunKey),
          sourcePriority: Value(mappedPriority),
        ),
      );
    }
  }

  Future<void> _backfillLegacyPrescribedPlanData() async {
    final days = await select(workoutDays).get();
    if (days.isEmpty) {
      return;
    }
    final dayIdToDate = <String, String>{
      for (final day in days) day.id: day.workoutDate,
    };

    final legacyRows = await select(prescribedStrengthSets).get();
    if (legacyRows.isEmpty) {
      return;
    }

    final byWeekStart = <String, List<PrescribedStrengthSet>>{};
    for (final row in legacyRows) {
      final ymd = dayIdToDate[row.workoutDayId];
      if (ymd == null) {
        continue;
      }
      final weekStart = _startOfWeekYmd(ymd);
      final bucket =
          byWeekStart.putIfAbsent(weekStart, () => <PrescribedStrengthSet>[]);
      bucket.add(row);
    }

    for (final entry in byWeekStart.entries) {
      final weekStart = entry.key;
      final weekStartDate = parseYmd(weekStart);
      final weekEnd = toYmd(weekStartDate.add(const Duration(days: 6)));
      final cycleId = _uuid.v4();
      await into(planCycles).insert(
        PlanCyclesCompanion.insert(
          id: cycleId,
          cycleKey: 'legacy_${weekStart.replaceAll('-', '')}',
          weekStart: weekStart,
          weekEnd: weekEnd,
          source: 'legacy_backfill',
          createdAt: unixMsNow(),
        ),
      );

      final planDayIdByNumber = <int, String>{};
      for (var dayNumber = 1; dayNumber <= 7; dayNumber++) {
        final estimated =
            toYmd(weekStartDate.add(Duration(days: dayNumber - 1)));
        final planDayId = _uuid.v4();
        planDayIdByNumber[dayNumber] = planDayId;
        await into(planDays).insert(
          PlanDaysCompanion.insert(
            id: planDayId,
            planCycleId: cycleId,
            dayNumber: dayNumber,
            sheetName: 'Day $dayNumber',
            createdAt: unixMsNow(),
            estimatedDate: Value(estimated),
            sessionType: Value('unknown'),
          ),
        );
      }

      for (final row in entry.value) {
        final ymd = dayIdToDate[row.workoutDayId];
        if (ymd == null) {
          continue;
        }
        final dayNumber = parseYmd(ymd).difference(weekStartDate).inDays + 1;
        final planDayId = planDayIdByNumber[dayNumber];
        if (planDayId == null) {
          continue;
        }
        await into(planPrescribedStrengthSets).insert(
          PlanPrescribedStrengthSetsCompanion.insert(
            id: _uuid.v4(),
            planDayId: planDayId,
            exerciseCanonical: row.exerciseCanonical,
            setIndex: row.setIndex,
            unit: row.unit,
            weight: Value(row.weight),
            reps: Value(row.reps),
            rir: Value(row.rir),
            rawSetString: Value(_rawSetFromFields(
              weight: row.weight,
              reps: row.reps,
              rir: row.rir,
            )),
            createdAt: unixMsNow(),
          ),
        );
      }
    }
  }

  Future<void> _backfillPlanDaySessionTypes() async {
    final rows = await select(planDays).get();
    for (final row in rows) {
      if (row.sessionType != null && row.sessionType!.trim().isNotEmpty) {
        continue;
      }
      await (update(planDays)..where((d) => d.id.equals(row.id))).write(
        PlanDaysCompanion(
          sessionType: Value(
            _deriveSessionType(sheetName: row.sheetName),
          ),
        ),
      );
    }
  }

  Future<void> _ensurePlanDaysSessionTypeColumn() async {
    final tableExists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'plan_days' LIMIT 1",
    ).getSingleOrNull();
    if (tableExists == null) {
      return;
    }

    final columns = await customSelect('PRAGMA table_info(plan_days)').get();
    final hasSessionType = columns.any(
      (row) =>
          (row.data['name']?.toString().toLowerCase() ?? '') == 'session_type',
    );
    if (hasSessionType) {
      return;
    }

    await customStatement('ALTER TABLE plan_days ADD COLUMN session_type TEXT');
    await _backfillPlanDaySessionTypes();
  }

  Future<void> _backfillActualStrengthPrescribedExerciseCanonical() async {
    final rows = await select(actualStrengthSets).get();
    for (final row in rows) {
      final existing = row.prescribedExerciseCanonical;
      if (existing != null && existing.trim().isNotEmpty) {
        continue;
      }
      await (update(actualStrengthSets)..where((t) => t.id.equals(row.id)))
          .write(
        ActualStrengthSetsCompanion(
          prescribedExerciseCanonical: Value(row.exerciseCanonical),
        ),
      );
    }
  }

  Future<void> _ensureExerciseSubstitutionsTable() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'exercise_substitutions' LIMIT 1",
    ).getSingleOrNull();
    if (exists != null) {
      return;
    }
    await customStatement('''
      CREATE TABLE exercise_substitutions (
        id TEXT NOT NULL PRIMARY KEY,
        workout_day_id TEXT NOT NULL,
        plan_day_id TEXT NULL,
        prescribed_exercise_canonical TEXT NOT NULL,
        substitute_exercise_canonical TEXT NOT NULL,
        reason_code TEXT NOT NULL,
        reason_notes TEXT NULL,
        selected_at INTEGER NOT NULL,
        selected_by TEXT NULL,
        match_score REAL NULL,
        match_explanation_json TEXT NULL,
        warning_acknowledged INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        UNIQUE(workout_day_id, prescribed_exercise_canonical)
      )
    ''');
  }

  Future<void> _ensurePlanExerciseAlternativesTable() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'plan_exercise_alternatives' LIMIT 1",
    ).getSingleOrNull();
    if (exists != null) {
      return;
    }
    await customStatement('''
      CREATE TABLE plan_exercise_alternatives (
        id TEXT NOT NULL PRIMARY KEY,
        plan_day_id TEXT NULL,
        prescribed_exercise_canonical TEXT NOT NULL,
        alternative_exercise_canonical TEXT NOT NULL,
        priority INTEGER NOT NULL DEFAULT 0,
        notes TEXT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _ensureActualStrengthSetSubstitutionColumns() async {
    final tableExists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'actual_strength_sets' LIMIT 1",
    ).getSingleOrNull();
    if (tableExists == null) {
      return;
    }
    final columns =
        await customSelect('PRAGMA table_info(actual_strength_sets)').get();
    final hasPrescribed = columns.any(
      (r) =>
          (r.data['name']?.toString().toLowerCase() ?? '') ==
          'prescribed_exercise_canonical',
    );
    final hasSubId = columns.any(
      (r) =>
          (r.data['name']?.toString().toLowerCase() ?? '') == 'substitution_id',
    );
    if (!hasPrescribed) {
      await customStatement(
        'ALTER TABLE actual_strength_sets ADD COLUMN prescribed_exercise_canonical TEXT',
      );
    }
    if (!hasSubId) {
      await customStatement(
        'ALTER TABLE actual_strength_sets ADD COLUMN substitution_id TEXT',
      );
    }
    await _backfillActualStrengthPrescribedExerciseCanonical();
  }

  Future<void> _ensureAppPromptTemplatesTable() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'app_prompt_templates' LIMIT 1",
    ).getSingleOrNull();
    if (exists != null) {
      return;
    }
    await customStatement('''
      CREATE TABLE app_prompt_templates (
        template_key TEXT NOT NULL PRIMARY KEY,
        template_text TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'user_override',
        version_tag TEXT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _ensurePlanLongRangeWeeksTable() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'plan_long_range_weeks' LIMIT 1",
    ).getSingleOrNull();
    if (exists != null) {
      return;
    }
    await customStatement('''
      CREATE TABLE plan_long_range_weeks (
        id TEXT NOT NULL PRIMARY KEY,
        week_label TEXT NOT NULL,
        week_number INTEGER NULL,
        week_start TEXT NOT NULL,
        week_end TEXT NOT NULL,
        run_focus TEXT NULL,
        strength_focus TEXT NULL,
        strength_progression_expectation TEXT NULL,
        primary_progression_target TEXT NULL,
        recovery_emphasis TEXT NULL,
        deload INTEGER NOT NULL DEFAULT 0,
        notes TEXT NULL,
        source TEXT NOT NULL,
        last_plan_cycle_id TEXT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _ensurePlanLongRangeWeeksColumns() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'plan_long_range_weeks' LIMIT 1",
    ).getSingleOrNull();
    if (exists == null) {
      return;
    }
    final columns =
        await customSelect('PRAGMA table_info(plan_long_range_weeks)').get();
    final hasStrengthExpectation = columns.any(
      (r) =>
          (r.data['name']?.toString().toLowerCase() ?? '') ==
          'strength_progression_expectation',
    );
    if (!hasStrengthExpectation) {
      await customStatement(
        'ALTER TABLE plan_long_range_weeks ADD COLUMN strength_progression_expectation TEXT',
      );
    }
  }

  Future<void> _ensurePlanLongRangeWeekPerformanceTable() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'plan_long_range_week_performance' LIMIT 1",
    ).getSingleOrNull();
    if (exists != null) {
      return;
    }
    await customStatement('''
      CREATE TABLE plan_long_range_week_performance (
        id TEXT NOT NULL PRIMARY KEY,
        plan_long_range_week_id TEXT NULL,
        week_label TEXT NULL,
        week_number INTEGER NULL,
        week_start TEXT NOT NULL,
        week_end TEXT NOT NULL,
        evaluated_plan_cycle_id TEXT NULL,
        evaluation_source TEXT NOT NULL,
        planned_day_count INTEGER NOT NULL,
        completed_plan_days INTEGER NOT NULL,
        planned_run_days INTEGER NOT NULL,
        actual_run_days INTEGER NOT NULL,
        planned_run_sessions INTEGER NOT NULL,
        actual_run_sessions INTEGER NOT NULL,
        planned_strength_exercises INTEGER NOT NULL,
        actual_strength_exercises INTEGER NOT NULL,
        planned_strength_sets INTEGER NOT NULL,
        actual_strength_sets INTEGER NOT NULL,
        strength_progression_expectation TEXT NULL,
        strength_progression_evaluation TEXT NULL,
        actual_run_distance_m REAL NULL,
        actual_run_duration_s INTEGER NULL,
        metrics_json TEXT NULL,
        captured_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _ensurePlanLongRangeWeekPerformanceColumns() async {
    final cols = await customSelect(
      'PRAGMA table_info(plan_long_range_week_performance)',
    ).get();
    if (cols.isEmpty) {
      return;
    }
    final names = cols
        .map((r) => (r.data['name'] ?? '').toString().trim().toLowerCase())
        .toSet();
    if (!names.contains('strength_progression_expectation')) {
      await customStatement(
        'ALTER TABLE plan_long_range_week_performance '
        'ADD COLUMN strength_progression_expectation TEXT',
      );
    }
    if (!names.contains('strength_progression_evaluation')) {
      await customStatement(
        'ALTER TABLE plan_long_range_week_performance '
        'ADD COLUMN strength_progression_evaluation TEXT',
      );
    }
  }

  Future<void> _ensureCloudWorkspacesTable() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'cloud_workspaces' LIMIT 1",
    ).getSingleOrNull();
    if (exists != null) {
      return;
    }
    await customStatement('''
      CREATE TABLE cloud_workspaces (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        created_by_user_id TEXT NOT NULL
      )
    ''');
  }

  Future<void> _ensureCloudWorkspaceMembershipsTable() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'cloud_workspace_memberships' LIMIT 1",
    ).getSingleOrNull();
    if (exists != null) {
      return;
    }
    await customStatement('''
      CREATE TABLE cloud_workspace_memberships (
        id TEXT NOT NULL PRIMARY KEY,
        workspace_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_email TEXT NOT NULL,
        display_name TEXT NULL,
        role TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        created_by_user_id TEXT NOT NULL
      )
    ''');
  }

  Future<void> _ensureCloudAthleteProfilesTable() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'cloud_athlete_profiles' LIMIT 1",
    ).getSingleOrNull();
    if (exists != null) {
      return;
    }
    await customStatement('''
      CREATE TABLE cloud_athlete_profiles (
        id TEXT NOT NULL PRIMARY KEY,
        workspace_id TEXT NOT NULL,
        name TEXT NOT NULL,
        date_of_birth TEXT NULL,
        notes TEXT NULL,
        created_at INTEGER NOT NULL,
        created_by_user_id TEXT NOT NULL
      )
    ''');
  }

  Future<void> _ensureCloudAthleteProfileAssignmentsTable() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'cloud_athlete_profile_assignments' LIMIT 1",
    ).getSingleOrNull();
    if (exists != null) {
      return;
    }
    await customStatement('''
      CREATE TABLE cloud_athlete_profile_assignments (
        id TEXT NOT NULL PRIMARY KEY,
        workspace_id TEXT NOT NULL,
        athlete_profile_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        can_view INTEGER NOT NULL DEFAULT 1,
        can_edit INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        created_by_user_id TEXT NOT NULL
      )
    ''');
  }

  Future<void> _ensureCloudWorkspaceInvitesTable() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'cloud_workspace_invites' LIMIT 1",
    ).getSingleOrNull();
    if (exists != null) {
      return;
    }
    await customStatement('''
      CREATE TABLE cloud_workspace_invites (
        id TEXT NOT NULL PRIMARY KEY,
        workspace_id TEXT NOT NULL,
        email TEXT NOT NULL,
        role TEXT NOT NULL,
        display_name TEXT NULL,
        expires_at INTEGER NOT NULL,
        status TEXT NOT NULL,
        assigned_profile_ids_json TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        created_by_user_id TEXT NOT NULL
      )
    ''');
  }

  Future<void> _ensureAppContextStateTable() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'app_context_state' LIMIT 1",
    ).getSingleOrNull();
    if (exists != null) {
      return;
    }
    await customStatement('''
      CREATE TABLE app_context_state (
        id TEXT NOT NULL PRIMARY KEY DEFAULT 'default',
        active_workspace_id TEXT NULL,
        active_profile_id TEXT NULL,
        active_role TEXT NULL,
        last_auth_user_id TEXT NULL,
        needs_cloud_claim INTEGER NOT NULL DEFAULT 0,
        pending_invite_token TEXT NULL,
        updated_at INTEGER NULL
      )
    ''');
    await customStatement(
        "INSERT OR IGNORE INTO app_context_state(id) VALUES ('default')");
  }

  String _startOfWeekYmd(String ymd) {
    final date = parseYmd(ymd);
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return toYmd(monday);
  }

  String _runKeyFromStartMsOrLegacy(int? startTimeMs, String id) {
    if (startTimeMs == null) {
      return 'legacy_$id';
    }
    return GarminCsvImportService.runKeyFromDateTime(
      DateTime.fromMillisecondsSinceEpoch(startTimeMs),
    );
  }

  int _sourcePriorityFor(String source) {
    final normalized = source.toLowerCase();
    if (normalized.contains('garmin') || normalized.contains('import')) {
      return 100;
    }
    if (normalized.contains('manual')) {
      return 10;
    }
    return 0;
  }

  static const List<String> _skipSessionTypes = <String>[
    'push',
    'pull',
    'legs',
  ];

  String _normalizeSessionType(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized.contains('rest')) {
      return 'rest';
    }
    if (normalized.contains('push')) {
      return 'push';
    }
    if (normalized.contains('pull')) {
      return 'pull';
    }
    if (normalized.contains('leg')) {
      return 'legs';
    }
    if (_skipSessionTypes.contains(normalized)) {
      return normalized;
    }
    return 'unknown';
  }

  String _sessionTypeLabel(String? value) {
    switch (_normalizeSessionType(value)) {
      case 'push':
        return 'Push';
      case 'pull':
        return 'Pull';
      case 'legs':
        return 'Legs';
      case 'rest':
        return 'Rest';
      default:
        return 'Unknown';
    }
  }

  String _inferSessionTypeFromPlannedSets(
    List<PlanPrescribedStrengthSet> plannedSets,
  ) {
    if (plannedSets.isEmpty) {
      return 'unknown';
    }
    var push = 0;
    var pull = 0;
    var legs = 0;
    for (final row in plannedSets) {
      final ex = row.exerciseCanonical.toLowerCase();
      if (ex.contains('core:') ||
          ex.contains('plank') ||
          ex.contains('dead_bug')) {
        continue;
      }
      if (ex.contains('squat') ||
          ex.contains('rdl') ||
          ex.contains('deadlift') ||
          ex.contains('leg_extension') ||
          ex.contains('leg extension') ||
          ex.contains('hamstring') ||
          ex.contains('calf') ||
          ex.contains('lunge') ||
          ex.contains('split_squat') ||
          ex.contains('leg_press') ||
          ex.contains('leg press')) {
        legs++;
      }
      if (ex.contains('pull') ||
          ex.contains('row') ||
          ex.contains('lat') ||
          ex.contains('curl') ||
          ex.contains('rear_delt')) {
        pull++;
      }
      if (ex.contains('bench') ||
          ex.contains('press') ||
          ex.contains('fly') ||
          ex.contains('triceps') ||
          ex.contains('lateral_raise') ||
          ex.contains('lateral raise')) {
        push++;
      }
    }
    final maxScore = [push, pull, legs].reduce((a, b) => a > b ? a : b);
    if (maxScore < 2) {
      return 'unknown';
    }
    final winners = <String>[
      if (push == maxScore) 'push',
      if (pull == maxScore) 'pull',
      if (legs == maxScore) 'legs',
    ];
    return winners.length == 1 ? winners.first : 'unknown';
  }

  String _resolveDisplaySessionType({
    required String? storedSessionType,
    required List<PlanPrescribedStrengthSet> plannedSets,
  }) {
    final normalizedStored = _normalizeSessionType(storedSessionType);
    final inferred = _inferSessionTypeFromPlannedSets(plannedSets);
    if (inferred == 'unknown') {
      return normalizedStored;
    }
    if (normalizedStored == 'unknown' || normalizedStored == 'rest') {
      return inferred;
    }
    // Correct obvious mismatches from imported/mislabeled workbook summaries.
    if (_skipSessionTypes.contains(normalizedStored) &&
        normalizedStored != inferred) {
      return inferred;
    }
    return normalizedStored;
  }

  String _deriveSessionType({
    required String sheetName,
    String? dayLabel,
    String? liftFocus,
    String? summarySession,
  }) {
    final sheetDerived = _normalizeSessionType(sheetName);
    if (sheetDerived != 'unknown') {
      return sheetDerived;
    }
    final summaryDerived = _normalizeSessionType(summarySession);
    if (summaryDerived != 'unknown') {
      return summaryDerived;
    }
    final labelDerived = _normalizeSessionType(dayLabel);
    if (labelDerived != 'unknown') {
      return labelDerived;
    }
    final liftDerived = _normalizeSessionType(liftFocus);
    if (liftDerived != 'unknown') {
      return liftDerived;
    }
    return 'unknown';
  }

  String _sheetNameForDay({
    required int dayNumber,
    required String sessionType,
    required String fallbackSheetName,
  }) {
    final normalized = _normalizeSessionType(sessionType);
    final label = _sessionTypeLabel(normalized);
    if (normalized == 'unknown') {
      return fallbackSheetName.trim().isEmpty
          ? 'Day $dayNumber'
          : fallbackSheetName;
    }
    return 'Day $dayNumber - $label';
  }

  Future<String> createOrGetWorkoutDayByDate(String dateString) async {
    final existing = await (select(workoutDays)
          ..where((d) => d.workoutDate.equals(dateString)))
        .getSingleOrNull();
    if (existing != null) {
      return existing.id;
    }

    final id = _uuid.v4();
    await into(workoutDays).insert(
      WorkoutDaysCompanion.insert(
        id: id,
        workoutDate: dateString,
        createdAt: unixMsNow(),
      ),
    );
    return id;
  }

  Future<PlanCycle?> getActivePlanCycleForDate(String ymd) async {
    final dayRows = await (select(planDays)
          ..where((d) => d.estimatedDate.equals(ymd))
          ..orderBy([
            (d) =>
                OrderingTerm(expression: d.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
    if (dayRows.isNotEmpty) {
      final cycleIds = dayRows.map((d) => d.planCycleId).toSet().toList();
      final cycles = await (select(planCycles)
            ..where((c) => c.id.isIn(cycleIds))
            ..orderBy([
              (c) =>
                  OrderingTerm(expression: c.createdAt, mode: OrderingMode.desc)
            ]))
          .get();
      if (cycles.isNotEmpty) {
        return cycles.first;
      }
    }

    final overlappingCycles = await (select(planCycles)
          ..where((c) => c.weekStart.isSmallerOrEqualValue(ymd))
          ..where((c) => c.weekEnd.isBiggerOrEqualValue(ymd))
          ..orderBy([
            (c) =>
                OrderingTerm(expression: c.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
    return overlappingCycles.isEmpty ? null : overlappingCycles.first;
  }

  Future<List<PlanCycle>> findOverlappingPlanCycles({
    required String rangeStartYmd,
    required String rangeEndYmd,
  }) {
    return (select(planCycles)
          ..where((c) => c.weekStart.isSmallerOrEqualValue(rangeEndYmd))
          ..where((c) => c.weekEnd.isBiggerOrEqualValue(rangeStartYmd))
          ..orderBy([
            (c) =>
                OrderingTerm(expression: c.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<PlanDay?> _getLatestPlanDayByEstimatedDate(String ymd) async {
    final days = await (select(planDays)
          ..where((d) => d.estimatedDate.equals(ymd))
          ..orderBy([
            (d) =>
                OrderingTerm(expression: d.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
    if (days.isEmpty) {
      return null;
    }
    final byCycle = <String, PlanDay>{};
    for (final day in days) {
      byCycle.putIfAbsent(day.planCycleId, () => day);
    }
    final cycleIds = byCycle.keys.toList();
    final cycles = await (select(planCycles)
          ..where((c) => c.id.isIn(cycleIds))
          ..orderBy([
            (c) =>
                OrderingTerm(expression: c.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
    if (cycles.isEmpty) {
      return days.first;
    }
    return byCycle[cycles.first.id] ?? days.first;
  }

  Future<bool> _planDayHasPrescribedContent(String planDayId) async {
    final hasStrengthSets = await (select(planPrescribedStrengthSets)
          ..where((s) => s.planDayId.equals(planDayId))
          ..limit(1))
        .getSingleOrNull();
    if (hasStrengthSets != null) {
      return true;
    }
    final hasRun = await (select(planPrescribedRuns)
          ..where((r) => r.planDayId.equals(planDayId))
          ..limit(1))
        .getSingleOrNull();
    return hasRun != null;
  }

  Future<PlanDay?> _getPreferredPlanDayByEstimatedDate(String ymd) async {
    final latest = await _getLatestPlanDayByEstimatedDate(ymd);
    if (latest == null) {
      return null;
    }

    final sessionType = (latest.sessionType ?? '').trim().toLowerCase();
    if (sessionType.contains('rest')) {
      return latest;
    }
    if (await _planDayHasPrescribedContent(latest.id)) {
      return latest;
    }

    final days = await (select(planDays)
          ..where((d) => d.estimatedDate.equals(ymd))
          ..orderBy([
            (d) =>
                OrderingTerm(expression: d.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
    for (final candidate in days) {
      if (candidate.id == latest.id) {
        continue;
      }
      final candidateSession =
          (candidate.sessionType ?? '').trim().toLowerCase();
      if (candidateSession.contains('rest')) {
        continue;
      }
      if (await _planDayHasPrescribedContent(candidate.id)) {
        return candidate;
      }
    }

    return latest;
  }

  Future<PlanDayDetail?> getPlanDayDetail({
    required String planCycleId,
    required int dayNumber,
  }) async {
    final cycle = await (select(planCycles)
          ..where((c) => c.id.equals(planCycleId)))
        .getSingleOrNull();
    if (cycle == null) {
      return null;
    }
    final day = await (select(planDays)
          ..where((d) => d.planCycleId.equals(planCycleId))
          ..where((d) => d.dayNumber.equals(dayNumber)))
        .getSingleOrNull();
    if (day == null) {
      return null;
    }
    final sets = await (select(planPrescribedStrengthSets)
          ..where((s) => s.planDayId.equals(day.id))
          ..orderBy([(s) => OrderingTerm.asc(s.setIndex)]))
        .get();
    final run = await (select(planPrescribedRuns)
          ..where((r) => r.planDayId.equals(day.id)))
        .getSingleOrNull();
    return PlanDayDetail(
      cycle: cycle,
      day: day,
      strengthSets: sets,
      prescribedRun: run,
    );
  }

  Future<List<String>> getAvailableSkipDayTypesForDate(String dateYmd) async {
    final cycle = await getActivePlanCycleForDate(dateYmd);
    if (cycle == null) {
      return const <String>[];
    }
    final days = await (select(planDays)
          ..where((d) => d.planCycleId.equals(cycle.id))
          ..orderBy([(d) => OrderingTerm.asc(d.dayNumber)]))
        .get();
    if (days.isEmpty) {
      return const <String>[];
    }

    var selectedIndex = days.indexWhere((d) => d.estimatedDate == dateYmd);
    if (selectedIndex == -1) {
      final byOffset =
          parseYmd(dateYmd).difference(parseYmd(cycle.weekStart)).inDays;
      if (byOffset < 0 || byOffset >= days.length) {
        return const <String>[];
      }
      selectedIndex = byOffset;
    }

    final available = <String>{};
    for (var i = selectedIndex + 1; i < days.length; i++) {
      final type =
          _normalizeSessionType(days[i].sessionType ?? days[i].sheetName);
      if (_skipSessionTypes.contains(type)) {
        available.add(type);
      }
    }
    return _skipSessionTypes.where(available.contains).toList();
  }

  Future<void> markRestDayAndPushSplit({
    required String dateYmd,
    String? skipSessionType,
  }) async {
    final normalizedSkip =
        skipSessionType == null ? null : _normalizeSessionType(skipSessionType);
    if (normalizedSkip != null && !_skipSessionTypes.contains(normalizedSkip)) {
      throw StateError(
          'Invalid skip day type "$skipSessionType". Expected Push, Pull, or Legs.');
    }

    await transaction(() async {
      final cycle = await getActivePlanCycleForDate(dateYmd);
      if (cycle == null) {
        throw StateError('No active split found for $dateYmd.');
      }

      final days = await (select(planDays)
            ..where((d) => d.planCycleId.equals(cycle.id))
            ..orderBy([(d) => OrderingTerm.asc(d.dayNumber)]))
          .get();
      if (days.isEmpty) {
        throw StateError('Active split has no planned days.');
      }

      var selectedIndex = days.indexWhere((d) => d.estimatedDate == dateYmd);
      if (selectedIndex == -1) {
        final byOffset =
            parseYmd(dateYmd).difference(parseYmd(cycle.weekStart)).inDays;
        if (byOffset < 0 || byOffset >= days.length) {
          throw StateError('$dateYmd is not part of the active split.');
        }
        selectedIndex = byOffset;
      }

      if (selectedIndex >= days.length - 1) {
        throw StateError(
            'Cannot push split from the final day because no future days remain.');
      }

      final selected = days[selectedIndex];
      final selectedType =
          _normalizeSessionType(selected.sessionType ?? selected.sheetName);
      if (selectedType == 'rest') {
        return;
      }

      final dayIds = days.map((d) => d.id).toList();
      final strengthRows = await (select(planPrescribedStrengthSets)
            ..where((s) => s.planDayId.isIn(dayIds)))
          .get();
      final runRows = await (select(planPrescribedRuns)
            ..where((r) => r.planDayId.isIn(dayIds)))
          .get();
      final alternativeRows = await (select(planExerciseAlternatives)
            ..where((a) => a.planDayId.isIn(dayIds)))
          .get();

      final setsByDayId = <String, List<PlanPrescribedStrengthSet>>{};
      for (final row in strengthRows) {
        final bucket = setsByDayId.putIfAbsent(
          row.planDayId,
          () => <PlanPrescribedStrengthSet>[],
        );
        bucket.add(row);
      }
      for (final bucket in setsByDayId.values) {
        bucket.sort((a, b) => a.setIndex.compareTo(b.setIndex));
      }

      final runByDayId = <String, PlanPrescribedRun>{
        for (final row in runRows) row.planDayId: row,
      };
      final alternativesByDayId = <String, List<PlanExerciseAlternative>>{};
      for (final row in alternativeRows) {
        final planDayId = row.planDayId;
        if (planDayId == null) {
          continue;
        }
        alternativesByDayId
            .putIfAbsent(planDayId, () => <PlanExerciseAlternative>[])
            .add(row);
      }

      final snapshots = days
          .map(
            (day) => _PlanDaySnapshot(
              sheetName: day.sheetName,
              sessionType:
                  _normalizeSessionType(day.sessionType ?? day.sheetName),
              strengthSets: List<PlanPrescribedStrengthSet>.from(
                setsByDayId[day.id] ?? const <PlanPrescribedStrengthSet>[],
              ),
              alternatives: List<PlanExerciseAlternative>.from(
                alternativesByDayId[day.id] ??
                    const <PlanExerciseAlternative>[],
              ),
              runPlan: runByDayId[day.id],
            ),
          )
          .toList();

      final restPlaceholder = _PlanDaySnapshot(
        sheetName: selected.sheetName,
        sessionType: 'rest',
        strengthSets: const <PlanPrescribedStrengthSet>[],
        alternatives: const <PlanExerciseAlternative>[],
        runPlan: null,
      );

      final candidates = <_PlanDaySnapshot>[
        snapshots[selectedIndex],
        ...snapshots.skip(selectedIndex + 1),
      ];

      var removeIndex = -1;
      for (var i = 1; i < candidates.length; i++) {
        if (_normalizeSessionType(candidates[i].sessionType) == 'rest') {
          removeIndex = i;
          break;
        }
      }

      if (removeIndex == -1) {
        if (normalizedSkip == null) {
          final available = <String>{};
          for (var i = 1; i < candidates.length; i++) {
            final type = _normalizeSessionType(candidates[i].sessionType);
            if (_skipSessionTypes.contains(type)) {
              available.add(type);
            }
          }
          final ordered = _skipSessionTypes.where(available.contains).toList();
          if (ordered.isEmpty) {
            throw StateError(
                'No future rest day exists and no Push/Pull/Legs day is available to skip.');
          }
          throw StateError(
              'No future rest day exists. Choose a day type to skip: ${ordered.map(_sessionTypeLabel).join(', ')}.');
        }
        for (var i = 1; i < candidates.length; i++) {
          if (_normalizeSessionType(candidates[i].sessionType) ==
              normalizedSkip) {
            removeIndex = i;
            break;
          }
        }
        if (removeIndex == -1) {
          throw StateError(
              'No future ${_sessionTypeLabel(normalizedSkip)} day exists to skip.');
        }
      }

      candidates.removeAt(removeIndex);
      final rebuilt = <_PlanDaySnapshot>[
        ...snapshots.take(selectedIndex),
        restPlaceholder,
        ...candidates,
      ];
      if (rebuilt.length != days.length) {
        throw StateError('Split push failed due to an internal mapping error.');
      }

      final splitStart = parseYmd(cycle.weekStart);
      for (var i = 0; i < days.length; i++) {
        final targetDay = days[i];
        final source = rebuilt[i];
        final sessionType = _normalizeSessionType(source.sessionType);

        await (update(planDays)..where((d) => d.id.equals(targetDay.id))).write(
          PlanDaysCompanion(
            dayNumber: Value(i + 1),
            estimatedDate: Value(toYmd(splitStart.add(Duration(days: i)))),
            sessionType: Value(sessionType),
            sheetName: Value(
              _sheetNameForDay(
                dayNumber: i + 1,
                sessionType: sessionType,
                fallbackSheetName: source.sheetName,
              ),
            ),
          ),
        );

        await (delete(planPrescribedStrengthSets)
              ..where((s) => s.planDayId.equals(targetDay.id)))
            .go();
        await (delete(planPrescribedRuns)
              ..where((r) => r.planDayId.equals(targetDay.id)))
            .go();
        await (delete(planExerciseAlternatives)
              ..where((a) => a.planDayId.equals(targetDay.id)))
            .go();

        for (final set in source.strengthSets) {
          await into(planPrescribedStrengthSets).insert(
            PlanPrescribedStrengthSetsCompanion.insert(
              id: _uuid.v4(),
              planDayId: targetDay.id,
              exerciseCanonical: set.exerciseCanonical,
              setIndex: set.setIndex,
              unit: set.unit,
              weight: Value(set.weight),
              reps: Value(set.reps),
              rir: Value(set.rir),
              rawSetString: Value(set.rawSetString),
              createdAt: unixMsNow(),
            ),
          );
        }

        final run = source.runPlan;
        if (run != null) {
          await into(planPrescribedRuns).insert(
            PlanPrescribedRunsCompanion.insert(
              id: _uuid.v4(),
              planDayId: targetDay.id,
              dayLabel: Value(run.dayLabel),
              liftFocus: Value(run.liftFocus),
              runType: Value(run.runType),
              durationText: Value(run.durationText),
              targetPace: Value(run.targetPace),
              effortHrGuardrails: Value(run.effortHrGuardrails),
              notes: Value(run.notes),
              createdAt: unixMsNow(),
            ),
          );
        }
        for (final alt in source.alternatives) {
          await upsertPlanExerciseAlternative(
            planDayId: targetDay.id,
            prescribedExerciseCanonical: alt.prescribedExerciseCanonical,
            alternativeExerciseCanonical: alt.alternativeExerciseCanonical,
            priority: alt.priority,
            notes: alt.notes,
          );
          await upsertPlanExerciseAlternative(
            planDayId: null,
            prescribedExerciseCanonical: alt.prescribedExerciseCanonical,
            alternativeExerciseCanonical: alt.alternativeExerciseCanonical,
            priority: alt.priority,
            notes: alt.notes,
          );
        }
      }
    });
  }

  Future<void> undoRestDayAndPullSplit({
    required String dateYmd,
  }) async {
    await transaction(() async {
      final cycle = await getActivePlanCycleForDate(dateYmd);
      if (cycle == null) {
        throw StateError('No active split found for $dateYmd.');
      }

      final days = await (select(planDays)
            ..where((d) => d.planCycleId.equals(cycle.id))
            ..orderBy([(d) => OrderingTerm.asc(d.dayNumber)]))
          .get();
      if (days.isEmpty) {
        throw StateError('Active split has no planned days.');
      }

      var selectedIndex = days.indexWhere((d) => d.estimatedDate == dateYmd);
      if (selectedIndex == -1) {
        final byOffset =
            parseYmd(dateYmd).difference(parseYmd(cycle.weekStart)).inDays;
        if (byOffset < 0 || byOffset >= days.length) {
          throw StateError('$dateYmd is not part of the active split.');
        }
        selectedIndex = byOffset;
      }

      final selected = days[selectedIndex];
      final selectedType =
          _normalizeSessionType(selected.sessionType ?? selected.sheetName);
      if (selectedType != 'rest') {
        throw StateError('Selected day is not currently a rest day.');
      }
      if (selectedIndex >= days.length - 1) {
        throw StateError(
          'Cannot undo rest-day push from the final day because no future training day remains to pull forward.',
        );
      }

      final dayIds = days.map((d) => d.id).toList();
      final strengthRows = await (select(planPrescribedStrengthSets)
            ..where((s) => s.planDayId.isIn(dayIds)))
          .get();
      final runRows = await (select(planPrescribedRuns)
            ..where((r) => r.planDayId.isIn(dayIds)))
          .get();
      final alternativeRows = await (select(planExerciseAlternatives)
            ..where((a) => a.planDayId.isIn(dayIds)))
          .get();

      final setsByDayId = <String, List<PlanPrescribedStrengthSet>>{};
      for (final row in strengthRows) {
        final bucket = setsByDayId.putIfAbsent(
          row.planDayId,
          () => <PlanPrescribedStrengthSet>[],
        );
        bucket.add(row);
      }
      for (final bucket in setsByDayId.values) {
        bucket.sort((a, b) => a.setIndex.compareTo(b.setIndex));
      }

      final runByDayId = <String, PlanPrescribedRun>{
        for (final row in runRows) row.planDayId: row,
      };
      final alternativesByDayId = <String, List<PlanExerciseAlternative>>{};
      for (final row in alternativeRows) {
        final planDayId = row.planDayId;
        if (planDayId == null) {
          continue;
        }
        alternativesByDayId
            .putIfAbsent(planDayId, () => <PlanExerciseAlternative>[])
            .add(row);
      }

      final snapshots = days
          .map(
            (day) => _PlanDaySnapshot(
              sheetName: day.sheetName,
              sessionType:
                  _normalizeSessionType(day.sessionType ?? day.sheetName),
              strengthSets: List<PlanPrescribedStrengthSet>.from(
                setsByDayId[day.id] ?? const <PlanPrescribedStrengthSet>[],
              ),
              alternatives: List<PlanExerciseAlternative>.from(
                alternativesByDayId[day.id] ??
                    const <PlanExerciseAlternative>[],
              ),
              runPlan: runByDayId[day.id],
            ),
          )
          .toList();

      final tail = <_PlanDaySnapshot>[...snapshots.skip(selectedIndex)];
      var pullIndex = -1;
      for (var i = 1; i < tail.length; i++) {
        if (_normalizeSessionType(tail[i].sessionType) != 'rest') {
          pullIndex = i;
          break;
        }
      }
      if (pullIndex == -1) {
        throw StateError(
          'No future training day exists to pull forward into this rest day.',
        );
      }

      final pulled = tail.removeAt(pullIndex);
      // Remove the currently selected rest placeholder at the start of the tail.
      tail.removeAt(0);
      final endRestPlaceholder = _PlanDaySnapshot(
        sheetName: selected.sheetName,
        sessionType: 'rest',
        strengthSets: const <PlanPrescribedStrengthSet>[],
        alternatives: const <PlanExerciseAlternative>[],
        runPlan: null,
      );

      final rebuilt = <_PlanDaySnapshot>[
        ...snapshots.take(selectedIndex),
        pulled,
        ...tail,
        endRestPlaceholder,
      ];
      if (rebuilt.length != days.length) {
        throw StateError(
            'Undo rest-day push failed due to an internal mapping error.');
      }

      final splitStart = parseYmd(cycle.weekStart);
      for (var i = 0; i < days.length; i++) {
        final targetDay = days[i];
        final source = rebuilt[i];
        final sessionType = _normalizeSessionType(source.sessionType);

        await (update(planDays)..where((d) => d.id.equals(targetDay.id))).write(
          PlanDaysCompanion(
            dayNumber: Value(i + 1),
            estimatedDate: Value(toYmd(splitStart.add(Duration(days: i)))),
            sessionType: Value(sessionType),
            sheetName: Value(
              _sheetNameForDay(
                dayNumber: i + 1,
                sessionType: sessionType,
                fallbackSheetName: source.sheetName,
              ),
            ),
          ),
        );

        await (delete(planPrescribedStrengthSets)
              ..where((s) => s.planDayId.equals(targetDay.id)))
            .go();
        await (delete(planPrescribedRuns)
              ..where((r) => r.planDayId.equals(targetDay.id)))
            .go();
        await (delete(planExerciseAlternatives)
              ..where((a) => a.planDayId.equals(targetDay.id)))
            .go();

        for (final set in source.strengthSets) {
          await into(planPrescribedStrengthSets).insert(
            PlanPrescribedStrengthSetsCompanion.insert(
              id: _uuid.v4(),
              planDayId: targetDay.id,
              exerciseCanonical: set.exerciseCanonical,
              setIndex: set.setIndex,
              unit: set.unit,
              weight: Value(set.weight),
              reps: Value(set.reps),
              rir: Value(set.rir),
              rawSetString: Value(set.rawSetString),
              createdAt: unixMsNow(),
            ),
          );
        }

        final run = source.runPlan;
        if (run != null) {
          await into(planPrescribedRuns).insert(
            PlanPrescribedRunsCompanion.insert(
              id: _uuid.v4(),
              planDayId: targetDay.id,
              dayLabel: Value(run.dayLabel),
              liftFocus: Value(run.liftFocus),
              runType: Value(run.runType),
              durationText: Value(run.durationText),
              targetPace: Value(run.targetPace),
              effortHrGuardrails: Value(run.effortHrGuardrails),
              notes: Value(run.notes),
              createdAt: unixMsNow(),
            ),
          );
        }
        for (final alt in source.alternatives) {
          await upsertPlanExerciseAlternative(
            planDayId: targetDay.id,
            prescribedExerciseCanonical: alt.prescribedExerciseCanonical,
            alternativeExerciseCanonical: alt.alternativeExerciseCanonical,
            priority: alt.priority,
            notes: alt.notes,
          );
          await upsertPlanExerciseAlternative(
            planDayId: null,
            prescribedExerciseCanonical: alt.prescribedExerciseCanonical,
            alternativeExerciseCanonical: alt.alternativeExerciseCanonical,
            priority: alt.priority,
            notes: alt.notes,
          );
        }
      }
    });
  }

  Future<String?> _resolvePlanDayIdForWorkoutDayId(String workoutDayId) async {
    final day = await (select(workoutDays)
          ..where((d) => d.id.equals(workoutDayId)))
        .getSingleOrNull();
    if (day == null) {
      return null;
    }
    return _resolvePlanDayIdForDate(day.workoutDate);
  }

  Future<String?> _resolvePlanDayIdForDate(String ymd) async {
    final byEstimatedDate = await _getPreferredPlanDayByEstimatedDate(ymd);
    if (byEstimatedDate != null) {
      return byEstimatedDate.id;
    }

    final cycle = await getActivePlanCycleForDate(ymd);
    if (cycle == null) {
      return null;
    }
    final dayNumber =
        parseYmd(ymd).difference(parseYmd(cycle.weekStart)).inDays + 1;
    if (dayNumber < 1 || dayNumber > 7) {
      return null;
    }
    final planDay = await (select(planDays)
          ..where((d) => d.planCycleId.equals(cycle.id))
          ..where((d) => d.dayNumber.equals(dayNumber)))
        .getSingleOrNull();
    return planDay?.id;
  }

  Future<void> insertActualStrengthSet({
    required String workoutDayId,
    required String exercise,
    required int setIndex,
    required double? weight,
    required int? reps,
    required int? rir,
    required String unit,
    required String source,
    required String? rawSetString,
    int? performedAt,
    String? planDayId,
    String? prescribedExerciseCanonical,
    String? substitutionId,
  }) async {
    final mappedPlanDayId =
        planDayId ?? await _resolvePlanDayIdForWorkoutDayId(workoutDayId);
    final canonicalPerformed = ExerciseNormalizer.normalize(exercise);
    final canonicalPrescribed = ExerciseNormalizer.normalize(
      (prescribedExerciseCanonical ?? exercise),
    );
    await into(actualStrengthSets).insert(
      ActualStrengthSetsCompanion.insert(
        id: _uuid.v4(),
        workoutDayId: workoutDayId,
        planDayId: Value(mappedPlanDayId),
        exerciseCanonical: canonicalPerformed,
        prescribedExerciseCanonical: Value(canonicalPrescribed),
        substitutionId: Value(substitutionId),
        setIndex: setIndex,
        unit: unit,
        source: source,
        createdAt: unixMsNow(),
        weight: Value(weight),
        reps: Value(reps),
        rir: Value(rir),
        rawSetString: Value(rawSetString),
        performedAt: Value(performedAt),
      ),
    );
  }

  Future<void> upsertActualStrengthSetForDate({
    required String dateYmd,
    required String exerciseCanonical,
    required int setIndex,
    required double? weight,
    required int? reps,
    required int? rir,
    int? performedAtMs,
    String source = 'manual_from_prescribed',
    String? rawSetString,
    String? prescribedExerciseCanonical,
    String? substitutionId,
  }) async {
    final workoutDayId = await createOrGetWorkoutDayByDate(dateYmd);
    final mappedPlanDayId = await _resolvePlanDayIdForDate(dateYmd);
    final canonicalExercise = ExerciseNormalizer.normalize(exerciseCanonical);
    final canonicalPrescribed = ExerciseNormalizer.normalize(
      prescribedExerciseCanonical ?? exerciseCanonical,
    );
    final mappedWeight = weight ?? 0.0;
    final now = unixMsNow();
    final normalizedSource =
        source.trim().isEmpty ? 'manual_from_prescribed' : source.trim();
    final rawTrimmed = rawSetString?.trim();
    final resolvedRaw = (rawTrimmed != null && rawTrimmed.isNotEmpty)
        ? rawTrimmed
        : _rawSetFromFields(
            weight: mappedWeight,
            reps: reps,
            rir: rir,
          );

    final existing = await (select(actualStrengthSets)
          ..where((a) => a.workoutDayId.equals(workoutDayId))
          ..where((a) => a.setIndex.equals(setIndex))
          ..where(
              (a) => a.prescribedExerciseCanonical.equals(canonicalPrescribed))
          ..orderBy([
            (a) =>
                OrderingTerm(expression: a.createdAt, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();
    final fallbackExisting = existing ??
        await (select(actualStrengthSets)
              ..where((a) => a.workoutDayId.equals(workoutDayId))
              ..where((a) => a.exerciseCanonical.equals(canonicalExercise))
              ..where((a) => a.setIndex.equals(setIndex))
              ..orderBy([
                (a) => OrderingTerm(
                    expression: a.createdAt, mode: OrderingMode.desc)
              ])
              ..limit(1))
            .getSingleOrNull();

    if (fallbackExisting == null) {
      await into(actualStrengthSets).insert(
        ActualStrengthSetsCompanion.insert(
          id: _uuid.v4(),
          workoutDayId: workoutDayId,
          planDayId: Value(mappedPlanDayId),
          exerciseCanonical: canonicalExercise,
          prescribedExerciseCanonical: Value(canonicalPrescribed),
          substitutionId: Value(substitutionId),
          setIndex: setIndex,
          weight: Value(mappedWeight),
          reps: Value(reps),
          rir: Value(rir),
          unit: 'lb',
          source: normalizedSource,
          rawSetString: Value(resolvedRaw),
          performedAt: Value(performedAtMs ?? now),
          createdAt: now,
        ),
      );
      return;
    }

    await (update(actualStrengthSets)
          ..where((a) => a.id.equals(fallbackExisting.id)))
        .write(
      ActualStrengthSetsCompanion(
        planDayId: Value(mappedPlanDayId),
        exerciseCanonical: Value(canonicalExercise),
        prescribedExerciseCanonical: Value(canonicalPrescribed),
        substitutionId: Value(substitutionId),
        weight: Value(mappedWeight),
        reps: Value(reps),
        rir: Value(rir),
        unit: const Value('lb'),
        source: Value(normalizedSource),
        rawSetString: Value(resolvedRaw),
        performedAt: Value(performedAtMs ?? now),
      ),
    );
  }

  Future<void> upsertExerciseSubstitutionForDate({
    required String dateYmd,
    required String prescribedExerciseCanonical,
    required String substituteExerciseCanonical,
    required String reasonCode,
    String? reasonNotes,
    double? matchScore,
    String? matchExplanationJson,
    bool warningAcknowledged = false,
  }) async {
    final workoutDayId = await createOrGetWorkoutDayByDate(dateYmd);
    final planDayId = await _resolvePlanDayIdForDate(dateYmd);
    final prescribed =
        ExerciseNormalizer.normalize(prescribedExerciseCanonical);
    final substitute =
        ExerciseNormalizer.normalize(substituteExerciseCanonical);
    final existing = await (select(exerciseSubstitutions)
          ..where((t) => t.workoutDayId.equals(workoutDayId))
          ..where((t) => t.prescribedExerciseCanonical.equals(prescribed))
          ..limit(1))
        .getSingleOrNull();
    final now = unixMsNow();
    if (existing == null) {
      await into(exerciseSubstitutions).insert(
        ExerciseSubstitutionsCompanion.insert(
          id: _uuid.v4(),
          workoutDayId: workoutDayId,
          planDayId: Value(planDayId),
          prescribedExerciseCanonical: prescribed,
          substituteExerciseCanonical: substitute,
          reasonCode: reasonCode,
          reasonNotes: Value(
              reasonNotes?.trim().isEmpty ?? true ? null : reasonNotes!.trim()),
          selectedAt: now,
          selectedBy: const Value.absent(),
          matchScore: Value(matchScore),
          matchExplanationJson: Value(matchExplanationJson),
          warningAcknowledged: Value(warningAcknowledged),
          createdAt: now,
        ),
      );
      return;
    }
    await (update(exerciseSubstitutions)
          ..where((t) => t.id.equals(existing.id)))
        .write(
      ExerciseSubstitutionsCompanion(
        planDayId: Value(planDayId),
        substituteExerciseCanonical: Value(substitute),
        reasonCode: Value(reasonCode),
        reasonNotes: Value(
            reasonNotes?.trim().isEmpty ?? true ? null : reasonNotes!.trim()),
        selectedAt: Value(now),
        matchScore: Value(matchScore),
        matchExplanationJson: Value(matchExplanationJson),
        warningAcknowledged: Value(warningAcknowledged),
      ),
    );
  }

  Future<void> clearExerciseSubstitutionForDate({
    required String dateYmd,
    required String prescribedExerciseCanonical,
  }) async {
    final day = await (select(workoutDays)
          ..where((d) => d.workoutDate.equals(dateYmd)))
        .getSingleOrNull();
    if (day == null) {
      return;
    }
    final prescribed =
        ExerciseNormalizer.normalize(prescribedExerciseCanonical);
    await (delete(exerciseSubstitutions)
          ..where((t) => t.workoutDayId.equals(day.id))
          ..where((t) => t.prescribedExerciseCanonical.equals(prescribed)))
        .go();
  }

  Future<List<ExerciseAlternativeChoice>>
      getPlanExerciseAlternativesForPlanDay({
    required String? planDayId,
    required String prescribedExerciseCanonical,
  }) async {
    final prescribed =
        ExerciseNormalizer.normalize(prescribedExerciseCanonical);
    final ordered = <PlanExerciseAlternative>[];

    if (planDayId != null) {
      final planDayRows = await (select(planExerciseAlternatives)
            ..where((t) => t.prescribedExerciseCanonical.equals(prescribed))
            ..where((t) => t.planDayId.equals(planDayId))
            ..orderBy([
              (t) =>
                  OrderingTerm(expression: t.priority, mode: OrderingMode.desc),
              (t) =>
                  OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
            ]))
          .get();
      ordered.addAll(planDayRows);
    }

    final globalRows = await (select(planExerciseAlternatives)
          ..where((t) => t.prescribedExerciseCanonical.equals(prescribed))
          ..where((t) => t.planDayId.isNull())
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.priority, mode: OrderingMode.desc),
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
    ordered.addAll(globalRows);

    final seen = <String>{};
    final output = <ExerciseAlternativeChoice>[];
    for (final r in ordered) {
      final alt = ExerciseNormalizer.normalize(r.alternativeExerciseCanonical);
      if (!seen.add(alt)) {
        continue;
      }
      output.add(
        ExerciseAlternativeChoice(
          exerciseCanonical: alt,
          priority: r.priority,
          notes: r.notes,
        ),
      );
    }
    return output;
  }

  Future<void> upsertPlanExerciseAlternative({
    required String? planDayId,
    required String prescribedExerciseCanonical,
    required String alternativeExerciseCanonical,
    int priority = 0,
    String? notes,
  }) async {
    final prescribed =
        ExerciseNormalizer.normalize(prescribedExerciseCanonical);
    final alternative =
        ExerciseNormalizer.normalize(alternativeExerciseCanonical);
    final existingQuery = select(planExerciseAlternatives)
      ..where((t) => t.prescribedExerciseCanonical.equals(prescribed))
      ..where((t) => t.alternativeExerciseCanonical.equals(alternative))
      ..limit(1);
    if (planDayId == null) {
      existingQuery.where((t) => t.planDayId.isNull());
    } else {
      existingQuery.where((t) => t.planDayId.equals(planDayId));
    }
    final existing = await existingQuery.getSingleOrNull();
    if (existing != null) {
      await (update(planExerciseAlternatives)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        PlanExerciseAlternativesCompanion(
          priority: Value(priority),
          notes: Value(notes),
        ),
      );
      return;
    }
    await into(planExerciseAlternatives).insert(
      PlanExerciseAlternativesCompanion.insert(
        id: _uuid.v4(),
        planDayId: Value(planDayId),
        prescribedExerciseCanonical: prescribed,
        alternativeExerciseCanonical: alternative,
        priority: Value(priority),
        notes: Value(notes),
        createdAt: unixMsNow(),
      ),
    );
  }

  Future<AppPromptTemplate?> getAppPromptTemplateByKey(String templateKey) {
    return (select(appPromptTemplates)
          ..where((t) => t.templateKey.equals(templateKey))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> upsertAppPromptTemplate({
    required String templateKey,
    required String templateText,
    String source = 'user_override',
    String? versionTag,
  }) async {
    final existing = await getAppPromptTemplateByKey(templateKey);
    final companion = AppPromptTemplatesCompanion(
      templateText: Value(templateText),
      source: Value(source),
      versionTag: Value(versionTag),
      updatedAt: Value(unixMsNow()),
    );
    if (existing == null) {
      await into(appPromptTemplates).insert(
        AppPromptTemplatesCompanion.insert(
          templateKey: templateKey,
          templateText: templateText,
          source: Value(source),
          versionTag: Value(versionTag),
          updatedAt: unixMsNow(),
        ),
      );
      return;
    }
    await (update(appPromptTemplates)
          ..where((t) => t.templateKey.equals(templateKey)))
        .write(companion);
  }

  Future<void> deleteAppPromptTemplateByKey(String templateKey) async {
    await (delete(appPromptTemplates)
          ..where((t) => t.templateKey.equals(templateKey)))
        .go();
  }

  Future<void> insertPrescribedStrengthSet({
    required String workoutDayId,
    required String exercise,
    required int setIndex,
    required double? weight,
    required int? reps,
    required int? rir,
    required String unit,
  }) async {
    await into(prescribedStrengthSets).insert(
      PrescribedStrengthSetsCompanion.insert(
        id: _uuid.v4(),
        workoutDayId: workoutDayId,
        exerciseCanonical: exercise,
        setIndex: setIndex,
        unit: unit,
        weight: Value(weight),
        reps: Value(reps),
        rir: Value(rir),
      ),
    );
  }

  Future<void> clearPrescribedSetsForWorkoutDay(String workoutDayId) {
    return (delete(prescribedStrengthSets)
          ..where((p) => p.workoutDayId.equals(workoutDayId)))
        .go();
  }

  Future<RunUpsertOutcome> insertOrUpdateManualRun({
    required String dateString,
    required int startTimeMs,
    required int durationS,
    required double distanceM,
    required double? avgHr,
    required double? maxHr,
    List<ManualRunSegmentInput> manualSegments =
        const <ManualRunSegmentInput>[],
  }) async {
    final sanitizedSegments = _sanitizeManualRunSegments(manualSegments);
    final rawMetricsJson = _manualRunRawMetricsJson(sanitizedSegments);
    final runKey = GarminCsvImportService.runKeyFromDateTime(
      DateTime.fromMillisecondsSinceEpoch(startTimeMs),
    );
    final workoutDayId = await createOrGetWorkoutDayByDate(dateString);
    final mappedPlanDayId = await _resolvePlanDayIdForDate(dateString);
    final endTimeMs = startTimeMs + (durationS * 1000);

    return transaction(() async {
      final existing = await (select(runSessions)
            ..where((r) => r.runKey.equals(runKey)))
          .getSingleOrNull();

      if (existing == null) {
        final id = _uuid.v4();
        await into(runSessions).insert(
          RunSessionsCompanion.insert(
            id: id,
            runKey: Value(runKey),
            workoutDayId: Value(workoutDayId),
            planDayId: Value(mappedPlanDayId),
            startTime: Value(startTimeMs),
            endTime: Value(endTimeMs),
            durationS: Value(durationS),
            distanceM: Value(distanceM),
            avgHr: Value(avgHr),
            maxHr: Value(maxHr),
            treadmill: const Value(false),
            rawMetricsJson: Value(rawMetricsJson),
            source: 'manual',
            sourcePriority: const Value(10),
          ),
        );
        await _replaceRunSegmentsForManualRun(
          runSessionId: id,
          segments: sanitizedSegments,
        );

        return RunUpsertOutcome(
          runSessionId: id,
          inserted: true,
          updated: false,
          overriddenManual: false,
          preservedGarmin: false,
        );
      }

      if (existing.sourcePriority >= 100) {
        return RunUpsertOutcome(
          runSessionId: existing.id,
          inserted: false,
          updated: false,
          overriddenManual: false,
          preservedGarmin: true,
        );
      }

      await (update(runSessions)..where((r) => r.id.equals(existing.id))).write(
        RunSessionsCompanion(
          workoutDayId: Value(workoutDayId),
          planDayId: Value(mappedPlanDayId),
          startTime: Value(startTimeMs),
          endTime: Value(endTimeMs),
          durationS: Value(durationS),
          distanceM: Value(distanceM),
          avgHr: Value(avgHr),
          maxHr: Value(maxHr),
          rawMetricsJson: Value(rawMetricsJson),
          source: const Value('manual'),
          sourcePriority: const Value(10),
        ),
      );
      await _replaceRunSegmentsForManualRun(
        runSessionId: existing.id,
        segments: sanitizedSegments,
      );

      return RunUpsertOutcome(
        runSessionId: existing.id,
        inserted: false,
        updated: true,
        overriddenManual: false,
        preservedGarmin: false,
      );
    });
  }

  Future<RunUpsertOutcome> updateExistingRunFromManualEntry({
    required String runSessionId,
    required String dateString,
    required int startTimeMs,
    required int durationS,
    required double distanceM,
    required double? avgHr,
    required double? maxHr,
    List<ManualRunSegmentInput> manualSegments =
        const <ManualRunSegmentInput>[],
  }) async {
    final sanitizedSegments = _sanitizeManualRunSegments(manualSegments);
    final rawMetricsJson = _manualRunRawMetricsJson(sanitizedSegments);
    final runKey = GarminCsvImportService.runKeyFromDateTime(
      DateTime.fromMillisecondsSinceEpoch(startTimeMs),
    );
    final workoutDayId = await createOrGetWorkoutDayByDate(dateString);
    final mappedPlanDayId = await _resolvePlanDayIdForDate(dateString);
    final endTimeMs = startTimeMs + (durationS * 1000);

    return transaction(() async {
      final existing = await (select(runSessions)
            ..where((r) => r.id.equals(runSessionId)))
          .getSingleOrNull();
      if (existing == null) {
        throw StateError('Run session not found: $runSessionId');
      }

      final conflicting = await (select(runSessions)
            ..where((r) => r.runKey.equals(runKey))
            ..where((r) => r.id.equals(runSessionId).not())
            ..limit(1))
          .getSingleOrNull();
      if (conflicting != null) {
        throw StateError(
          'Another run already exists at that start time. Pick a different start time.',
        );
      }

      final wasHighPriority = existing.sourcePriority >= 100;
      if (wasHighPriority) {
        await insertRunOverrideAudit(
          runKey: existing.runKey,
          workoutDayId: workoutDayId,
          oldSource: existing.source,
          newSource: 'manual',
          oldSnapshot: _snapshotFromRun(existing),
          newSnapshot: {
            'id': existing.id,
            'run_key': runKey,
            'workout_day_id': workoutDayId,
            'plan_day_id': mappedPlanDayId,
            'start_time': startTimeMs,
            'end_time': endTimeMs,
            'duration_s': durationS,
            'distance_m': distanceM,
            'avg_hr': avgHr,
            'max_hr': maxHr,
            'source': 'manual',
            'source_priority': 10,
          },
          reason: 'manual_edit_override',
        );
      }

      await (update(runSessions)..where((r) => r.id.equals(runSessionId)))
          .write(
        RunSessionsCompanion(
          runKey: Value(runKey),
          workoutDayId: Value(workoutDayId),
          planDayId: Value(mappedPlanDayId),
          startTime: Value(startTimeMs),
          endTime: Value(endTimeMs),
          durationS: Value(durationS),
          distanceM: Value(distanceM),
          avgHr: Value(avgHr),
          maxHr: Value(maxHr),
          treadmill: const Value(false),
          rawMetricsJson: Value(rawMetricsJson),
          source: const Value('manual'),
          sourcePriority: const Value(10),
        ),
      );
      await _replaceRunSegmentsForManualRun(
        runSessionId: runSessionId,
        segments: sanitizedSegments,
      );

      return RunUpsertOutcome(
        runSessionId: runSessionId,
        inserted: false,
        updated: true,
        overriddenManual: wasHighPriority,
        preservedGarmin: false,
      );
    });
  }

  List<ManualRunSegmentInput> _sanitizeManualRunSegments(
      List<ManualRunSegmentInput> input) {
    final output = <ManualRunSegmentInput>[];
    for (final segment in input) {
      if (segment.durationS <= 0) {
        continue;
      }
      final normalizedKind =
          segment.kind.trim().toLowerCase() == 'rest' ? 'rest' : 'interval';
      final safeDistance = segment.distanceM < 0 ? 0.0 : segment.distanceM;
      output.add(
        ManualRunSegmentInput(
          idx: output.length + 1,
          durationS: segment.durationS,
          distanceM: safeDistance,
          kind: normalizedKind,
          speedMps: segment.speedMps,
        ),
      );
    }
    return output;
  }

  String? _manualRunRawMetricsJson(List<ManualRunSegmentInput> segments) {
    if (segments.isEmpty) {
      return null;
    }
    return jsonEncode({
      'manual_segments': segments.map((s) => s.toJson()).toList(),
    });
  }

  Future<void> _replaceRunSegmentsForManualRun({
    required String runSessionId,
    required List<ManualRunSegmentInput> segments,
  }) async {
    await (delete(runSegments)
          ..where((s) => s.runSessionId.equals(runSessionId)))
        .go();
    for (final segment in segments) {
      await into(runSegments).insert(
        RunSegmentsCompanion.insert(
          id: _uuid.v4(),
          runSessionId: runSessionId,
          idx: segment.idx,
          durationS: Value(segment.durationS),
          distanceM: Value(segment.distanceM),
          speedMps: Value(segment.speedMps),
        ),
      );
    }
  }

  Future<RunUpsertOutcome> upsertGarminRun({
    required GarminParsedRunRow row,
    required String importFileName,
  }) async {
    final dateString = toYmd(row.startDateTime);
    final workoutDayId = await createOrGetWorkoutDayByDate(dateString);
    final mappedPlanDayId = await _resolvePlanDayIdForDate(dateString);
    final startMs = row.startDateTime.millisecondsSinceEpoch;
    final endMs =
        row.durationS == null ? null : startMs + (row.durationS! * 1000);

    final existing = await (select(runSessions)
          ..where((r) => r.runKey.equals(row.runKey)))
        .getSingleOrNull();

    final companion = RunSessionsCompanion(
      runKey: Value(row.runKey),
      workoutDayId: Value(workoutDayId),
      planDayId: Value(mappedPlanDayId),
      startTime: Value(startMs),
      endTime: Value(endMs),
      durationS: Value(row.durationS),
      distanceM: Value(row.distanceM),
      avgHr: Value(row.avgHr),
      maxHr: Value(row.maxHr),
      treadmill: Value(row.activityType.toLowerCase().contains('treadmill')),
      source: const Value('garmin_import'),
      title: Value(row.title),
      activityType: Value(row.activityType),
      calories: Value(row.calories),
      movingTimeS: Value(row.movingTimeS),
      elapsedTimeS: Value(row.elapsedTimeS),
      sourcePriority: const Value(100),
      importFileName: Value(importFileName),
      rawMetricsJson: Value(jsonEncode(row.rawMap)),
    );

    if (existing == null) {
      final id = _uuid.v4();
      await into(runSessions).insert(
        companion.copyWith(id: Value(id)),
      );

      return RunUpsertOutcome(
        runSessionId: id,
        inserted: true,
        updated: false,
        overriddenManual: false,
        preservedGarmin: false,
      );
    }

    var overriddenManual = false;
    if (existing.sourcePriority < 100) {
      overriddenManual = true;
      await insertRunOverrideAudit(
        runKey: row.runKey,
        workoutDayId: workoutDayId,
        oldSource: existing.source,
        newSource: 'garmin_import',
        oldSnapshot: _snapshotFromRun(existing),
        newSnapshot: {
          'run_key': row.runKey,
          'start_time': startMs,
          'duration_s': row.durationS,
          'distance_m': row.distanceM,
          'avg_hr': row.avgHr,
          'max_hr': row.maxHr,
          'source': 'garmin_import',
        },
        reason: 'garmin_overrides_manual',
      );
    }

    await (update(runSessions)..where((r) => r.id.equals(existing.id)))
        .write(companion);

    return RunUpsertOutcome(
      runSessionId: existing.id,
      inserted: false,
      updated: true,
      overriddenManual: overriddenManual,
      preservedGarmin: false,
    );
  }

  Future<void> upsertRunDetails({
    required String runSessionId,
    required GarminParsedRunRow row,
  }) async {
    final existing = await (select(runSessionDetails)
          ..where((d) => d.runSessionId.equals(runSessionId)))
        .getSingleOrNull();

    final companion = RunSessionDetailsCompanion(
      runSessionId: Value(runSessionId),
      favorite: Value(row.favorite),
      aerobicTe: Value(row.aerobicTe),
      avgRunCadence: Value(row.avgRunCadence),
      maxRunCadence: Value(row.maxRunCadence),
      avgPaceS: Value(row.avgPaceS),
      bestPaceS: Value(row.bestPaceS),
      totalAscent: Value(row.totalAscent),
      totalDescent: Value(row.totalDescent),
      avgStrideLengthM: Value(row.avgStrideLengthM),
      trainingStressScore: Value(row.trainingStressScore),
      steps: Value(row.steps),
      minTemp: Value(row.minTemp),
      maxTemp: Value(row.maxTemp),
      decompression: Value(row.decompression),
      bestLapTimeS: Value(row.bestLapTimeS),
      numberOfLaps: Value(row.numberOfLaps),
      minElevation: Value(row.minElevation),
      maxElevation: Value(row.maxElevation),
      rawMetricsJson: Value(jsonEncode(row.rawMap)),
    );

    if (existing == null) {
      await into(runSessionDetails).insert(
        RunSessionDetailsCompanion.insert(
          runSessionId: runSessionId,
          rawMetricsJson: jsonEncode(row.rawMap),
          favorite: Value(row.favorite),
          aerobicTe: Value(row.aerobicTe),
          avgRunCadence: Value(row.avgRunCadence),
          maxRunCadence: Value(row.maxRunCadence),
          avgPaceS: Value(row.avgPaceS),
          bestPaceS: Value(row.bestPaceS),
          totalAscent: Value(row.totalAscent),
          totalDescent: Value(row.totalDescent),
          avgStrideLengthM: Value(row.avgStrideLengthM),
          trainingStressScore: Value(row.trainingStressScore),
          steps: Value(row.steps),
          minTemp: Value(row.minTemp),
          maxTemp: Value(row.maxTemp),
          decompression: Value(row.decompression),
          bestLapTimeS: Value(row.bestLapTimeS),
          numberOfLaps: Value(row.numberOfLaps),
          minElevation: Value(row.minElevation),
          maxElevation: Value(row.maxElevation),
        ),
      );
      return;
    }

    await (update(runSessionDetails)
          ..where((d) => d.runSessionId.equals(runSessionId)))
        .write(companion);
  }

  Future<void> insertRunOverrideAudit({
    required String runKey,
    required String? workoutDayId,
    required String oldSource,
    required String newSource,
    required Map<String, dynamic> oldSnapshot,
    required Map<String, dynamic> newSnapshot,
    required String reason,
  }) async {
    await into(runOverrideAudit).insert(
      RunOverrideAuditCompanion.insert(
        id: _uuid.v4(),
        runKey: runKey,
        workoutDayId: Value(workoutDayId),
        oldSource: oldSource,
        newSource: newSource,
        oldSnapshotJson: jsonEncode(oldSnapshot),
        newSnapshotJson: jsonEncode(newSnapshot),
        reason: reason,
        createdAt: unixMsNow(),
      ),
    );
  }

  Future<GarminImportResult> importGarminCsv({
    required String filePath,
    required GarminImportOptions options,
  }) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final parsed = GarminCsvImportService.parseCsvContent(content, options);

    final deduped = <String, GarminParsedRunRow>{};
    for (final row in parsed.rows) {
      deduped[row.runKey] = row;
    }

    var inserted = 0;
    var updated = 0;
    var overridden = 0;

    for (final row in deduped.values) {
      final outcome = await upsertGarminRun(
        row: row,
        importFileName: p.basename(filePath),
      );
      await upsertRunDetails(runSessionId: outcome.runSessionId, row: row);

      if (outcome.inserted) {
        inserted++;
      } else if (outcome.updated) {
        updated++;
      }
      if (outcome.overriddenManual) {
        overridden++;
      }
    }

    final duplicateCount = parsed.rows.length - deduped.length;

    return GarminImportResult(
      insertedCount: inserted,
      updatedCount: updated,
      overriddenCount: overridden,
      skippedCount: parsed.skippedCount + duplicateCount,
      errorRows: parsed.errors,
    );
  }

  Future<StrengthImportResult> importStrengthHistoryXlsx({
    required String filePath,
  }) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final parsed = StrengthHistoryImportService.parseXlsxBytes(bytes);

    var inserted = 0;
    var skipped = parsed.skippedCount;

    for (final row in parsed.rows) {
      final dateString = toYmd(row.date);
      final workoutDayId = await createOrGetWorkoutDayByDate(dateString);
      final canonicalExercise = ExerciseNormalizer.normalize(row.exercise);
      final unit = row.weightLb == null ? 'unknown' : 'lb';

      final duplicate = await (select(actualStrengthSets)
            ..where((t) => t.workoutDayId.equals(workoutDayId))
            ..where((t) => t.exerciseCanonical.equals(canonicalExercise))
            ..where((t) => t.setIndex.equals(row.setIndex))
            ..where((t) => t.source.equals('import'))
            ..where((t) => _nullableDoubleEquals(t.weight, row.weightLb))
            ..where((t) => _nullableIntEquals(t.reps, row.reps))
            ..where((t) => _nullableIntEquals(t.rir, row.rir)))
          .getSingleOrNull();

      if (duplicate != null) {
        skipped++;
        continue;
      }

      await into(actualStrengthSets).insert(
        ActualStrengthSetsCompanion.insert(
          id: _uuid.v4(),
          workoutDayId: workoutDayId,
          performedAt: const Value(null),
          exerciseCanonical: canonicalExercise,
          setIndex: row.setIndex,
          weight: Value(row.weightLb),
          reps: Value(row.reps),
          rir: Value(row.rir),
          unit: unit,
          source: 'import',
          rawSetString: Value(_rawSetFromFields(
            weight: row.weightLb,
            reps: row.reps,
            rir: row.rir,
          )),
          createdAt: unixMsNow(),
        ),
      );
      inserted++;
    }

    return StrengthImportResult(
      insertedCount: inserted,
      skippedCount: skipped,
      errorRows: parsed.errors,
    );
  }

  Future<int> replacePlanCycleFromTemplate({
    required DateTime startDate,
    required List<PplTemplateDay> days,
    required bool applyProgression,
    required bool progressionAllowed,
  }) async {
    final normalizedStart =
        DateTime(startDate.year, startDate.month, startDate.day);
    final weekStart = toYmd(normalizedStart);
    final weekEnd = toYmd(normalizedStart.add(const Duration(days: 6)));

    return transaction(() async {
      await _deletePlanCyclesOverlappingDateRange(
        rangeStartYmd: weekStart,
        rangeEndYmd: weekEnd,
      );

      final cycleId = _uuid.v4();
      await into(planCycles).insert(
        PlanCyclesCompanion.insert(
          id: cycleId,
          cycleKey: 'template_${weekStart.replaceAll('-', '')}',
          weekStart: weekStart,
          weekEnd: weekEnd,
          source: 'template_generator',
          createdAt: unixMsNow(),
        ),
      );

      final planDayIdByNumber = <int, String>{};
      final templateDayByNumber = <int, PplTemplateDay>{
        for (final day in days) day.dayNumber: day,
      };
      for (var dayNumber = 1; dayNumber <= 7; dayNumber++) {
        final planDayId = _uuid.v4();
        planDayIdByNumber[dayNumber] = planDayId;
        final estimatedDate =
            toYmd(normalizedStart.add(Duration(days: dayNumber - 1)));
        final templateDay = templateDayByNumber[dayNumber];
        final sheetName = templateDay?.sheetName ?? 'Day $dayNumber';
        final sessionType = _deriveSessionType(
          sheetName: sheetName,
        );
        await into(planDays).insert(
          PlanDaysCompanion.insert(
            id: planDayId,
            planCycleId: cycleId,
            dayNumber: dayNumber,
            sheetName: _sheetNameForDay(
              dayNumber: dayNumber,
              sessionType: sessionType,
              fallbackSheetName: sheetName,
            ),
            estimatedDate: Value(estimatedDate),
            sessionType: Value(sessionType),
            createdAt: unixMsNow(),
          ),
        );
      }

      var inserted = 0;
      for (final day in days) {
        final planDayId = planDayIdByNumber[day.dayNumber];
        if (planDayId == null) {
          continue;
        }
        for (final set in day.sets) {
          final allowProgression = applyProgression && progressionAllowed;
          final progressedWeight = (allowProgression && set.weight != null)
              ? set.weight! + 5
              : set.weight;
          await into(planPrescribedStrengthSets).insert(
            PlanPrescribedStrengthSetsCompanion.insert(
              id: _uuid.v4(),
              planDayId: planDayId,
              exerciseCanonical: set.exercise,
              setIndex: set.setIndex,
              weight: Value(progressedWeight),
              reps: Value(set.reps),
              rir: Value(set.rir),
              unit: set.unit,
              rawSetString: Value(_rawSetFromFields(
                weight: progressedWeight,
                reps: set.reps,
                rir: set.rir,
              )),
              createdAt: unixMsNow(),
            ),
          );
          inserted++;
        }
      }

      return inserted;
    });
  }

  Future<StandardWorkbookImportResult> importStandardWorkbookXlsx({
    required String filePath,
    required DateTime splitStartDate,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    SpreadsheetDecoder? decoder;
    Object? spreadsheetDecoderError;
    try {
      decoder = SpreadsheetDecoder.decodeBytes(bytes, update: false);
    } catch (e) {
      spreadsheetDecoderError = e;
    }
    final decoderSheetNames = decoder?.tables.keys.toList() ?? const <String>[];
    final useExcelFallback = decoderSheetNames.isEmpty;
    Excel? excelWorkbook;
    if (useExcelFallback) {
      try {
        excelWorkbook = Excel.decodeBytes(bytes);
      } catch (e) {
        final spreadsheetMsg = spreadsheetDecoderError == null
            ? 'SpreadsheetDecoder returned 0 sheets'
            : 'SpreadsheetDecoder failed: $spreadsheetDecoderError';
        throw StateError(
          'Workbook parse failed. $spreadsheetMsg. '
          'Excel fallback failed: $e. '
          'This usually means the workbook has unsupported/damaged XLSX styles metadata. '
          'Open it in Excel and use Save As to create a repaired copy, then retry.',
        );
      }
    }
    final sheetNames = useExcelFallback
        ? excelWorkbook!.tables.keys.toList()
        : decoderSheetNames;
    List<List<dynamic>> rowsForSheet(String sheetName) {
      if (useExcelFallback) {
        return _decodeExcelRows(excelWorkbook!.tables[sheetName]);
      }
      return _decodeRows(decoder!.tables[sheetName]?.rows);
    }

    if (sheetNames.length < 11) {
      throw StateError(
          'Expected at least 11 sheets, found ${sheetNames.length}.');
    }
    const requiredPrefix = <String>['Strength Data', 'Run Data'];
    for (var i = 0; i < requiredPrefix.length; i++) {
      if (sheetNames[i].trim() != requiredPrefix[i]) {
        throw StateError(
          'Sheet ${i + 1} must be "${requiredPrefix[i]}". Found "${sheetNames[i]}".',
        );
      }
    }

    var summaryStartIndex = 2;
    String? tenWeekPlanSheetName;
    if (sheetNames.length > summaryStartIndex &&
        sheetNames[summaryStartIndex].trim().toLowerCase() == '10 week plan') {
      tenWeekPlanSheetName = sheetNames[summaryStartIndex].trim();
      summaryStartIndex++;
    }

    final strengthSummarySheetName = sheetNames[summaryStartIndex].trim();
    const allowedStrengthSummaryNames = <String>{
      '5-Day Push Pull Plan',
      '7-Day Push Pull Plan',
    };
    if (!allowedStrengthSummaryNames.contains(strengthSummarySheetName)) {
      throw StateError(
        'Sheet ${summaryStartIndex + 1} must be one of '
        '"5-Day Push Pull Plan" or "7-Day Push Pull Plan". '
        'Found "${sheetNames[summaryStartIndex]}".',
      );
    }

    final runPlanSheetName = sheetNames[summaryStartIndex + 1].trim();
    if (runPlanSheetName != 'Run Plan - 5mi @ 8 min' &&
        runPlanSheetName != 'Run Plan - 5mi @ 8') {
      throw StateError(
          'Sheet ${summaryStartIndex + 2} must be "Run Plan - 5mi @ 8 min" (or legacy "Run Plan - 5mi @ 8").');
    }

    final firstDaySheetIndex = summaryStartIndex + 2;
    for (var dayNumber = 1; dayNumber <= 7; dayNumber++) {
      final idx = firstDaySheetIndex + (dayNumber - 1);
      final expectedPrefix = 'day $dayNumber';
      if (idx >= sheetNames.length ||
          !sheetNames[idx].trim().toLowerCase().startsWith(expectedPrefix)) {
        throw StateError(
          'Expected sheet ${idx + 1} to start with "Day $dayNumber". Found "${idx < sheetNames.length ? sheetNames[idx] : 'missing'}".',
        );
      }
    }

    final strengthSummaryRows = rowsForSheet(strengthSummarySheetName);
    final runSummaryRows = rowsForSheet(runPlanSheetName);
    final tenWeekPlanRows = tenWeekPlanSheetName == null
        ? const <List<dynamic>>[]
        : rowsForSheet(tenWeekPlanSheetName);
    final parsedLongRangeWeeks =
        _parseLongRangePlanRowsFromTenWeekSnapshotRows(tenWeekPlanRows);
    final summarySessionByDay =
        _extractSummarySessionByDay(strengthSummaryRows);

    final parsedDays = <_ParsedDailyPlan>[];
    for (var dayNumber = 1; dayNumber <= 7; dayNumber++) {
      final sheetName = sheetNames[firstDaySheetIndex + (dayNumber - 1)];
      final rows = rowsForSheet(sheetName);
      parsedDays.add(_parseDailyPlanSheet(
        dayNumber: dayNumber,
        sheetName: sheetName,
        rows: rows,
        summarySession: summarySessionByDay[dayNumber],
      ));
    }

    final conflicts = _detectWorkbookConflicts(
      summaryStrengthRows: strengthSummaryRows,
      summaryRunRows: runSummaryRows,
      parsedDays: parsedDays,
    );
    if (conflicts.isNotEmpty) {
      final reportPath = await _writeConflictReportWorkbook(
        filePath: filePath,
        conflicts: conflicts,
        dailyPlans: parsedDays,
        summaryStrengthRows: strengthSummaryRows,
        summaryRunRows: runSummaryRows,
      );
      await into(planImportAudit).insert(
        PlanImportAuditCompanion.insert(
          id: _uuid.v4(),
          importedAt: unixMsNow(),
          fileName: p.basename(filePath),
          success: false,
          detailsJson: jsonEncode({'conflicts': conflicts}),
          conflictReportPath: Value(reportPath),
        ),
      );
      throw StateError(
          'Import rejected due to summary/daily conflicts. Conflict report: $reportPath');
    }

    final normalizedSplitStart = DateTime(
      splitStartDate.year,
      splitStartDate.month,
      splitStartDate.day,
    );
    final weekStart = toYmd(normalizedSplitStart);
    final weekEnd = toYmd(normalizedSplitStart.add(const Duration(days: 6)));

    late int insertedDayCount;
    late int insertedStrengthCount;
    late int insertedRunCount;
    late int insertedAlternativeCount;
    late bool replacedCycle;

    await transaction(() async {
      replacedCycle = await _deletePlanCyclesOverlappingDateRange(
        rangeStartYmd: weekStart,
        rangeEndYmd: weekEnd,
      );

      final cycleId = _uuid.v4();
      await into(planCycles).insert(
        PlanCyclesCompanion.insert(
          id: cycleId,
          cycleKey: 'wk_${weekStart.replaceAll('-', '')}',
          weekStart: weekStart,
          weekEnd: weekEnd,
          source: 'standard_workbook_import',
          createdAt: unixMsNow(),
        ),
      );

      final snapshots = <String, List<List<dynamic>>>{
        strengthSummarySheetName: strengthSummaryRows,
        runPlanSheetName == 'Run Plan - 5mi @ 8'
            ? 'Run Plan - 5mi @ 8'
            : 'Run Plan - 5mi @ 8 min': runSummaryRows,
      };
      if (tenWeekPlanSheetName != null) {
        snapshots[tenWeekPlanSheetName] = tenWeekPlanRows;
      }
      for (final entry in snapshots.entries) {
        await into(planSummarySnapshots).insert(
          PlanSummarySnapshotsCompanion.insert(
            id: _uuid.v4(),
            planCycleId: cycleId,
            tabName: entry.key,
            snapshotJson: jsonEncode({'rows': entry.value}),
            createdAt: unixMsNow(),
          ),
        );
      }
      if (parsedLongRangeWeeks.isNotEmpty) {
        await _upsertPlanLongRangeWeeks(
          rows: parsedLongRangeWeeks,
          source: 'standard_workbook_import',
          planCycleId: cycleId,
        );
      }

      final planDayIdByNumber = <int, String>{};
      for (final day in parsedDays) {
        final planDayId = _uuid.v4();
        planDayIdByNumber[day.dayNumber] = planDayId;
        final estimatedDate = toYmd(
          normalizedSplitStart.add(Duration(days: day.dayNumber - 1)),
        );
        await into(planDays).insert(
          PlanDaysCompanion.insert(
            id: planDayId,
            planCycleId: cycleId,
            dayNumber: day.dayNumber,
            sheetName: _sheetNameForDay(
              dayNumber: day.dayNumber,
              sessionType: day.sessionType,
              fallbackSheetName: day.sheetName,
            ),
            estimatedDate: Value(estimatedDate),
            sessionType: Value(day.sessionType),
            createdAt: unixMsNow(),
          ),
        );
      }

      insertedDayCount = parsedDays.length;
      insertedStrengthCount = 0;
      insertedRunCount = 0;
      insertedAlternativeCount = 0;

      for (final day in parsedDays) {
        final planDayId = planDayIdByNumber[day.dayNumber]!;
        await into(planPrescribedRuns).insert(
          PlanPrescribedRunsCompanion.insert(
            id: _uuid.v4(),
            planDayId: planDayId,
            dayLabel: Value(day.dayLabel),
            liftFocus: Value(day.liftFocus),
            runType: Value(day.runType),
            durationText: Value(day.durationText),
            targetPace: Value(day.targetPace),
            effortHrGuardrails: Value(day.effortHrGuardrails),
            notes: Value(day.notes),
            createdAt: unixMsNow(),
          ),
        );
        insertedRunCount++;

        for (final set in day.strengthRows) {
          await into(planPrescribedStrengthSets).insert(
            PlanPrescribedStrengthSetsCompanion.insert(
              id: _uuid.v4(),
              planDayId: planDayId,
              exerciseCanonical: set.exerciseCanonical,
              setIndex: set.setIndex,
              weight: Value(set.weight),
              reps: Value(set.reps),
              rir: Value(set.rir),
              unit: set.unit,
              rawSetString: Value(set.rawSetString),
              createdAt: unixMsNow(),
            ),
          );
          insertedStrengthCount++;
        }

        for (final alt in day.alternatives) {
          final combinedNotes = _composeAlternativeNotes(
            tier: alt.tier,
            rationale: alt.rationale,
            notes: alt.notes,
          );
          await upsertPlanExerciseAlternative(
            planDayId: planDayId,
            prescribedExerciseCanonical: alt.prescribedExerciseCanonical,
            alternativeExerciseCanonical: alt.alternativeExerciseCanonical,
            priority: 1000 - alt.rank,
            notes: combinedNotes,
          );
          // Also store a reusable global substitute bank entry sourced from AI/workbook output.
          await upsertPlanExerciseAlternative(
            planDayId: null,
            prescribedExerciseCanonical: alt.prescribedExerciseCanonical,
            alternativeExerciseCanonical: alt.alternativeExerciseCanonical,
            priority: 1000 - alt.rank,
            notes: combinedNotes,
          );
          insertedAlternativeCount++;
        }
      }
    });

    await into(planImportAudit).insert(
      PlanImportAuditCompanion.insert(
        id: _uuid.v4(),
        importedAt: unixMsNow(),
        fileName: p.basename(filePath),
        success: true,
        detailsJson: jsonEncode({
          'split_start': weekStart,
          'split_end': weekEnd,
          'inserted_plan_days': insertedDayCount,
          'inserted_strength_sets': insertedStrengthCount,
          'inserted_run_plans': insertedRunCount,
          'inserted_alternatives': insertedAlternativeCount,
        }),
      ),
    );

    return StandardWorkbookImportResult(
      replacedCycle: replacedCycle,
      insertedPlanDays: insertedDayCount,
      insertedStrengthSets: insertedStrengthCount,
      insertedRunPlans: insertedRunCount,
      insertedAlternatives: insertedAlternativeCount,
      warnings: const <String>[],
      conflictReportPath: null,
    );
  }

  Future<AiWeeklyPlanTextImportResult> importAiWeeklyPlanText({
    required String text,
    required DateTime splitStartDate,
  }) async {
    final bundle = _parseAiPlanImportBundleText(text);
    final parsed = bundle.weeklyPlan;

    final normalizedSplitStart = DateTime(
      splitStartDate.year,
      splitStartDate.month,
      splitStartDate.day,
    );
    final expectedWeekStart = toYmd(normalizedSplitStart);
    final expectedWeekEnd =
        toYmd(normalizedSplitStart.add(const Duration(days: 6)));

    if (parsed.weekStart != expectedWeekStart) {
      throw StateError(
        'WEEK_START (${parsed.weekStart}) does not match selected split start ($expectedWeekStart).',
      );
    }
    if (parsed.weekEnd != expectedWeekEnd) {
      throw StateError(
        'WEEK_END (${parsed.weekEnd}) does not match selected split end ($expectedWeekEnd).',
      );
    }

    final tenWeekSnapshotRows = bundle.tenWeekRows.isNotEmpty
        ? _aiTenWeekRowsToSnapshotRows(bundle.tenWeekRows)
        : await _getLatestSummarySnapshotRowsByTabName('10 Week Plan');

    late int insertedDayCount;
    late int insertedStrengthCount;
    late int insertedRunCount;
    late int insertedAlternativeCount;
    late bool replacedCycle;

    await transaction(() async {
      replacedCycle = await _deletePlanCyclesOverlappingDateRange(
        rangeStartYmd: expectedWeekStart,
        rangeEndYmd: expectedWeekEnd,
      );

      final cycleId = _uuid.v4();
      await into(planCycles).insert(
        PlanCyclesCompanion.insert(
          id: cycleId,
          cycleKey: 'aiwk_${expectedWeekStart.replaceAll('-', '')}',
          weekStart: expectedWeekStart,
          weekEnd: expectedWeekEnd,
          source: 'ai_weekly_plan_text',
          createdAt: unixMsNow(),
        ),
      );

      if (tenWeekSnapshotRows != null && tenWeekSnapshotRows.isNotEmpty) {
        await into(planSummarySnapshots).insert(
          PlanSummarySnapshotsCompanion.insert(
            id: _uuid.v4(),
            planCycleId: cycleId,
            tabName: '10 Week Plan',
            snapshotJson: jsonEncode({'rows': tenWeekSnapshotRows}),
            createdAt: unixMsNow(),
          ),
        );
      }
      if (bundle.tenWeekRows.isNotEmpty) {
        await _upsertPlanLongRangeWeeks(
          rows: _longRangeInputsFromAiTenWeekRows(bundle.tenWeekRows),
          source: 'ai_weekly_plan_text',
          planCycleId: cycleId,
        );
      }

      final planDayIdByNumber = <int, String>{};
      insertedDayCount = 0;
      insertedStrengthCount = 0;
      insertedRunCount = 0;
      insertedAlternativeCount = 0;

      for (final day in parsed.days) {
        final planDayId = _uuid.v4();
        planDayIdByNumber[day.dayNumber] = planDayId;
        final estimatedDate = toYmd(
          normalizedSplitStart.add(Duration(days: day.dayNumber - 1)),
        );
        final fallbackSheetName = (day.dayLabel?.trim().isNotEmpty ?? false)
            ? 'Day ${day.dayNumber} - ${day.dayLabel!.trim()}'
            : 'Day ${day.dayNumber}';
        await into(planDays).insert(
          PlanDaysCompanion.insert(
            id: planDayId,
            planCycleId: cycleId,
            dayNumber: day.dayNumber,
            sheetName: _sheetNameForDay(
              dayNumber: day.dayNumber,
              sessionType: day.sessionType,
              fallbackSheetName: fallbackSheetName,
            ),
            estimatedDate: Value(estimatedDate),
            sessionType: Value(day.sessionType),
            createdAt: unixMsNow(),
          ),
        );
        insertedDayCount++;
      }

      for (final day in parsed.days) {
        final planDayId = planDayIdByNumber[day.dayNumber]!;
        await into(planPrescribedRuns).insert(
          PlanPrescribedRunsCompanion.insert(
            id: _uuid.v4(),
            planDayId: planDayId,
            dayLabel: Value(day.dayLabel),
            liftFocus: Value(day.liftFocus),
            runType: Value(day.runType),
            durationText: Value(day.durationText),
            targetPace: Value(day.targetPace),
            effortHrGuardrails: Value(day.effortHrGuardrails),
            notes: Value(day.notes),
            createdAt: unixMsNow(),
          ),
        );
        insertedRunCount++;

        for (final set in day.strengthRows) {
          await into(planPrescribedStrengthSets).insert(
            PlanPrescribedStrengthSetsCompanion.insert(
              id: _uuid.v4(),
              planDayId: planDayId,
              exerciseCanonical: set.exerciseCanonical,
              setIndex: set.setIndex,
              weight: Value(set.weight),
              reps: Value(set.reps),
              rir: Value(set.rir),
              unit: set.unit,
              rawSetString: Value(set.rawSetString),
              createdAt: unixMsNow(),
            ),
          );
          insertedStrengthCount++;
        }

        for (final alt in day.alternatives) {
          final combinedNotes = _composeAlternativeNotes(
            tier: alt.tier,
            rationale: alt.rationale,
            notes: alt.notes,
          );
          await upsertPlanExerciseAlternative(
            planDayId: planDayId,
            prescribedExerciseCanonical: alt.prescribedExerciseCanonical,
            alternativeExerciseCanonical: alt.alternativeExerciseCanonical,
            priority: 1000 - alt.rank,
            notes: combinedNotes,
          );
          await upsertPlanExerciseAlternative(
            planDayId: null,
            prescribedExerciseCanonical: alt.prescribedExerciseCanonical,
            alternativeExerciseCanonical: alt.alternativeExerciseCanonical,
            priority: 1000 - alt.rank,
            notes: combinedNotes,
          );
          insertedAlternativeCount++;
        }
      }
    });

    await into(planImportAudit).insert(
      PlanImportAuditCompanion.insert(
        id: _uuid.v4(),
        importedAt: unixMsNow(),
        fileName: 'ai_weekly_plan_text',
        success: true,
        detailsJson: jsonEncode({
          'format': 'WEEK_PLAN_V1',
          'week_start': expectedWeekStart,
          'week_end': expectedWeekEnd,
          'inserted_plan_days': insertedDayCount,
          'inserted_strength_sets': insertedStrengthCount,
          'inserted_run_plans': insertedRunCount,
          'inserted_alternatives': insertedAlternativeCount,
          'ten_week_rows_persisted': tenWeekSnapshotRows?.length ?? 0,
        }),
      ),
    );

    return AiWeeklyPlanTextImportResult(
      replacedCycle: replacedCycle,
      insertedPlanDays: insertedDayCount,
      insertedStrengthSets: insertedStrengthCount,
      insertedRunPlans: insertedRunCount,
      insertedAlternatives: insertedAlternativeCount,
      warnings: const <String>[],
    );
  }

  Future<List<List<dynamic>>?> _getLatestSummarySnapshotRowsByTabName(
    String tabName,
  ) async {
    final row = await (select(planSummarySnapshots)
          ..where((s) => s.tabName.equals(tabName))
          ..orderBy([
            (s) =>
                OrderingTerm(expression: s.createdAt, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) {
      return null;
    }
    final rows = _rowsFromSnapshotJson(row.snapshotJson);
    return rows.isEmpty ? null : rows;
  }

  List<List<dynamic>> _aiTenWeekRowsToSnapshotRows(
    List<_AiParsedTenWeekPlanRow> rows,
  ) {
    return <List<dynamic>>[
      <dynamic>[
        'Week',
        'Week Start',
        'Week End',
        'Run Focus',
        'Strength Focus',
        'Strength Progression Expectation',
        'Primary Progression Target',
        'Recovery Emphasis',
        'Deload?',
        'Notes',
      ],
      ...rows.map(
        (r) => <dynamic>[
          r.weekLabel,
          r.weekStart,
          r.weekEnd,
          r.runFocus,
          r.strengthFocus,
          r.strengthProgressionExpectation,
          r.primaryProgressionTarget,
          r.recoveryEmphasis,
          r.deload ? 'Yes' : 'No',
          r.notes ?? '',
        ],
      ),
    ];
  }

  List<_LongRangePlanWeekUpsertInput> _longRangeInputsFromAiTenWeekRows(
    List<_AiParsedTenWeekPlanRow> rows,
  ) {
    return rows
        .map(
          (r) => _LongRangePlanWeekUpsertInput(
            weekLabel: r.weekLabel,
            weekNumber: _weekNumberFromLabel(r.weekLabel),
            weekStart: r.weekStart,
            weekEnd: r.weekEnd,
            runFocus: r.runFocus,
            strengthFocus: r.strengthFocus,
            strengthProgressionExpectation: r.strengthProgressionExpectation,
            primaryProgressionTarget: r.primaryProgressionTarget,
            recoveryEmphasis: r.recoveryEmphasis,
            deload: r.deload,
            notes: r.notes,
          ),
        )
        .toList(growable: false);
  }

  List<_LongRangePlanWeekUpsertInput>
      _parseLongRangePlanRowsFromTenWeekSnapshotRows(
    List<List<dynamic>> rows,
  ) {
    if (rows.isEmpty) {
      return const <_LongRangePlanWeekUpsertInput>[];
    }
    final headerRow = rows.first;
    final colByKey = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final header = _cleanString(headerRow[i]);
      if (header == null) {
        continue;
      }
      colByKey[_normalizeTenWeekHeader(header)] = i;
    }

    int? idxFor(List<String> candidates) {
      for (final c in candidates) {
        final idx = colByKey[c];
        if (idx != null) {
          return idx;
        }
      }
      return null;
    }

    final weekIdx = idxFor(const ['week']);
    final weekStartIdx = idxFor(const ['week_start']);
    final weekEndIdx = idxFor(const ['week_end']);
    if (weekIdx == null || weekStartIdx == null || weekEndIdx == null) {
      return const <_LongRangePlanWeekUpsertInput>[];
    }

    final runFocusIdx = idxFor(const ['run_focus']);
    final strengthFocusIdx = idxFor(const ['strength_focus']);
    final strengthExpectationIdx =
        idxFor(const ['strength_progression_expectation']);
    final primaryTargetIdx = idxFor(const ['primary_progression_target']);
    final recoveryIdx = idxFor(const ['recovery_emphasis']);
    final deloadIdx = idxFor(const ['deload']);
    final notesIdx = idxFor(const ['notes']);

    final result = <_LongRangePlanWeekUpsertInput>[];
    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      final weekLabel = _cleanString(_cellValue([row], 0, weekIdx));
      final weekStart = _parseYmdLike(_cellValue([row], 0, weekStartIdx));
      final weekEnd = _parseYmdLike(_cellValue([row], 0, weekEndIdx));
      final anyPrimaryValue =
          weekLabel != null || weekStart != null || weekEnd != null;
      if (!anyPrimaryValue) {
        continue;
      }
      if (weekLabel == null || weekStart == null || weekEnd == null) {
        continue;
      }
      result.add(
        _LongRangePlanWeekUpsertInput(
          weekLabel: weekLabel,
          weekNumber: _weekNumberFromLabel(weekLabel),
          weekStart: weekStart,
          weekEnd: weekEnd,
          runFocus: runFocusIdx == null
              ? null
              : _cleanString(_cellValue([row], 0, runFocusIdx)),
          strengthFocus: strengthFocusIdx == null
              ? null
              : _cleanString(_cellValue([row], 0, strengthFocusIdx)),
          strengthProgressionExpectation: strengthExpectationIdx == null
              ? null
              : _cleanString(_cellValue([row], 0, strengthExpectationIdx)),
          primaryProgressionTarget: primaryTargetIdx == null
              ? null
              : _cleanString(_cellValue([row], 0, primaryTargetIdx)),
          recoveryEmphasis: recoveryIdx == null
              ? null
              : _cleanString(_cellValue([row], 0, recoveryIdx)),
          deload: _parseTenWeekDeloadValue(
            deloadIdx == null ? null : _cellValue([row], 0, deloadIdx),
          ),
          notes: notesIdx == null
              ? null
              : _cleanString(_cellValue([row], 0, notesIdx)),
        ),
      );
    }
    return result;
  }

  String _normalizeTenWeekHeader(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (normalized == 'deload') {
      return 'deload';
    }
    if (normalized == 'deload_') {
      return 'deload';
    }
    return normalized;
  }

  bool _parseTenWeekDeloadValue(dynamic raw) {
    final text = (_cleanString(raw) ?? '').trim().toLowerCase();
    if (text.isEmpty) {
      return false;
    }
    return text == 'yes' || text == 'true' || text == '1' || text == 'y';
  }

  int? _weekNumberFromLabel(String? weekLabel) {
    final text = (weekLabel ?? '').trim();
    if (text.isEmpty) {
      return null;
    }
    return int.tryParse(RegExp(r'(\d+)').firstMatch(text)?.group(1) ?? '');
  }

  Future<void> _upsertPlanLongRangeWeeks({
    required List<_LongRangePlanWeekUpsertInput> rows,
    required String source,
    String? planCycleId,
  }) async {
    if (rows.isEmpty) {
      return;
    }
    final now = unixMsNow();
    for (final row in rows) {
      final existing = await (select(planLongRangeWeeks)
            ..where((t) => t.weekStart.equals(row.weekStart))
            ..where((t) => t.weekEnd.equals(row.weekEnd))
            ..orderBy([
              (t) => OrderingTerm(
                  expression: t.updatedAt, mode: OrderingMode.desc),
            ])
            ..limit(1))
          .getSingleOrNull();
      if (existing != null) {
        await (update(planLongRangeWeeks)
              ..where((t) => t.id.equals(existing.id)))
            .write(
          PlanLongRangeWeeksCompanion(
            weekLabel: Value(row.weekLabel),
            weekNumber: Value(row.weekNumber),
            runFocus: Value(row.runFocus),
            strengthFocus: Value(row.strengthFocus),
            strengthProgressionExpectation:
                Value(row.strengthProgressionExpectation),
            primaryProgressionTarget: Value(row.primaryProgressionTarget),
            recoveryEmphasis: Value(row.recoveryEmphasis),
            deload: Value(row.deload),
            notes: Value(row.notes),
            source: Value(source),
            lastPlanCycleId: Value(planCycleId),
            updatedAt: Value(now),
          ),
        );
        continue;
      }
      await into(planLongRangeWeeks).insert(
        PlanLongRangeWeeksCompanion.insert(
          id: _uuid.v4(),
          weekLabel: row.weekLabel,
          weekNumber: Value(row.weekNumber),
          weekStart: row.weekStart,
          weekEnd: row.weekEnd,
          runFocus: Value(row.runFocus),
          strengthFocus: Value(row.strengthFocus),
          strengthProgressionExpectation:
              Value(row.strengthProgressionExpectation),
          primaryProgressionTarget: Value(row.primaryProgressionTarget),
          recoveryEmphasis: Value(row.recoveryEmphasis),
          deload: Value(row.deload),
          notes: Value(row.notes),
          source: source,
          lastPlanCycleId: Value(planCycleId),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  _AiParsedPlanImportBundle _parseAiPlanImportBundleText(String text) {
    final lines = const LineSplitter().convert(text);
    final weeklyLines = <String>[];
    final tenWeekRows = <_AiParsedTenWeekPlanRow>[];
    var inTenWeekSection = false;
    var sawWeekHeader = false;
    var sawTenWeekHeader = false;
    var sawTenWeekEnd = false;

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      if (i == 0 && line.startsWith('\ufeff')) {
        line = line.substring(1);
      }
      final trimmed = line.trim();
      final lineNo = i + 1;

      if (sawWeekHeader) {
        weeklyLines.add(line);
        continue;
      }

      if (inTenWeekSection) {
        if (trimmed.isEmpty) {
          continue;
        }
        if (trimmed == 'END_TEN_WEEK_PLAN_UPDATE_V1') {
          inTenWeekSection = false;
          sawTenWeekEnd = true;
          continue;
        }
        final colonIndex = trimmed.indexOf(':');
        if (colonIndex <= 0) {
          throw StateError(
            'Line $lineNo: expected TEN_WEEK_ROW: ... or END_TEN_WEEK_PLAN_UPDATE_V1.',
          );
        }
        final key = trimmed.substring(0, colonIndex).trim().toUpperCase();
        final payload = trimmed.substring(colonIndex + 1).trim();
        if (key != 'TEN_WEEK_ROW') {
          throw StateError(
              'Line $lineNo: unexpected field "$key" in ten-week section.');
        }
        tenWeekRows.add(_parseAiTenWeekPlanRow(payload, lineNo: lineNo));
        continue;
      }

      if (trimmed.isEmpty) {
        continue;
      }

      if (trimmed == 'TEN_WEEK_PLAN_UPDATE_V1') {
        if (sawTenWeekHeader) {
          throw StateError(
              'Line $lineNo: duplicate TEN_WEEK_PLAN_UPDATE_V1 section.');
        }
        if (sawWeekHeader) {
          throw StateError(
            'Line $lineNo: TEN_WEEK_PLAN_UPDATE_V1 must appear before WEEK_PLAN_V1.',
          );
        }
        inTenWeekSection = true;
        sawTenWeekHeader = true;
        continue;
      }

      if (trimmed == 'WEEK_PLAN_V1') {
        sawWeekHeader = true;
        weeklyLines.add('WEEK_PLAN_V1');
        continue;
      }

      throw StateError(
        'Line $lineNo: expected TEN_WEEK_PLAN_UPDATE_V1 or WEEK_PLAN_V1.',
      );
    }

    if (inTenWeekSection) {
      throw StateError(
          'TEN_WEEK_PLAN_UPDATE_V1 is missing END_TEN_WEEK_PLAN_UPDATE_V1.');
    }
    if (sawTenWeekHeader && !sawTenWeekEnd) {
      throw StateError(
          'TEN_WEEK_PLAN_UPDATE_V1 is missing END_TEN_WEEK_PLAN_UPDATE_V1.');
    }
    if (!sawWeekHeader || weeklyLines.isEmpty) {
      throw StateError('Missing WEEK_PLAN_V1 section.');
    }
    if (tenWeekRows.isNotEmpty) {
      _validateAiTenWeekPlanRows(tenWeekRows);
    }

    final weeklyPlan = _parseAiWeeklyPlanText(weeklyLines.join('\n'));
    return _AiParsedPlanImportBundle(
      weeklyPlan: weeklyPlan,
      tenWeekRows: List<_AiParsedTenWeekPlanRow>.unmodifiable(tenWeekRows),
    );
  }

  _AiParsedTenWeekPlanRow _parseAiTenWeekPlanRow(
    String payload, {
    required int lineNo,
  }) {
    final parts = payload
        .split('|')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      throw StateError('Line $lineNo: TEN_WEEK_ROW is empty.');
    }
    final kv = _parseAiWeeklyKeyValueParts(
      parts,
      lineNo: lineNo,
      context: 'TEN_WEEK_ROW',
    );
    final weekLabel = (kv['week'] ?? '').trim();
    if (weekLabel.isEmpty) {
      throw StateError('Line $lineNo: TEN_WEEK_ROW.week is required.');
    }
    final weekStart = _parseAiWeeklyPlanYmd(
      (kv['week_start'] ?? '').trim(),
      lineNo: lineNo,
      field: 'TEN_WEEK_ROW.week_start',
    );
    final weekEnd = _parseAiWeeklyPlanYmd(
      (kv['week_end'] ?? '').trim(),
      lineNo: lineNo,
      field: 'TEN_WEEK_ROW.week_end',
    );
    final runFocus = (kv['run_focus'] ?? '').trim();
    final strengthFocus = (kv['strength_focus'] ?? '').trim();
    final strengthProgressionExpectation =
        (kv['strength_progression_expectation'] ?? '').trim();
    final primaryProgressionTarget =
        (kv['primary_progression_target'] ?? '').trim();
    final recoveryEmphasis = (kv['recovery_emphasis'] ?? '').trim();
    if (runFocus.isEmpty ||
        strengthFocus.isEmpty ||
        strengthProgressionExpectation.isEmpty ||
        primaryProgressionTarget.isEmpty ||
        recoveryEmphasis.isEmpty) {
      throw StateError(
        'Line $lineNo: TEN_WEEK_ROW requires run_focus, strength_focus, '
        'strength_progression_expectation, primary_progression_target, '
        'and recovery_emphasis.',
      );
    }
    final deloadRaw = (kv['deload'] ?? '').trim().toLowerCase();
    if (deloadRaw != 'yes' && deloadRaw != 'no') {
      throw StateError('Line $lineNo: TEN_WEEK_ROW.deload must be yes or no.');
    }
    final notes = _parseAiWeeklyNullableText(kv['notes'] ?? '');
    return _AiParsedTenWeekPlanRow(
      weekLabel: weekLabel,
      weekStart: weekStart,
      weekEnd: weekEnd,
      runFocus: runFocus,
      strengthFocus: strengthFocus,
      strengthProgressionExpectation: strengthProgressionExpectation,
      primaryProgressionTarget: primaryProgressionTarget,
      recoveryEmphasis: recoveryEmphasis,
      deload: deloadRaw == 'yes',
      notes: notes,
    );
  }

  void _validateAiTenWeekPlanRows(List<_AiParsedTenWeekPlanRow> rows) {
    final seenWeekLabels = <String>{};
    final seenDateRanges = <String>{};
    for (final row in rows) {
      final weekLabelKey = row.weekLabel.trim().toLowerCase();
      if (!seenWeekLabels.add(weekLabelKey)) {
        throw StateError('Duplicate TEN_WEEK_ROW.week "${row.weekLabel}".');
      }
      final rangeKey = '${row.weekStart}|${row.weekEnd}';
      if (!seenDateRanges.add(rangeKey)) {
        throw StateError(
          'Duplicate TEN_WEEK_ROW date range ${row.weekStart}..${row.weekEnd}.',
        );
      }
      final start = DateTime.tryParse('${row.weekStart}T00:00:00');
      final end = DateTime.tryParse('${row.weekEnd}T00:00:00');
      if (start == null || end == null) {
        throw StateError('Invalid TEN_WEEK_ROW dates for "${row.weekLabel}".');
      }
      if (toYmd(start.add(const Duration(days: 6))) != row.weekEnd) {
        throw StateError(
          'TEN_WEEK_ROW ${row.weekLabel}: week_end must be exactly 6 days after week_start.',
        );
      }
    }
  }

  _AiParsedWeeklyPlan _parseAiWeeklyPlanText(String text) {
    final lines = const LineSplitter().convert(text);
    var sawHeader = false;
    String? weekStart;
    String? weekEnd;
    final dayBuilders = <int, _AiParsedWeeklyPlanDayBuilder>{};
    _AiParsedWeeklyPlanDayBuilder? currentDay;

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      if (i == 0 && line.startsWith('\ufeff')) {
        line = line.substring(1);
      }
      final trimmed = line.trim();
      final lineNo = i + 1;
      if (trimmed.isEmpty) {
        continue;
      }

      if (!sawHeader) {
        if (trimmed != 'WEEK_PLAN_V1') {
          throw StateError('Line $lineNo: expected "WEEK_PLAN_V1".');
        }
        sawHeader = true;
        continue;
      }

      final dayStartMatch = RegExp(r'^DAY\s+([1-7])$').firstMatch(trimmed);
      final dayEndMatch = RegExp(r'^END\s+DAY\s+([1-7])$').firstMatch(trimmed);

      if (currentDay == null) {
        if (dayStartMatch != null) {
          final dayNumber = int.parse(dayStartMatch.group(1)!);
          if (dayBuilders.containsKey(dayNumber)) {
            throw StateError('Line $lineNo: duplicate DAY $dayNumber block.');
          }
          currentDay = _AiParsedWeeklyPlanDayBuilder(dayNumber);
          dayBuilders[dayNumber] = currentDay;
          continue;
        }
        if (dayEndMatch != null) {
          throw StateError(
              'Line $lineNo: END DAY found before DAY block start.');
        }
        final colonIndex = trimmed.indexOf(':');
        if (colonIndex <= 0) {
          throw StateError('Line $lineNo: expected KEY: VALUE line.');
        }
        final key = trimmed.substring(0, colonIndex).trim().toUpperCase();
        final value = trimmed.substring(colonIndex + 1).trim();
        switch (key) {
          case 'WEEK_START':
            weekStart =
                _parseAiWeeklyPlanYmd(value, lineNo: lineNo, field: key);
            break;
          case 'WEEK_END':
            weekEnd = _parseAiWeeklyPlanYmd(value, lineNo: lineNo, field: key);
            break;
          default:
            throw StateError(
              'Line $lineNo: unexpected top-level field "$key".',
            );
        }
        continue;
      }

      if (dayStartMatch != null) {
        throw StateError(
          'Line $lineNo: encountered DAY start before closing DAY ${currentDay.dayNumber}.',
        );
      }
      if (dayEndMatch != null) {
        final endDay = int.parse(dayEndMatch.group(1)!);
        if (endDay != currentDay.dayNumber) {
          throw StateError(
            'Line $lineNo: END DAY $endDay does not match current DAY ${currentDay.dayNumber}.',
          );
        }
        currentDay = null;
        continue;
      }

      final colonIndex = trimmed.indexOf(':');
      if (colonIndex <= 0) {
        throw StateError('Line $lineNo: expected KEY: VALUE inside day block.');
      }
      final key = trimmed.substring(0, colonIndex).trim().toUpperCase();
      final payload = trimmed.substring(colonIndex + 1).trim();

      switch (key) {
        case 'SESSION_TYPE':
          final raw = payload.trim().toLowerCase();
          if (raw.isEmpty) {
            currentDay.sessionType = 'unknown';
            break;
          }
          const allowed = {'push', 'pull', 'legs', 'rest', 'unknown'};
          if (!allowed.contains(raw)) {
            throw StateError(
              'Line $lineNo: invalid SESSION_TYPE "$payload".',
            );
          }
          currentDay.sessionType = raw;
          break;
        case 'DAY_LABEL':
          currentDay.dayLabel = _parseAiWeeklyNullableText(payload);
          break;
        case 'LIFT_FOCUS':
          currentDay.liftFocus = _parseAiWeeklyNullableText(payload);
          break;
        case 'RUN_TYPE':
          currentDay.runType = _parseAiWeeklyNullableText(payload);
          break;
        case 'RUN_DURATION':
          currentDay.durationText = _parseAiWeeklyNullableText(payload);
          break;
        case 'RUN_TARGET_PACE':
          currentDay.targetPace = _parseAiWeeklyNullableText(payload);
          break;
        case 'RUN_HR_GUARDRAILS':
          currentDay.effortHrGuardrails = _parseAiWeeklyNullableText(payload);
          break;
        case 'RUN_NOTES':
          currentDay.notes = _parseAiWeeklyNullableText(payload);
          break;
        case 'STRENGTH_SET':
          currentDay.strengthRows.add(
            _parseAiWeeklyPlanStrengthSet(payload, lineNo: lineNo),
          );
          break;
        case 'ALT':
          currentDay.alternatives.add(
            _parseAiWeeklyPlanAlternative(payload, lineNo: lineNo),
          );
          break;
        default:
          throw StateError(
              'Line $lineNo: unexpected field "$key" in day block.');
      }
    }

    if (!sawHeader) {
      throw StateError('Missing WEEK_PLAN_V1 header.');
    }
    if (currentDay != null) {
      throw StateError(
          'DAY ${currentDay.dayNumber} is missing END DAY ${currentDay.dayNumber}.');
    }
    if (weekStart == null || weekEnd == null) {
      throw StateError('WEEK_START and WEEK_END are required.');
    }

    final parsedWeekStart = DateTime.tryParse('${weekStart}T00:00:00');
    final parsedWeekEnd = DateTime.tryParse('${weekEnd}T00:00:00');
    if (parsedWeekStart == null || parsedWeekEnd == null) {
      throw StateError('WEEK_START/WEEK_END must be valid YYYY-MM-DD dates.');
    }
    if (toYmd(parsedWeekStart.add(const Duration(days: 6))) != weekEnd) {
      throw StateError('WEEK_END must be exactly 6 days after WEEK_START.');
    }

    final missingDays = List<int>.generate(7, (i) => i + 1)
        .where((d) => !dayBuilders.containsKey(d))
        .toList();
    if (missingDays.isNotEmpty) {
      throw StateError(
          'Missing required day blocks: ${missingDays.join(', ')}.');
    }

    final builtDays = <_AiParsedWeeklyPlanDay>[];
    for (var dayNumber = 1; dayNumber <= 7; dayNumber++) {
      final day = dayBuilders[dayNumber]!.build(this);
      _validateAiWeeklyPlanDay(day);
      builtDays.add(day);
    }

    return _AiParsedWeeklyPlan(
      weekStart: weekStart,
      weekEnd: weekEnd,
      days: builtDays,
    );
  }

  void _validateAiWeeklyPlanDay(_AiParsedWeeklyPlanDay day) {
    final setKeyByExerciseAndIndex = <String>{};
    final prescribedExercises = <String>{};

    for (final row in day.strengthRows) {
      prescribedExercises.add(row.exerciseCanonical);
      final key = '${row.exerciseCanonical}|${row.setIndex}';
      if (!setKeyByExerciseAndIndex.add(key)) {
        throw StateError(
          'DAY ${day.dayNumber}: duplicate STRENGTH_SET for ${row.exerciseCanonical} set=${row.setIndex}.',
        );
      }
    }

    final altKeySet = <String>{};
    final ranksByPrescribed = <String, Set<int>>{};
    for (final alt in day.alternatives) {
      if (!prescribedExercises.contains(alt.prescribedExerciseCanonical)) {
        throw StateError(
          'DAY ${day.dayNumber}: ALT references unknown prescribed exercise '
          '"${alt.prescribedExerciseCanonical}".',
        );
      }
      final altKey =
          '${alt.prescribedExerciseCanonical}|${alt.alternativeExerciseCanonical}';
      if (!altKeySet.add(altKey)) {
        throw StateError(
          'DAY ${day.dayNumber}: duplicate ALT for ${alt.prescribedExerciseCanonical} -> ${alt.alternativeExerciseCanonical}.',
        );
      }
      final rankSet = ranksByPrescribed.putIfAbsent(
        alt.prescribedExerciseCanonical,
        () => <int>{},
      );
      if (!rankSet.add(alt.rank)) {
        throw StateError(
          'DAY ${day.dayNumber}: duplicate ALT rank=${alt.rank} for ${alt.prescribedExerciseCanonical}.',
        );
      }
    }

    for (final exercise in prescribedExercises) {
      if (!ranksByPrescribed.containsKey(exercise)) {
        throw StateError(
          'DAY ${day.dayNumber}: missing ALT rows for prescribed exercise "$exercise".',
        );
      }
    }
  }

  String? _parseAiWeeklyNullableText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String _parseAiWeeklyPlanYmd(
    String value, {
    required int lineNo,
    required String field,
  }) {
    final trimmed = value.trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) {
      throw StateError('Line $lineNo: $field must be YYYY-MM-DD.');
    }
    final parsed = DateTime.tryParse('${trimmed}T00:00:00');
    if (parsed == null || toYmd(parsed) != trimmed) {
      throw StateError('Line $lineNo: $field is not a valid date.');
    }
    return trimmed;
  }

  _ParsedPlannedStrengthRow _parseAiWeeklyPlanStrengthSet(
    String payload, {
    required int lineNo,
  }) {
    final parts = payload
        .split('|')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      throw StateError('Line $lineNo: STRENGTH_SET is empty.');
    }
    final exerciseCanonical = ExerciseNormalizer.normalize(parts.first);
    if (exerciseCanonical.isEmpty) {
      throw StateError('Line $lineNo: STRENGTH_SET missing exercise name.');
    }

    final kv = _parseAiWeeklyKeyValueParts(
      parts.skip(1).toList(),
      lineNo: lineNo,
      context: 'STRENGTH_SET',
    );
    final setIndex = _parseAiWeeklyRequiredInt(
      kv,
      key: 'set',
      lineNo: lineNo,
      context: 'STRENGTH_SET',
      min: 1,
    );
    final weight = _parseAiWeeklyOptionalDouble(
      kv['weight'],
      lineNo: lineNo,
      context: 'STRENGTH_SET.weight',
    );
    final reps = _parseAiWeeklyOptionalInt(
      kv['reps'],
      lineNo: lineNo,
      context: 'STRENGTH_SET.reps',
      min: 0,
    );
    final rir = _parseAiWeeklyOptionalInt(
      kv['rir'],
      lineNo: lineNo,
      context: 'STRENGTH_SET.rir',
      min: 0,
    );
    final unit = (kv['unit'] ?? '').trim().toLowerCase();
    const allowedUnits = {'lb', 'kg', 'bw', 'unknown'};
    if (!allowedUnits.contains(unit)) {
      throw StateError(
        'Line $lineNo: STRENGTH_SET.unit must be one of ${allowedUnits.join(', ')}.',
      );
    }

    return _ParsedPlannedStrengthRow(
      exerciseCanonical: exerciseCanonical,
      setIndex: setIndex,
      weight: weight,
      reps: reps,
      rir: rir,
      unit: unit,
      rawSetString: payload,
    );
  }

  _AiParsedPlanAlternative _parseAiWeeklyPlanAlternative(
    String payload, {
    required int lineNo,
  }) {
    final parts = payload
        .split('|')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      throw StateError('Line $lineNo: ALT row is empty.');
    }
    final prescribedExerciseCanonical =
        ExerciseNormalizer.normalize(parts.first);
    if (prescribedExerciseCanonical.isEmpty) {
      throw StateError('Line $lineNo: ALT missing prescribed exercise.');
    }
    final kv = _parseAiWeeklyKeyValueParts(
      parts.skip(1).toList(),
      lineNo: lineNo,
      context: 'ALT',
    );

    final rank = _parseAiWeeklyRequiredInt(
      kv,
      key: 'rank',
      lineNo: lineNo,
      context: 'ALT',
      min: 1,
    );
    final altExerciseRaw = (kv['exercise'] ?? '').trim();
    if (altExerciseRaw.isEmpty) {
      throw StateError('Line $lineNo: ALT.exercise is required.');
    }
    final altExerciseCanonical = ExerciseNormalizer.normalize(altExerciseRaw);
    final tier = (kv['tier'] ?? '').trim().toLowerCase();
    const allowedTiers = {'strong', 'acceptable', 'weak'};
    if (!allowedTiers.contains(tier)) {
      throw StateError(
        'Line $lineNo: ALT.tier must be one of ${allowedTiers.join(', ')}.',
      );
    }
    final rationale = (kv['rationale'] ?? '').trim();
    if (rationale.isEmpty) {
      throw StateError('Line $lineNo: ALT.rationale is required.');
    }
    final notes = _parseAiWeeklyNullableText(kv['notes'] ?? '');

    return _AiParsedPlanAlternative(
      prescribedExerciseCanonical: prescribedExerciseCanonical,
      alternativeExerciseCanonical: altExerciseCanonical,
      rank: rank,
      tier: tier,
      rationale: rationale,
      notes: notes,
    );
  }

  Map<String, String> _parseAiWeeklyKeyValueParts(
    List<String> parts, {
    required int lineNo,
    required String context,
  }) {
    final result = <String, String>{};
    for (final part in parts) {
      final equalsIndex = part.indexOf('=');
      if (equalsIndex <= 0) {
        throw StateError('Line $lineNo: malformed $context token "$part".');
      }
      final key = part.substring(0, equalsIndex).trim().toLowerCase();
      final value = part.substring(equalsIndex + 1).trim();
      if (key.isEmpty) {
        throw StateError('Line $lineNo: malformed $context token "$part".');
      }
      if (result.containsKey(key)) {
        throw StateError('Line $lineNo: duplicate $context field "$key".');
      }
      result[key] = value;
    }
    return result;
  }

  int _parseAiWeeklyRequiredInt(
    Map<String, String> kv, {
    required String key,
    required int lineNo,
    required String context,
    int? min,
  }) {
    final raw = (kv[key] ?? '').trim();
    if (raw.isEmpty) {
      throw StateError('Line $lineNo: $context.$key is required.');
    }
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      throw StateError('Line $lineNo: $context.$key must be an integer.');
    }
    if (min != null && parsed < min) {
      throw StateError('Line $lineNo: $context.$key must be >= $min.');
    }
    return parsed;
  }

  int? _parseAiWeeklyOptionalInt(
    String? raw, {
    required int lineNo,
    required String context,
    int? min,
  }) {
    final trimmed = (raw ?? '').trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final parsed = int.tryParse(trimmed);
    if (parsed == null) {
      throw StateError('Line $lineNo: $context must be an integer or blank.');
    }
    if (min != null && parsed < min) {
      throw StateError('Line $lineNo: $context must be >= $min.');
    }
    return parsed;
  }

  double? _parseAiWeeklyOptionalDouble(
    String? raw, {
    required int lineNo,
    required String context,
  }) {
    final trimmed = (raw ?? '').trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      throw StateError('Line $lineNo: $context must be numeric or blank.');
    }
    return parsed;
  }

  List<List<dynamic>> _decodeRows(List<List>? rows) {
    if (rows == null) {
      return const <List<dynamic>>[];
    }
    return rows.map((row) => List<dynamic>.from(row)).toList();
  }

  List<List<dynamic>> _decodeExcelRows(Sheet? sheet) {
    if (sheet == null) {
      return const <List<dynamic>>[];
    }
    return sheet.rows.map((row) {
      return row.map<dynamic>((cell) {
        final value = cell?.value;
        if (value == null) {
          return null;
        }
        if (value is TextCellValue) {
          return value.value;
        }
        if (value is IntCellValue) {
          return value.value;
        }
        if (value is DoubleCellValue) {
          return value.value;
        }
        if (value is BoolCellValue) {
          return value.value;
        }
        if (value is DateCellValue) {
          return DateTime(
            value.year,
            value.month,
            value.day,
          );
        }
        return value.toString();
      }).toList(growable: false);
    }).toList(growable: false);
  }

  _ParsedDailyPlan _parseDailyPlanSheet({
    required int dayNumber,
    required String sheetName,
    required List<List<dynamic>> rows,
    String? summarySession,
  }) {
    String? estimatedDate;
    if (rows.isNotEmpty &&
        _cleanString(_cellValue(rows, 0, 0))?.toLowerCase() == 'date') {
      estimatedDate = _parseYmdLike(_cellValue(rows, 0, 1));
    }

    final dayLabel = _cleanString(_cellValue(rows, 2, 0));
    final liftFocus = _cleanString(_cellValue(rows, 2, 1));
    final runType = _cleanString(_cellValue(rows, 2, 2));
    final durationText = _cleanString(_cellValue(rows, 2, 3));
    final targetPace = _cleanString(_cellValue(rows, 2, 4));
    final effort = _cleanString(_cellValue(rows, 2, 5));
    final notes = _cleanString(_cellValue(rows, 2, 6));
    final sessionType = _deriveSessionType(
      sheetName: sheetName,
      dayLabel: dayLabel,
      liftFocus: liftFocus,
      summarySession: summarySession,
    );

    var headerRowIndex = -1;
    var exerciseColumn = -1;
    final setColumns = <int>[];
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      for (var c = 0; c < row.length; c++) {
        final value = _cleanString(_cellValue(rows, r, c));
        if (value?.toLowerCase() == 'exercise') {
          headerRowIndex = r;
          exerciseColumn = c;
          for (var sc = c + 1; sc < row.length; sc++) {
            final header = _cleanString(_cellValue(rows, r, sc)) ?? '';
            if (header.toLowerCase().startsWith('set ')) {
              setColumns.add(sc);
            }
          }
          break;
        }
      }
      if (headerRowIndex != -1) {
        break;
      }
    }

    if (headerRowIndex == -1 || exerciseColumn == -1 || setColumns.isEmpty) {
      throw StateError(
          '[$sheetName] missing strength header row (Exercise + Set columns).');
    }

    final strengthRows = <_ParsedPlannedStrengthRow>[];
    for (var r = headerRowIndex + 1; r < rows.length; r++) {
      final exerciseRaw =
          _cleanString(_cellValue(rows, r, exerciseColumn)) ?? '';
      if (exerciseRaw.isEmpty) {
        continue;
      }
      final lower = exerciseRaw.toLowerCase();
      if (lower.contains('run results') ||
          lower.contains('strength results') ||
          lower.contains('exercise alternatives')) {
        break;
      }
      if (lower.contains('auto-progression')) {
        continue;
      }

      final exercise = ExerciseNormalizer.normalize(exerciseRaw);
      for (var i = 0; i < setColumns.length; i++) {
        final setText = _cleanString(_cellValue(rows, r, setColumns[i]));
        if (setText == null) {
          continue;
        }
        final parsed = _parsePlannedSetCell(setText);
        strengthRows.add(
          _ParsedPlannedStrengthRow(
            exerciseCanonical: exercise,
            setIndex: i + 1,
            weight: parsed.weight,
            reps: parsed.reps,
            rir: parsed.rir,
            unit: parsed.unit,
            rawSetString: parsed.raw,
          ),
        );
      }
    }

    final alternatives = _parseDailyPlanAlternativesSection(
      sheetName: sheetName,
      rows: rows,
      prescribedExercises: strengthRows.map((e) => e.exerciseCanonical).toSet(),
    );

    return _ParsedDailyPlan(
      dayNumber: dayNumber,
      sheetName: sheetName,
      estimatedDate: estimatedDate,
      sessionType: sessionType,
      dayLabel: dayLabel,
      liftFocus: liftFocus,
      runType: runType,
      durationText: durationText,
      targetPace: targetPace,
      effortHrGuardrails: effort,
      notes: notes,
      strengthRows: strengthRows,
      alternatives: alternatives,
      rawRows: rows,
    );
  }

  List<_AiParsedPlanAlternative> _parseDailyPlanAlternativesSection({
    required String sheetName,
    required List<List<dynamic>> rows,
    required Set<String> prescribedExercises,
  }) {
    var headerRowIndex = -1;
    var prescribedCol = -1;
    var altExerciseCol = -1;
    var rankCol = -1;
    var priorityCol = -1;
    var tierCol = -1;
    var rationaleCol = -1;
    var notesCol = -1;
    var sawAlternativesTitle = false;

    for (var r = 0; r < rows.length; r++) {
      final firstCell =
          (_cleanString(_cellValue(rows, r, 0)) ?? '').toLowerCase();
      if (firstCell.contains('exercise alternatives') ||
          firstCell.contains('substitute suggestions')) {
        sawAlternativesTitle = true;
      }

      final row = rows[r];
      var rowPrescribedCol = -1;
      var rowAltCol = -1;
      var rowRankCol = -1;
      var rowPriorityCol = -1;
      var rowTierCol = -1;
      var rowRationaleCol = -1;
      var rowNotesCol = -1;
      for (var c = 0; c < row.length; c++) {
        final header =
            (_cleanString(_cellValue(rows, r, c)) ?? '').toLowerCase();
        if (header.isEmpty) {
          continue;
        }
        if (header.contains('prescribed') && header.contains('exercise')) {
          rowPrescribedCol = c;
        } else if (header.contains('alternative') &&
            header.contains('exercise')) {
          rowAltCol = c;
        } else if (header == 'rank' ||
            header.endsWith(' rank') ||
            header.contains('alt rank')) {
          rowRankCol = c;
        } else if (header.contains('priority')) {
          rowPriorityCol = c;
        } else if (header == 'tier' || header.contains(' tier')) {
          rowTierCol = c;
        } else if (header.contains('rationale')) {
          rowRationaleCol = c;
        } else if (header.contains('note')) {
          rowNotesCol = c;
        }
      }

      if (rowPrescribedCol != -1 && rowAltCol != -1) {
        headerRowIndex = r;
        prescribedCol = rowPrescribedCol;
        altExerciseCol = rowAltCol;
        rankCol = rowRankCol;
        priorityCol = rowPriorityCol;
        tierCol = rowTierCol;
        rationaleCol = rowRationaleCol;
        notesCol = rowNotesCol;
        break;
      }
    }

    if (headerRowIndex == -1) {
      return const <_AiParsedPlanAlternative>[];
    }

    if (sawAlternativesTitle == false) {
      // Allow header-only sections for manually edited workbooks.
    }

    final result = <_AiParsedPlanAlternative>[];
    final altKeySet = <String>{};
    final ranksByPrescribed = <String, Set<int>>{};
    final nextRankByPrescribed = <String, int>{};

    for (var r = headerRowIndex + 1; r < rows.length; r++) {
      final firstCell =
          (_cleanString(_cellValue(rows, r, 0)) ?? '').toLowerCase();
      if (firstCell.contains('run results') ||
          firstCell.contains('strength results')) {
        break;
      }
      if (firstCell.contains('exercise alternatives') ||
          firstCell.contains('substitute suggestions')) {
        break;
      }

      final prescribedRaw = _cleanString(_cellValue(rows, r, prescribedCol));
      final altRaw = _cleanString(_cellValue(rows, r, altExerciseCol));
      final rankRaw = rankCol == -1 ? null : _cellValue(rows, r, rankCol);
      final priorityRaw =
          priorityCol == -1 ? null : _cellValue(rows, r, priorityCol);
      final tierRaw =
          tierCol == -1 ? null : _cleanString(_cellValue(rows, r, tierCol));
      final rationaleRaw = rationaleCol == -1
          ? null
          : _cleanString(_cellValue(rows, r, rationaleCol));
      final notesRaw =
          notesCol == -1 ? null : _cleanString(_cellValue(rows, r, notesCol));

      final hasAnyValue = prescribedRaw != null ||
          altRaw != null ||
          _cleanString(rankRaw) != null ||
          _cleanString(priorityRaw) != null ||
          tierRaw != null ||
          rationaleRaw != null ||
          notesRaw != null;
      if (!hasAnyValue) {
        continue;
      }

      if (prescribedRaw == null || altRaw == null) {
        throw StateError(
          '[$sheetName] alternatives row ${r + 1} must include Prescribed Exercise and Alternative Exercise.',
        );
      }

      final prescribed = ExerciseNormalizer.normalize(prescribedRaw);
      final alternative = ExerciseNormalizer.normalize(altRaw);
      if (!prescribedExercises.contains(prescribed)) {
        throw StateError(
          '[$sheetName] alternatives row ${r + 1} references unknown prescribed exercise "$prescribedRaw".',
        );
      }

      final parsedRank = _parseWorkbookOptionalInt(rankRaw);
      final parsedPriority = _parseWorkbookOptionalInt(priorityRaw);
      final nextRank = (nextRankByPrescribed[prescribed] ?? 0) + 1;
      final rank = (parsedRank != null && parsedRank > 0)
          ? parsedRank
          : (parsedPriority != null ? nextRank : nextRank);
      nextRankByPrescribed[prescribed] =
          rank > (nextRankByPrescribed[prescribed] ?? 0)
              ? rank
              : (nextRankByPrescribed[prescribed] ?? 0);

      final tierLower = (tierRaw ?? '').trim().toLowerCase();
      final tier = switch (tierLower) {
        'strong' => 'strong',
        'acceptable' => 'acceptable',
        'weak' => 'weak',
        _ => 'acceptable',
      };
      final rationale = rationaleRaw ?? 'Imported from standard workbook';
      final notes = notesRaw;

      final altKey = '$prescribed|$alternative';
      if (!altKeySet.add(altKey)) {
        throw StateError(
          '[$sheetName] duplicate alternative "$prescribedRaw -> $altRaw".',
        );
      }
      final rankSet = ranksByPrescribed.putIfAbsent(prescribed, () => <int>{});
      if (!rankSet.add(rank)) {
        throw StateError(
          '[$sheetName] duplicate alternative rank=$rank for "$prescribedRaw".',
        );
      }

      result.add(
        _AiParsedPlanAlternative(
          prescribedExerciseCanonical: prescribed,
          alternativeExerciseCanonical: alternative,
          rank: rank,
          tier: tier,
          rationale: rationale,
          notes: notes,
        ),
      );
    }

    return result;
  }

  int? _parseWorkbookOptionalInt(dynamic raw) {
    if (raw == null) {
      return null;
    }
    if (raw is int) {
      return raw;
    }
    if (raw is double) {
      final rounded = raw.round();
      if ((raw - rounded).abs() < 0.0000001) {
        return rounded;
      }
    }
    final text = _cleanString(raw);
    if (text == null) {
      return null;
    }
    return int.tryParse(text);
  }

  String _composeAlternativeNotes({
    required String tier,
    required String rationale,
    String? notes,
  }) {
    final noteParts = <String>[
      'tier=$tier',
      'rationale=$rationale',
    ];
    if (notes != null && notes.trim().isNotEmpty) {
      noteParts.add('notes=${notes.trim()}');
    }
    return noteParts.join(' | ');
  }

  _StoredAlternativeNoteParts _parseStoredAlternativeNotes(String? rawNotes) {
    final raw = rawNotes?.trim();
    if (raw == null || raw.isEmpty) {
      return const _StoredAlternativeNoteParts(
        tier: null,
        rationale: null,
        notes: null,
      );
    }

    String? tier;
    String? rationale;
    String? notes;
    final leftovers = <String>[];
    for (final token in raw.split('|')) {
      final piece = token.trim();
      if (piece.isEmpty) {
        continue;
      }
      final idx = piece.indexOf('=');
      if (idx <= 0) {
        leftovers.add(piece);
        continue;
      }
      final key = piece.substring(0, idx).trim().toLowerCase();
      final value = piece.substring(idx + 1).trim();
      switch (key) {
        case 'tier':
          if (tier == null || tier.isEmpty) {
            tier = value;
          } else {
            leftovers.add(piece);
          }
          break;
        case 'rationale':
          if (rationale == null || rationale.isEmpty) {
            rationale = value;
          } else {
            leftovers.add(piece);
          }
          break;
        case 'notes':
          if (notes == null || notes.isEmpty) {
            notes = value;
          } else {
            leftovers.add(piece);
          }
          break;
        default:
          leftovers.add(piece);
      }
    }
    if ((notes == null || notes.isEmpty) && leftovers.isNotEmpty) {
      notes = leftovers.join(' | ');
    }
    return _StoredAlternativeNoteParts(
      tier: tier,
      rationale: rationale,
      notes: notes,
    );
  }

  Map<int, String> _extractSummarySessionByDay(List<List<dynamic>> rows) {
    final result = <int, String>{};
    for (var i = 1; i < rows.length; i++) {
      final dayNumber = _extractDayNumber(_cellValue(rows, i, 0));
      final session = _cleanString(_cellValue(rows, i, 1));
      if (dayNumber == null || session == null) {
        continue;
      }
      result[dayNumber] = session;
    }
    return result;
  }

  List<String> _detectWorkbookConflicts({
    required List<List<dynamic>> summaryStrengthRows,
    required List<List<dynamic>> summaryRunRows,
    required List<_ParsedDailyPlan> parsedDays,
  }) {
    final conflicts = <String>[];
    final dailyByDay = <int, _ParsedDailyPlan>{
      for (final d in parsedDays) d.dayNumber: d,
    };

    final summaryRunByDay = <int, String>{};
    for (var i = 1; i < summaryRunRows.length; i++) {
      final dayNumber = _extractDayNumber(_cellValue(summaryRunRows, i, 0));
      final runType = _cleanString(_cellValue(summaryRunRows, i, 2));
      if (dayNumber == null || runType == null) {
        continue;
      }
      summaryRunByDay[dayNumber] = runType;
    }
    for (final entry in summaryRunByDay.entries) {
      final dailyRunType = dailyByDay[entry.key]?.runType;
      if (dailyRunType == null) {
        continue;
      }
      if (_normalizeComparable(entry.value) !=
          _normalizeComparable(dailyRunType)) {
        conflicts.add(
          '[run] Day ${entry.key}: summary run type "${entry.value}" != daily run type "$dailyRunType"',
        );
      }
    }

    final summaryStrengthByDay = <int, Set<String>>{};
    for (var i = 1; i < summaryStrengthRows.length; i++) {
      final dayNumber =
          _extractDayNumber(_cellValue(summaryStrengthRows, i, 0));
      final exercise = _cleanString(_cellValue(summaryStrengthRows, i, 2));
      if (dayNumber == null || exercise == null) {
        continue;
      }
      final bucket =
          summaryStrengthByDay.putIfAbsent(dayNumber, () => <String>{});
      bucket.add(ExerciseNormalizer.normalize(exercise));
    }
    for (var dayNumber = 1; dayNumber <= 7; dayNumber++) {
      final summaryExercises = summaryStrengthByDay[dayNumber] ?? <String>{};
      if (summaryExercises.isEmpty) {
        continue;
      }
      final dailyExercises = dailyByDay[dayNumber]
              ?.strengthRows
              .map((e) => e.exerciseCanonical)
              .toSet() ??
          <String>{};
      final missing = summaryExercises.difference(dailyExercises);
      final extra = dailyExercises.difference(summaryExercises);
      if (missing.isNotEmpty) {
        conflicts.add(
          '[strength] Day $dayNumber: missing from daily -> ${missing.toList()..sort()}',
        );
      }
      if (extra.isNotEmpty) {
        conflicts.add(
          '[strength] Day $dayNumber: extra in daily -> ${extra.toList()..sort()}',
        );
      }
    }

    return conflicts;
  }

  Future<String> _writeConflictReportWorkbook({
    required String filePath,
    required List<String> conflicts,
    required List<_ParsedDailyPlan> dailyPlans,
    required List<List<dynamic>> summaryStrengthRows,
    required List<List<dynamic>> summaryRunRows,
  }) async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != 'Conflicts') {
      excel.rename(defaultSheet, 'Conflicts');
    }

    final summarySheet = excel['Conflicts'];
    _setCell(summarySheet, 0, 0, TextCellValue('Conflict'));
    for (var i = 0; i < conflicts.length; i++) {
      _setCell(summarySheet, i + 1, 0, TextCellValue(conflicts[i]));
    }

    final byDayType = <String, List<String>>{};
    for (final conflict in conflicts) {
      final day = _extractDayNumber(conflict);
      if (day == null) {
        continue;
      }
      final type = conflict.startsWith('[run]') ? 'Run' : 'Strength';
      byDayType.putIfAbsent('$day|$type', () => <String>[]).add(conflict);
    }

    for (final entry in byDayType.entries) {
      final parts = entry.key.split('|');
      final dayNumber = int.parse(parts[0]);
      final type = parts[1];
      final sheetName = 'Conflict_Day${dayNumber}_$type';
      final sheet = excel[sheetName];

      var row = 0;
      _setCell(sheet, row++, 0, TextCellValue('Conflicts'));
      for (final message in entry.value) {
        _setCell(sheet, row++, 0, TextCellValue(message));
      }

      row++;
      _setCell(sheet, row++, 0, TextCellValue('Summary'));
      final summaryRows = type == 'Run'
          ? summaryRunRows
              .where(
                  (r) => _extractDayNumber(_cellValue([r], 0, 0)) == dayNumber)
              .toList()
          : summaryStrengthRows
              .where(
                  (r) => _extractDayNumber(_cellValue([r], 0, 0)) == dayNumber)
              .toList();
      for (final r in summaryRows) {
        for (var c = 0; c < r.length; c++) {
          final value = _cleanString(r[c]) ?? '';
          _setCell(sheet, row, c, TextCellValue(value));
        }
        row++;
      }

      row++;
      _setCell(sheet, row++, 0, TextCellValue('Daily'));
      final daily = dailyPlans.firstWhere((d) => d.dayNumber == dayNumber);
      if (type == 'Run') {
        final values = <String>[
          daily.dayLabel ?? '',
          daily.liftFocus ?? '',
          daily.runType ?? '',
          daily.durationText ?? '',
          daily.targetPace ?? '',
          daily.effortHrGuardrails ?? '',
          daily.notes ?? '',
        ];
        for (var c = 0; c < values.length; c++) {
          _setCell(sheet, row, c, TextCellValue(values[c]));
        }
      } else {
        _setCell(sheet, row, 0, TextCellValue('Exercise'));
        _setCell(sheet, row, 1, TextCellValue('Set'));
        _setCell(sheet, row, 2, TextCellValue('Raw'));
        row++;
        for (final s in daily.strengthRows) {
          _setCell(sheet, row, 0, TextCellValue(s.exerciseCanonical));
          _setCell(sheet, row, 1, TextCellValue(s.setIndex.toString()));
          _setCell(sheet, row, 2, TextCellValue(s.rawSetString));
          row++;
        }
      }
    }

    final file = File(
      p.join(
        p.dirname(filePath),
        'ConflictReport_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      ),
    );
    final encoded = excel.encode();
    if (encoded == null) {
      throw StateError('Failed to encode conflict workbook.');
    }
    await file.writeAsBytes(encoded, flush: true);
    return file.path;
  }

  Future<bool> _deletePlanCyclesOverlappingDateRange({
    required String rangeStartYmd,
    required String rangeEndYmd,
  }) async {
    final existing = await findOverlappingPlanCycles(
      rangeStartYmd: rangeStartYmd,
      rangeEndYmd: rangeEndYmd,
    );
    return _deletePlanCycles(existing);
  }

  Future<bool> _deletePlanCycles(List<PlanCycle> existing) async {
    if (existing.isEmpty) {
      return false;
    }

    for (final cycle in existing) {
      final dayRows = await (select(planDays)
            ..where((d) => d.planCycleId.equals(cycle.id)))
          .get();
      final dayIds = dayRows.map((d) => d.id).toList();

      if (dayIds.isNotEmpty) {
        await (delete(planExerciseAlternatives)
              ..where((a) => a.planDayId.isIn(dayIds)))
            .go();
        await (delete(planPrescribedStrengthSets)
              ..where((s) => s.planDayId.isIn(dayIds)))
            .go();
        await (delete(planPrescribedRuns)
              ..where((r) => r.planDayId.isIn(dayIds)))
            .go();
      }
      await (delete(planSummarySnapshots)
            ..where((s) => s.planCycleId.equals(cycle.id)))
          .go();
      await (delete(planDays)..where((d) => d.planCycleId.equals(cycle.id)))
          .go();
      await (delete(planCycles)..where((c) => c.id.equals(cycle.id))).go();
    }
    return true;
  }

  dynamic _cellValue(List<List<dynamic>> rows, int row, int col) {
    if (row < 0 || row >= rows.length) {
      return null;
    }
    final r = rows[row];
    if (col < 0 || col >= r.length) {
      return null;
    }
    return r[col];
  }

  String? _cleanString(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    if (text.isEmpty || text == '--') {
      return null;
    }
    return text;
  }

  String _normalizeComparable(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  int? _extractDayNumber(dynamic raw) {
    final text = _cleanString(raw);
    if (text == null) {
      return null;
    }
    final match = RegExp(r'(\d+)').firstMatch(text);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1)!);
  }

  String? _parseYmdLike(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return toYmd(value);
    }
    if (value is num) {
      final millis = (value.toDouble() * 24 * 3600 * 1000).round();
      final date = DateTime(1899, 12, 30).add(Duration(milliseconds: millis));
      return toYmd(date);
    }
    final raw = _cleanString(value);
    if (raw == null) {
      return null;
    }
    final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (parsed != null) {
      return toYmd(parsed);
    }
    return null;
  }

  _ParsedSetCell _parsePlannedSetCell(String value) {
    final normalized = value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final weighted = RegExp(r'^(\d+(?:\.\d+)?)\s*x\s*(\d+)(?:\s*r\s*(\d+))?$')
        .firstMatch(normalized);
    if (weighted != null) {
      return _ParsedSetCell(
        weight: double.tryParse(weighted.group(1)!),
        reps: int.tryParse(weighted.group(2)!),
        rir:
            weighted.group(3) == null ? null : int.tryParse(weighted.group(3)!),
        unit: 'lb',
        raw: value,
      );
    }
    final bw =
        RegExp(r'^bw\s*x\s*(\d+)(?:\s*r\s*(\d+))?$', caseSensitive: false)
            .firstMatch(normalized);
    if (bw != null) {
      return _ParsedSetCell(
        weight: null,
        reps: int.tryParse(bw.group(1)!),
        rir: bw.group(2) == null ? null : int.tryParse(bw.group(2)!),
        unit: 'bw',
        raw: value,
      );
    }
    final slashSide =
        RegExp(r'^(\d+)\s*/\s*side(?:\s*r\s*(\d+))?$', caseSensitive: false)
            .firstMatch(normalized);
    if (slashSide != null) {
      return _ParsedSetCell(
        weight: null,
        reps: int.tryParse(slashSide.group(1)!),
        rir: slashSide.group(2) == null
            ? null
            : int.tryParse(slashSide.group(2)!),
        unit: 'unknown',
        raw: value,
      );
    }
    final repsOnly = RegExp(r'^(\d+)(?:\s*r\s*(\d+))?$').firstMatch(normalized);
    if (repsOnly != null) {
      return _ParsedSetCell(
        weight: null,
        reps: int.tryParse(repsOnly.group(1)!),
        rir:
            repsOnly.group(2) == null ? null : int.tryParse(repsOnly.group(2)!),
        unit: 'unknown',
        raw: value,
      );
    }
    return _ParsedSetCell(
      weight: null,
      reps: null,
      rir: null,
      unit: 'unknown',
      raw: value,
    );
  }

  Expression<bool> _nullableDoubleEquals(
    GeneratedColumn<double> column,
    double? value,
  ) {
    if (value == null) {
      return column.isNull();
    }
    return column.equals(value);
  }

  Expression<bool> _nullableIntEquals(
    GeneratedColumn<int> column,
    int? value,
  ) {
    if (value == null) {
      return column.isNull();
    }
    return column.equals(value);
  }

  String? _rawSetFromFields({
    required double? weight,
    required int? reps,
    required int? rir,
  }) {
    if (weight == null || reps == null) {
      return null;
    }
    final weightText = weight == weight.roundToDouble()
        ? weight.toInt().toString()
        : weight.toString();
    if (rir == null) {
      return '${weightText}x$reps';
    }
    return '${weightText}x${reps}r$rir';
  }

  Future<void> upsertSleepNight({
    required String date,
    required int? totalSleepMin,
    required String source,
    int? startTime,
    int? endTime,
    int? remMin,
    int? deepMin,
    int? lightMin,
    int? awakeMin,
  }) async {
    final existing = await (select(sleepNights)
          ..where((s) => s.sleepDate.equals(date)))
        .getSingleOrNull();
    if (existing == null) {
      await into(sleepNights).insert(
        SleepNightsCompanion.insert(
          id: _uuid.v4(),
          sleepDate: date,
          source: source,
          totalSleepMin: Value(totalSleepMin),
          startTime: Value(startTime),
          endTime: Value(endTime),
          remMin: Value(remMin),
          deepMin: Value(deepMin),
          lightMin: Value(lightMin),
          awakeMin: Value(awakeMin),
        ),
      );
      return;
    }

    await (update(sleepNights)..where((s) => s.id.equals(existing.id))).write(
      SleepNightsCompanion(
        totalSleepMin: Value(totalSleepMin),
        source: Value(source),
        startTime: Value(startTime),
        endTime: Value(endTime),
        remMin: Value(remMin),
        deepMin: Value(deepMin),
        lightMin: Value(lightMin),
        awakeMin: Value(awakeMin),
      ),
    );
  }

  Future<SleepNight?> getSleepNightByDate(String date) {
    return (select(sleepNights)..where((s) => s.sleepDate.equals(date)))
        .getSingleOrNull();
  }

  Future<List<WorkoutDay>> listWorkoutDays({bool desc = true}) {
    final query = select(workoutDays)
      ..orderBy([
        (t) => OrderingTerm(
            expression: t.workoutDate,
            mode: desc ? OrderingMode.desc : OrderingMode.asc),
      ]);
    return query.get();
  }

  Future<List<RunSession>> listRunsByDate(String ymd) async {
    final day = await (select(workoutDays)
          ..where((d) => d.workoutDate.equals(ymd)))
        .getSingleOrNull();
    if (day == null) {
      return const <RunSession>[];
    }

    return (select(runSessions)
          ..where((r) => r.workoutDayId.equals(day.id))
          ..orderBy([
            (r) => OrderingTerm(expression: r.startTime, mode: OrderingMode.asc)
          ]))
        .get();
  }

  Future<void> insertRuleTrigger({
    required String triggerDate,
    required String ruleCode,
    required bool triggered,
    required Map<String, dynamic> details,
  }) async {
    await into(ruleTriggers).insert(
      RuleTriggersCompanion.insert(
        id: _uuid.v4(),
        triggerDate: triggerDate,
        ruleCode: ruleCode,
        triggered: triggered,
        detailsJson: jsonEncode(details),
        createdAt: unixMsNow(),
      ),
    );
  }

  Future<void> insertAiAudit({
    required int requestedAt,
    required String? dateWindowStart,
    required String? dateWindowEnd,
    required Map<String, dynamic> inputSnapshot,
    required Map<String, dynamic> response,
    required bool schemaValid,
    String? notes,
  }) async {
    await into(aiAudit).insert(
      AiAuditCompanion.insert(
        id: _uuid.v4(),
        requestedAt: requestedAt,
        dateWindowStart: Value(dateWindowStart),
        dateWindowEnd: Value(dateWindowEnd),
        inputSnapshotJson: jsonEncode(inputSnapshot),
        responseJson: jsonEncode(response),
        schemaValid: schemaValid,
        notes: Value(notes),
      ),
    );
  }

  Future<WorkoutDayDetail> getWorkoutDayDetail(String dateString) async {
    final dayRows = await (select(workoutDays)
          ..where((d) => d.workoutDate.equals(dateString))
          ..orderBy([
            (d) =>
                OrderingTerm(expression: d.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
    final day = dayRows.isEmpty ? null : dayRows.first;
    PlanDay? matchedPlanDay =
        await _getPreferredPlanDayByEstimatedDate(dateString);
    PlanCycle? activeCycle;
    if (matchedPlanDay != null) {
      final cycleId = matchedPlanDay.planCycleId;
      activeCycle = await (select(planCycles)
            ..where((c) => c.id.equals(cycleId)))
          .getSingleOrNull();
    } else {
      activeCycle = await getActivePlanCycleForDate(dateString);
      if (activeCycle != null) {
        final cycleId = activeCycle.id;
        final cycleWeekStart = activeCycle.weekStart;
        final dayNumber =
            parseYmd(dateString).difference(parseYmd(cycleWeekStart)).inDays +
                1;
        if (dayNumber >= 1 && dayNumber <= 7) {
          final planDayRows = await (select(planDays)
                ..where((d) => d.planCycleId.equals(cycleId))
                ..where((d) => d.dayNumber.equals(dayNumber))
                ..orderBy([
                  (d) => OrderingTerm(
                      expression: d.createdAt, mode: OrderingMode.desc),
                ]))
              .get();
          matchedPlanDay = planDayRows.isEmpty ? null : planDayRows.first;
        }
      }
    }
    matchedPlanDay ??= await _getLatestPlanDayByEstimatedDate(dateString);
    if (activeCycle == null && matchedPlanDay != null) {
      activeCycle = await (select(planCycles)
            ..where((c) => c.id.equals(matchedPlanDay!.planCycleId)))
          .getSingleOrNull();
    }

    final matchedPlanDayId = matchedPlanDay?.id;
    final plannedSets = matchedPlanDayId == null
        ? const <PlanPrescribedStrengthSet>[]
        : await (select(planPrescribedStrengthSets)
              ..where((s) => s.planDayId.equals(matchedPlanDayId))
              ..orderBy([
                (s) => OrderingTerm(
                    expression: s.createdAt, mode: OrderingMode.asc),
              ]))
            .get();
    PlanPrescribedRun? plannedRun;
    if (matchedPlanDayId != null) {
      final rows = await (select(planPrescribedRuns)
            ..where((r) => r.planDayId.equals(matchedPlanDayId))
            ..orderBy([
              (r) => OrderingTerm(
                  expression: r.createdAt, mode: OrderingMode.desc),
            ]))
          .get();
      plannedRun = rows.isEmpty ? null : rows.first;
    }
    final resolvedPlanSessionType = _resolveDisplaySessionType(
      storedSessionType: matchedPlanDay?.sessionType,
      plannedSets: plannedSets,
    );
    final prescribedRunView = plannedRun == null
        ? null
        : PrescribedRunPlan(
            dayLabel: plannedRun.dayLabel,
            liftFocus: plannedRun.liftFocus,
            runType: plannedRun.runType,
            durationText: plannedRun.durationText,
            targetPace: plannedRun.targetPace,
            effortHrGuardrails: plannedRun.effortHrGuardrails,
            notes: plannedRun.notes,
          );

    final sleeps = await (select(sleepNights)
          ..where((s) => s.sleepDate.equals(dateString)))
        .get();
    final triggers = await (select(ruleTriggers)
          ..where((r) => r.triggerDate.equals(dateString)))
        .get();
    final substitutions = day == null
        ? const <ExerciseSubstitution>[]
        : await (select(exerciseSubstitutions)
              ..where((s) => s.workoutDayId.equals(day.id))
              ..orderBy([
                (s) => OrderingTerm(
                    expression: s.createdAt, mode: OrderingMode.desc),
              ]))
            .get();

    if (day == null) {
      final fallbackGroups = _groupsFromPlannedAndActual(
        plannedRows: plannedSets,
        legacyRows: const <PrescribedStrengthSet>[],
        actualRows: const <ActualStrengthSet>[],
        substitutions: substitutions,
      );
      return WorkoutDayDetail(
        date: dateString,
        workoutDay: null,
        planCycleId: activeCycle?.id,
        planDayId: matchedPlanDayId,
        planDayNumber: matchedPlanDay?.dayNumber,
        planSessionType: resolvedPlanSessionType,
        prescribedRun: prescribedRunView,
        sleepNights: sleeps,
        runSessions: const <RunSessionWithSegments>[],
        groups: fallbackGroups,
        ruleTriggers: triggers,
        aiAudits: await _findAiAuditsForDate(dateString),
        runOverrideAudits: const <RunOverrideAuditData>[],
      );
    }

    final actual = await (select(actualStrengthSets)
          ..where((a) => a.workoutDayId.equals(day.id))
          ..orderBy([
            (a) =>
                OrderingTerm(expression: a.createdAt, mode: OrderingMode.asc),
            (a) => OrderingTerm(expression: a.setIndex, mode: OrderingMode.asc),
          ]))
        .get();
    final legacyPrescribed = await (select(prescribedStrengthSets)
          ..where((p) => p.workoutDayId.equals(day.id))
          ..orderBy([
            (p) => OrderingTerm(expression: p.setIndex, mode: OrderingMode.asc),
          ]))
        .get();
    final runs = await (select(runSessions)
          ..where((r) => r.workoutDayId.equals(day.id))
          ..orderBy([
            (r) => OrderingTerm(expression: r.startTime, mode: OrderingMode.asc)
          ]))
        .get();
    final runAudits = await (select(runOverrideAudit)
          ..where((a) => a.workoutDayId.equals(day.id)))
        .get();

    final runIds = runs.map((r) => r.id).toSet();
    final runKeysWithOverride = runAudits.map((a) => a.runKey).toSet();
    final detailsByRunId = <String, RunSessionDetail>{};

    if (runIds.isNotEmpty) {
      final details = await (select(runSessionDetails)
            ..where((d) => d.runSessionId.isIn(runIds)))
          .get();
      for (final detail in details) {
        detailsByRunId[detail.runSessionId] = detail;
      }
    }

    final runWithSegments = <RunSessionWithSegments>[];
    for (final run in runs) {
      final segments = await (select(runSegments)
            ..where((s) => s.runSessionId.equals(run.id))
            ..orderBy([(t) => OrderingTerm.asc(t.idx)]))
          .get();
      runWithSegments.add(
        RunSessionWithSegments(
          session: run,
          segments: segments,
          details: detailsByRunId[run.id],
          overrodeManual: runKeysWithOverride.contains(run.runKey),
        ),
      );
    }

    final grouped = _groupsFromPlannedAndActual(
      plannedRows: plannedSets,
      legacyRows: legacyPrescribed,
      actualRows: actual,
      substitutions: substitutions,
    );

    return WorkoutDayDetail(
      date: dateString,
      workoutDay: day,
      planCycleId: activeCycle?.id,
      planDayId: matchedPlanDayId,
      planDayNumber: matchedPlanDay?.dayNumber,
      planSessionType: resolvedPlanSessionType,
      prescribedRun: prescribedRunView,
      sleepNights: sleeps,
      runSessions: runWithSegments,
      groups: grouped,
      ruleTriggers: triggers,
      aiAudits: await _findAiAuditsForDate(dateString),
      runOverrideAudits: runAudits,
    );
  }

  Future<List<AiAuditData>> _findAiAuditsForDate(String dateString) async {
    final all = await select(aiAudit).get();
    return all.where((entry) {
      final start = entry.dateWindowStart;
      final end = entry.dateWindowEnd;
      if (start != null && dateString.compareTo(start) < 0) {
        return false;
      }
      if (end != null && dateString.compareTo(end) > 0) {
        return false;
      }
      return true;
    }).toList();
  }

  List<ExerciseSetGroup> _groupsFromPlannedAndActual({
    required List<PlanPrescribedStrengthSet> plannedRows,
    required List<PrescribedStrengthSet> legacyRows,
    required List<ActualStrengthSet> actualRows,
    required List<ExerciseSubstitution> substitutions,
  }) {
    final byExercise = <String, ExerciseSetGroup>{};
    final substitutionByPrescribed = <String, ExerciseSubstitutionView>{
      for (final row in substitutions)
        row.prescribedExerciseCanonical: ExerciseSubstitutionView(
          id: row.id,
          prescribedExerciseCanonical: row.prescribedExerciseCanonical,
          substituteExerciseCanonical: row.substituteExerciseCanonical,
          reasonCode: row.reasonCode,
          reasonNotes: row.reasonNotes,
          matchScore: row.matchScore,
          matchExplanationJson: row.matchExplanationJson,
          warningAcknowledged: row.warningAcknowledged,
          selectedAt: row.selectedAt,
        ),
    };

    if (plannedRows.isNotEmpty) {
      for (final row in plannedRows) {
        final current = byExercise[row.exerciseCanonical] ??
            ExerciseSetGroup(
              exercise: row.exerciseCanonical,
              displayExercise: substitutionByPrescribed[row.exerciseCanonical]
                      ?.substituteExerciseCanonical ??
                  row.exerciseCanonical,
              prescribed: const <PlannedStrengthSetView>[],
              substitution: substitutionByPrescribed[row.exerciseCanonical],
              actual: const <ActualStrengthSet>[],
            );
        byExercise[row.exerciseCanonical] = ExerciseSetGroup(
          exercise: current.exercise,
          displayExercise: current.displayExercise,
          prescribed: [
            ...current.prescribed,
            PlannedStrengthSetView(
              setIndex: row.setIndex,
              weight: row.weight,
              reps: row.reps,
              rir: row.rir,
              unit: row.unit,
            ),
          ]..sort((a, b) => a.setIndex.compareTo(b.setIndex)),
          substitution: current.substitution,
          actual: current.actual,
        );
      }
    } else {
      for (final row in legacyRows) {
        final current = byExercise[row.exerciseCanonical] ??
            ExerciseSetGroup(
              exercise: row.exerciseCanonical,
              displayExercise: substitutionByPrescribed[row.exerciseCanonical]
                      ?.substituteExerciseCanonical ??
                  row.exerciseCanonical,
              prescribed: const <PlannedStrengthSetView>[],
              substitution: substitutionByPrescribed[row.exerciseCanonical],
              actual: const <ActualStrengthSet>[],
            );
        byExercise[row.exerciseCanonical] = ExerciseSetGroup(
          exercise: current.exercise,
          displayExercise: current.displayExercise,
          prescribed: [
            ...current.prescribed,
            PlannedStrengthSetView(
              setIndex: row.setIndex,
              weight: row.weight,
              reps: row.reps,
              rir: row.rir,
              unit: row.unit,
            ),
          ]..sort((a, b) => a.setIndex.compareTo(b.setIndex)),
          substitution: current.substitution,
          actual: current.actual,
        );
      }
    }

    for (final row in actualRows) {
      final key = row.prescribedExerciseCanonical ?? row.exerciseCanonical;
      final current = byExercise[key] ??
          ExerciseSetGroup(
            exercise: key,
            displayExercise:
                substitutionByPrescribed[key]?.substituteExerciseCanonical ??
                    key,
            prescribed: const <PlannedStrengthSetView>[],
            substitution: substitutionByPrescribed[key],
            actual: const <ActualStrengthSet>[],
          );
      byExercise[key] = ExerciseSetGroup(
        exercise: current.exercise,
        displayExercise: current.displayExercise,
        prescribed: current.prescribed,
        substitution: current.substitution,
        actual: [...current.actual, row]
          ..sort((a, b) => a.setIndex.compareTo(b.setIndex)),
      );
    }

    return byExercise.values.toList();
  }

  Map<String, dynamic> _snapshotFromRun(RunSession row) {
    return {
      'id': row.id,
      'run_key': row.runKey,
      'workout_day_id': row.workoutDayId,
      'plan_day_id': row.planDayId,
      'start_time': row.startTime,
      'end_time': row.endTime,
      'duration_s': row.durationS,
      'distance_m': row.distanceM,
      'avg_hr': row.avgHr,
      'max_hr': row.maxHr,
      'source': row.source,
      'source_priority': row.sourcePriority,
    };
  }

  Future<Map<String, String>> exportCsvs({String? outputDirectoryPath}) async {
    final targetDir = await _resolveExportDirectory(outputDirectoryPath);

    Future<String> writeCsv(String fileName, List<List<dynamic>> rows) async {
      final file = File(p.join(targetDir.path, fileName));
      await file.writeAsString(const ListToCsvConverter().convert(rows));
      return file.path;
    }

    final runsRows = <List<dynamic>>[
      [
        'id',
        'run_key',
        'workout_day_id',
        'plan_day_id',
        'start_time',
        'end_time',
        'duration_s',
        'distance_m',
        'avg_hr',
        'max_hr',
        'treadmill',
        'title',
        'activity_type',
        'calories',
        'moving_time_s',
        'elapsed_time_s',
        'source_priority',
        'import_file_name',
        'raw_metrics_json',
        'source'
      ]
    ];
    for (final row in await select(runSessions).get()) {
      runsRows.add([
        row.id,
        row.runKey,
        row.workoutDayId,
        row.planDayId,
        row.startTime,
        row.endTime,
        row.durationS,
        row.distanceM,
        row.avgHr,
        row.maxHr,
        row.treadmill,
        row.title,
        row.activityType,
        row.calories,
        row.movingTimeS,
        row.elapsedTimeS,
        row.sourcePriority,
        row.importFileName,
        row.rawMetricsJson,
        row.source,
      ]);
    }

    final runDetailsRows = <List<dynamic>>[
      [
        'run_session_id',
        'favorite',
        'aerobic_te',
        'avg_run_cadence',
        'max_run_cadence',
        'avg_pace_s',
        'best_pace_s',
        'total_ascent',
        'total_descent',
        'avg_stride_length_m',
        'training_stress_score',
        'steps',
        'min_temp',
        'max_temp',
        'decompression',
        'best_lap_time_s',
        'number_of_laps',
        'min_elevation',
        'max_elevation',
        'raw_metrics_json'
      ]
    ];
    for (final row in await select(runSessionDetails).get()) {
      runDetailsRows.add([
        row.runSessionId,
        row.favorite,
        row.aerobicTe,
        row.avgRunCadence,
        row.maxRunCadence,
        row.avgPaceS,
        row.bestPaceS,
        row.totalAscent,
        row.totalDescent,
        row.avgStrideLengthM,
        row.trainingStressScore,
        row.steps,
        row.minTemp,
        row.maxTemp,
        row.decompression,
        row.bestLapTimeS,
        row.numberOfLaps,
        row.minElevation,
        row.maxElevation,
        row.rawMetricsJson,
      ]);
    }

    final runOverrideRows = <List<dynamic>>[
      [
        'id',
        'run_key',
        'workout_day_id',
        'old_source',
        'new_source',
        'old_snapshot_json',
        'new_snapshot_json',
        'reason',
        'created_at',
      ]
    ];
    for (final row in await select(runOverrideAudit).get()) {
      runOverrideRows.add([
        row.id,
        row.runKey,
        row.workoutDayId,
        row.oldSource,
        row.newSource,
        row.oldSnapshotJson,
        row.newSnapshotJson,
        row.reason,
        row.createdAt,
      ]);
    }

    final sleepRows = <List<dynamic>>[
      [
        'id',
        'sleep_date',
        'start_time',
        'end_time',
        'total_sleep_min',
        'rem_min',
        'deep_min',
        'light_min',
        'awake_min',
        'source'
      ]
    ];
    for (final row in await select(sleepNights).get()) {
      sleepRows.add([
        row.id,
        row.sleepDate,
        row.startTime,
        row.endTime,
        row.totalSleepMin,
        row.remMin,
        row.deepMin,
        row.lightMin,
        row.awakeMin,
        row.source,
      ]);
    }

    final actualRows = <List<dynamic>>[
      [
        'id',
        'workout_day_id',
        'plan_day_id',
        'performed_at',
        'exercise_canonical',
        'set_index',
        'weight',
        'reps',
        'rir',
        'unit',
        'source',
        'raw_set_string',
        'created_at'
      ]
    ];
    for (final row in await select(actualStrengthSets).get()) {
      actualRows.add([
        row.id,
        row.workoutDayId,
        row.planDayId,
        row.performedAt,
        row.exerciseCanonical,
        row.setIndex,
        row.weight,
        row.reps,
        row.rir,
        row.unit,
        row.source,
        row.rawSetString,
        row.createdAt,
      ]);
    }

    final prescribedRows = <List<dynamic>>[
      [
        'id',
        'workout_day_id',
        'exercise_canonical',
        'set_index',
        'weight',
        'reps',
        'rir',
        'unit'
      ]
    ];
    for (final row in await select(prescribedStrengthSets).get()) {
      prescribedRows.add([
        row.id,
        row.workoutDayId,
        row.exerciseCanonical,
        row.setIndex,
        row.weight,
        row.reps,
        row.rir,
        row.unit,
      ]);
    }

    final ruleRows = <List<dynamic>>[
      [
        'id',
        'trigger_date',
        'rule_code',
        'triggered',
        'details_json',
        'created_at'
      ]
    ];
    for (final row in await select(ruleTriggers).get()) {
      ruleRows.add([
        row.id,
        row.triggerDate,
        row.ruleCode,
        row.triggered,
        row.detailsJson,
        row.createdAt
      ]);
    }

    final aiRows = <List<dynamic>>[
      [
        'id',
        'requested_at',
        'date_window_start',
        'date_window_end',
        'input_snapshot_json',
        'response_json',
        'schema_valid',
        'notes'
      ]
    ];
    for (final row in await select(aiAudit).get()) {
      aiRows.add([
        row.id,
        row.requestedAt,
        row.dateWindowStart,
        row.dateWindowEnd,
        row.inputSnapshotJson,
        row.responseJson,
        row.schemaValid,
        row.notes,
      ]);
    }

    return {
      'Runs.csv': await writeCsv('Runs.csv', runsRows),
      'RunSessionDetails.csv':
          await writeCsv('RunSessionDetails.csv', runDetailsRows),
      'RunOverrideAudit.csv':
          await writeCsv('RunOverrideAudit.csv', runOverrideRows),
      'Sleep.csv': await writeCsv('Sleep.csv', sleepRows),
      'StrengthSets.csv': await writeCsv('StrengthSets.csv', actualRows),
      'PrescribedSets.csv':
          await writeCsv('PrescribedSets.csv', prescribedRows),
      'RuleTriggers.csv': await writeCsv('RuleTriggers.csv', ruleRows),
      'AiAudit.csv': await writeCsv('AiAudit.csv', aiRows),
    };
  }

  Future<String> exportStandardWorkbookXlsx({
    DateTime? anchorDate,
    String? outputDirectoryPath,
  }) async {
    final targetDir = await _resolveExportDirectory(outputDirectoryPath);
    final now = anchorDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final historyEndYmd = toYmd(today);
    final startOfCurrentWeek =
        today.subtract(Duration(days: today.weekday - 1));
    final previousWeekStart =
        startOfCurrentWeek.subtract(const Duration(days: 7));
    final previousWeekEnd = previousWeekStart.add(const Duration(days: 6));
    final previousWeekStartYmd = toYmd(previousWeekStart);
    final previousWeekEndYmd = toYmd(previousWeekEnd);
    final historyStartYmd = toYmd(today.subtract(const Duration(days: 20)));

    final excel = Excel.createExcel();
    final defaultSheetName = excel.getDefaultSheet();
    if (defaultSheetName != null && defaultSheetName != 'Strength Data') {
      excel.rename(defaultSheetName, 'Strength Data');
    }
    excel['Run Data'];
    excel['10 Week Plan'];

    final allDays = await select(workoutDays).get();
    final dayById = <String, String>{
      for (final day in allDays) day.id: day.workoutDate,
    };

    final strengthSheet = excel['Strength Data'];
    _setCell(strengthSheet, 0, 0, TextCellValue('Workout Date'));
    _setCell(strengthSheet, 0, 1, TextCellValue('Exercise'));
    _setCell(strengthSheet, 0, 2, TextCellValue('Set'));
    _setCell(strengthSheet, 0, 3, TextCellValue('Weight'));
    _setCell(strengthSheet, 0, 4, TextCellValue('Reps'));
    _setCell(strengthSheet, 0, 5, TextCellValue('RIR'));
    _setCell(strengthSheet, 0, 6, TextCellValue('Unit'));
    _setCell(strengthSheet, 0, 7, TextCellValue('Source'));
    _setCell(strengthSheet, 0, 8, TextCellValue('Raw Set String'));

    final allStrength = await (select(actualStrengthSets)
          ..orderBy([
            (s) =>
                OrderingTerm(expression: s.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
    var strengthRow = 1;
    for (final row in allStrength) {
      final workoutDate = dayById[row.workoutDayId];
      if (workoutDate == null) {
        continue;
      }
      if (workoutDate.compareTo(historyStartYmd) < 0 ||
          workoutDate.compareTo(historyEndYmd) > 0) {
        continue;
      }
      _setCell(strengthSheet, strengthRow, 0, TextCellValue(workoutDate));
      _setCell(
          strengthSheet, strengthRow, 1, TextCellValue(row.exerciseCanonical));
      _setCell(strengthSheet, strengthRow, 2, IntCellValue(row.setIndex));
      _setCell(strengthSheet, strengthRow, 3,
          TextCellValue(row.weight?.toString() ?? ''));
      _setCell(strengthSheet, strengthRow, 4,
          TextCellValue(row.reps?.toString() ?? ''));
      _setCell(strengthSheet, strengthRow, 5,
          TextCellValue(row.rir?.toString() ?? ''));
      _setCell(strengthSheet, strengthRow, 6, TextCellValue(row.unit));
      _setCell(strengthSheet, strengthRow, 7, TextCellValue(row.source));
      _setCell(
          strengthSheet, strengthRow, 8, TextCellValue(row.rawSetString ?? ''));
      strengthRow++;
    }

    final runSheet = excel['Run Data'];
    _setCell(runSheet, 0, 0, TextCellValue('Workout Date'));
    _setCell(runSheet, 0, 1, TextCellValue('Start Time'));
    _setCell(runSheet, 0, 2, TextCellValue('Duration (s)'));
    _setCell(runSheet, 0, 3, TextCellValue('Distance (m)'));
    _setCell(runSheet, 0, 4, TextCellValue('Avg HR'));
    _setCell(runSheet, 0, 5, TextCellValue('Max HR'));
    _setCell(runSheet, 0, 6, TextCellValue('Activity Type'));
    _setCell(runSheet, 0, 7, TextCellValue('Source'));
    _setCell(runSheet, 0, 8, TextCellValue('Run Key'));
    var runRow = 1;
    final runs = await (select(runSessions)
          ..orderBy([
            (r) =>
                OrderingTerm(expression: r.startTime, mode: OrderingMode.asc),
          ]))
        .get();
    for (final run in runs) {
      final workoutDate =
          run.workoutDayId == null ? null : dayById[run.workoutDayId!];
      if (workoutDate == null) {
        continue;
      }
      if (workoutDate.compareTo(historyStartYmd) < 0 ||
          workoutDate.compareTo(historyEndYmd) > 0) {
        continue;
      }
      final startTime = run.startTime == null
          ? ''
          : DateTime.fromMillisecondsSinceEpoch(run.startTime!)
              .toIso8601String();
      _setCell(runSheet, runRow, 0, TextCellValue(workoutDate));
      _setCell(runSheet, runRow, 1, TextCellValue(startTime));
      _setCell(
          runSheet, runRow, 2, TextCellValue(run.durationS?.toString() ?? ''));
      _setCell(
          runSheet, runRow, 3, TextCellValue(run.distanceM?.toString() ?? ''));
      _setCell(runSheet, runRow, 4, TextCellValue(run.avgHr?.toString() ?? ''));
      _setCell(runSheet, runRow, 5, TextCellValue(run.maxHr?.toString() ?? ''));
      _setCell(runSheet, runRow, 6, TextCellValue(run.activityType ?? ''));
      _setCell(runSheet, runRow, 7, TextCellValue(run.source));
      _setCell(runSheet, runRow, 8, TextCellValue(run.runKey));
      runRow++;
    }

    final activeCycle = await (select(planCycles)
          ..where((c) => c.weekStart.equals(previousWeekStartYmd))
          ..where((c) => c.weekEnd.equals(previousWeekEndYmd))
          ..orderBy([
            (c) =>
                OrderingTerm(expression: c.createdAt, mode: OrderingMode.desc)
          ]))
        .getSingleOrNull();

    Map<int, PlanDay> planDayByNumber = {};
    Map<String, List<PlanPrescribedStrengthSet>> planSetsByDayId = {};
    Map<String, PlanPrescribedRun> planRunByDayId = {};
    Map<String, List<PlanExerciseAlternative>> planAlternativesByDayId = {};
    Map<String, List<List<dynamic>>> snapshotsByTab = {};

    if (activeCycle != null) {
      final dayRows = await (select(planDays)
            ..where((d) => d.planCycleId.equals(activeCycle.id))
            ..orderBy([(d) => OrderingTerm.asc(d.dayNumber)]))
          .get();
      planDayByNumber = {for (final d in dayRows) d.dayNumber: d};
      final dayIds = dayRows.map((d) => d.id).toList();
      if (dayIds.isNotEmpty) {
        final planSets = await (select(planPrescribedStrengthSets)
              ..where((s) => s.planDayId.isIn(dayIds))
              ..orderBy([
                (s) =>
                    OrderingTerm(expression: s.setIndex, mode: OrderingMode.asc)
              ]))
            .get();
        for (final set in planSets) {
          final bucket = planSetsByDayId.putIfAbsent(
              set.planDayId, () => <PlanPrescribedStrengthSet>[]);
          bucket.add(set);
        }
        final runPlans = await (select(planPrescribedRuns)
              ..where((r) => r.planDayId.isIn(dayIds)))
            .get();
        for (final runPlan in runPlans) {
          planRunByDayId[runPlan.planDayId] = runPlan;
        }
        final altRows = await (select(planExerciseAlternatives)
              ..where((a) => a.planDayId.isIn(dayIds))
              ..orderBy([
                (a) => OrderingTerm(
                      expression: a.prescribedExerciseCanonical,
                      mode: OrderingMode.asc,
                    ),
                (a) => OrderingTerm(
                      expression: a.priority,
                      mode: OrderingMode.desc,
                    ),
                (a) => OrderingTerm(
                      expression: a.createdAt,
                      mode: OrderingMode.asc,
                    ),
              ]))
            .get();
        for (final alt in altRows) {
          final bucket = planAlternativesByDayId.putIfAbsent(
            alt.planDayId ?? '',
            () => <PlanExerciseAlternative>[],
          );
          bucket.add(alt);
        }
      }

      final snapshots = await (select(planSummarySnapshots)
            ..where((s) => s.planCycleId.equals(activeCycle.id)))
          .get();
      for (final snapshot in snapshots) {
        snapshotsByTab[snapshot.tabName] =
            _rowsFromSnapshotJson(snapshot.snapshotJson);
      }
    }

    final tenWeekPlanRows =
        snapshotsByTab['10 Week Plan'] ?? _generateTenWeekPlanRows();
    final strengthSummaryTabName =
        snapshotsByTab.containsKey('7-Day Push Pull Plan')
            ? '7-Day Push Pull Plan'
            : '5-Day Push Pull Plan';
    final strengthSummaryRows = snapshotsByTab[strengthSummaryTabName] ??
        snapshotsByTab['5-Day Push Pull Plan'] ??
        snapshotsByTab['7-Day Push Pull Plan'] ??
        _generateStrengthSummaryRows(planDayByNumber, planSetsByDayId);
    final runSummaryTabName = snapshotsByTab.containsKey('Run Plan - 5mi @ 8')
        ? 'Run Plan - 5mi @ 8'
        : 'Run Plan - 5mi @ 8 min';
    final runSummaryRows = snapshotsByTab['Run Plan - 5mi @ 8 min'] ??
        snapshotsByTab['Run Plan - 5mi @ 8'] ??
        _generateRunSummaryRows(planDayByNumber, planRunByDayId);
    _writeRows(excel['10 Week Plan'], tenWeekPlanRows);
    _writeTenWeekExportContext(
      sheet: excel['10 Week Plan'],
      tenWeekPlanRows: tenWeekPlanRows,
      exportWeekStart: previousWeekStartYmd,
      exportWeekEnd: previousWeekEndYmd,
    );
    _writeRows(excel[strengthSummaryTabName], strengthSummaryRows);
    _writeRows(excel[runSummaryTabName], runSummaryRows);

    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final dayNumber = dayOffset + 1;
      final planDay = planDayByNumber[dayNumber];
      final ymd = planDay?.estimatedDate ??
          toYmd(previousWeekStart.add(Duration(days: dayOffset)));
      final sheetName = planDay?.sheetName.isNotEmpty == true
          ? planDay!.sheetName
          : 'Day $dayNumber';
      final sheet = excel[sheetName];
      _setCell(sheet, 0, 0, TextCellValue('Date'));
      _setCell(sheet, 0, 1, TextCellValue(ymd));
      _setCell(sheet, 1, 0, TextCellValue('Auto-progression notes'));

      final detail = await getWorkoutDayDetail(ymd);
      final runPlan = planDay == null
          ? null
          : planRunByDayId[planDay.id] ??
              (detail.prescribedRun == null
                  ? null
                  : PlanPrescribedRun(
                      id: '',
                      planDayId: planDay.id,
                      dayLabel: detail.prescribedRun!.dayLabel,
                      liftFocus: detail.prescribedRun!.liftFocus,
                      runType: detail.prescribedRun!.runType,
                      durationText: detail.prescribedRun!.durationText,
                      targetPace: detail.prescribedRun!.targetPace,
                      effortHrGuardrails:
                          detail.prescribedRun!.effortHrGuardrails,
                      notes: detail.prescribedRun!.notes,
                      createdAt: 0,
                    ));

      _setCell(sheet, 2, 0, TextCellValue('Day $dayNumber'));
      _setCell(sheet, 2, 1, TextCellValue(runPlan?.liftFocus ?? ''));
      _setCell(sheet, 2, 2, TextCellValue(runPlan?.runType ?? ''));
      _setCell(sheet, 2, 3, TextCellValue(runPlan?.durationText ?? ''));
      _setCell(sheet, 2, 4, TextCellValue(runPlan?.targetPace ?? ''));
      _setCell(sheet, 2, 5, TextCellValue(runPlan?.effortHrGuardrails ?? ''));
      _setCell(sheet, 2, 6, TextCellValue(runPlan?.notes ?? ''));

      final plannedByExercise = <String, List<PlanPrescribedStrengthSet>>{};
      for (final row in (planDay == null
          ? const <PlanPrescribedStrengthSet>[]
          : planSetsByDayId[planDay.id] ??
              const <PlanPrescribedStrengthSet>[])) {
        final bucket = plannedByExercise.putIfAbsent(
            row.exerciseCanonical, () => <PlanPrescribedStrengthSet>[]);
        bucket.add(row);
      }

      var maxSetIndex = 4;
      for (final sets in plannedByExercise.values) {
        for (final row in sets) {
          if (row.setIndex > maxSetIndex) {
            maxSetIndex = row.setIndex;
          }
        }
      }

      final headerRow = 4; // Row 5
      _setCell(sheet, headerRow, 0, TextCellValue('Exercise'));
      for (var setIdx = 1; setIdx <= maxSetIndex; setIdx++) {
        _setCell(
          sheet,
          headerRow,
          setIdx,
          TextCellValue('Set $setIdx (Wt x Reps)'),
        );
      }

      var rowCursor = headerRow + 1;
      final exerciseKeys = plannedByExercise.keys.toList()..sort();
      for (final exercise in exerciseKeys) {
        _setCell(sheet, rowCursor, 0, TextCellValue(exercise));
        final bySet = {
          for (final s in plannedByExercise[exercise]!) s.setIndex: s,
        };
        for (var setIdx = 1; setIdx <= maxSetIndex; setIdx++) {
          final set = bySet[setIdx];
          if (set != null) {
            _setCell(
              sheet,
              rowCursor,
              setIdx,
              TextCellValue(_formatPlannedSetForSheet(set)),
            );
          }
        }
        rowCursor++;
      }

      rowCursor += 1;
      _setCell(
        sheet,
        rowCursor,
        0,
        TextCellValue('Exercise Alternatives (Substitute Suggestions)'),
      );
      rowCursor += 1;
      _setCell(sheet, rowCursor, 0, TextCellValue('Prescribed Exercise'));
      _setCell(sheet, rowCursor, 1, TextCellValue('Rank'));
      _setCell(sheet, rowCursor, 2, TextCellValue('Alternative Exercise'));
      _setCell(sheet, rowCursor, 3, TextCellValue('Tier'));
      _setCell(sheet, rowCursor, 4, TextCellValue('Rationale'));
      _setCell(sheet, rowCursor, 5, TextCellValue('Notes'));
      rowCursor += 1;

      final dayAltRows = planDay == null
          ? const <PlanExerciseAlternative>[]
          : (planAlternativesByDayId[planDay.id] ??
              const <PlanExerciseAlternative>[]);
      final nextRankByPrescribed = <String, int>{};
      for (final alt in dayAltRows) {
        final meta = _parseStoredAlternativeNotes(alt.notes);
        final nextRank =
            (nextRankByPrescribed[alt.prescribedExerciseCanonical] ?? 0) + 1;
        nextRankByPrescribed[alt.prescribedExerciseCanonical] = nextRank;
        _setCell(
          sheet,
          rowCursor,
          0,
          TextCellValue(alt.prescribedExerciseCanonical),
        );
        _setCell(sheet, rowCursor, 1, IntCellValue(nextRank));
        _setCell(
          sheet,
          rowCursor,
          2,
          TextCellValue(alt.alternativeExerciseCanonical),
        );
        _setCell(sheet, rowCursor, 3, TextCellValue(meta.tier ?? ''));
        _setCell(sheet, rowCursor, 4, TextCellValue(meta.rationale ?? ''));
        _setCell(sheet, rowCursor, 5, TextCellValue(meta.notes ?? ''));
        rowCursor++;
      }

      rowCursor += 1;
      _setCell(sheet, rowCursor, 0, TextCellValue('Run Results (Actual)'));
      rowCursor += 1;
      _setCell(sheet, rowCursor, 0, TextCellValue('Start Time'));
      _setCell(sheet, rowCursor, 1, TextCellValue('Duration (s)'));
      _setCell(sheet, rowCursor, 2, TextCellValue('Distance (m)'));
      _setCell(sheet, rowCursor, 3, TextCellValue('Avg HR'));
      _setCell(sheet, rowCursor, 4, TextCellValue('Max HR'));
      _setCell(sheet, rowCursor, 5, TextCellValue('Source'));
      _setCell(sheet, rowCursor, 6, TextCellValue('Activity Type'));
      rowCursor += 1;

      for (final run in detail.runSessions) {
        final runDateTime = run.session.startTime == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(run.session.startTime!);
        _setCell(
          sheet,
          rowCursor,
          0,
          TextCellValue(runDateTime?.toIso8601String() ?? 'unknown'),
        );
        _setCell(
          sheet,
          rowCursor,
          1,
          TextCellValue(run.session.durationS?.toString() ?? 'unknown'),
        );
        _setCell(
          sheet,
          rowCursor,
          2,
          TextCellValue(run.session.distanceM?.toString() ?? 'unknown'),
        );
        _setCell(
          sheet,
          rowCursor,
          3,
          TextCellValue(run.session.avgHr?.toString() ?? 'unknown'),
        );
        _setCell(
          sheet,
          rowCursor,
          4,
          TextCellValue(run.session.maxHr?.toString() ?? 'unknown'),
        );
        _setCell(sheet, rowCursor, 5, TextCellValue(run.session.source));
        _setCell(
          sheet,
          rowCursor,
          6,
          TextCellValue(run.session.activityType ?? 'unknown'),
        );
        rowCursor++;
      }

      rowCursor += 1;
      _setCell(sheet, rowCursor, 0, TextCellValue('Strength Results (Actual)'));
      rowCursor += 1;
      _setCell(sheet, rowCursor, 0, TextCellValue('Exercise'));
      _setCell(sheet, rowCursor, 1, TextCellValue('Set'));
      _setCell(sheet, rowCursor, 2, TextCellValue('Weight'));
      _setCell(sheet, rowCursor, 3, TextCellValue('Reps'));
      _setCell(sheet, rowCursor, 4, TextCellValue('RIR'));
      _setCell(sheet, rowCursor, 5, TextCellValue('Unit'));
      _setCell(sheet, rowCursor, 6, TextCellValue('Source'));
      rowCursor += 1;

      for (final group in detail.groups) {
        for (final actual in group.actual) {
          _setCell(sheet, rowCursor, 0, TextCellValue(group.exercise));
          _setCell(
              sheet, rowCursor, 1, TextCellValue(actual.setIndex.toString()));
          _setCell(sheet, rowCursor, 2,
              TextCellValue(actual.weight?.toString() ?? ''));
          _setCell(sheet, rowCursor, 3,
              TextCellValue(actual.reps?.toString() ?? ''));
          _setCell(
              sheet, rowCursor, 4, TextCellValue(actual.rir?.toString() ?? ''));
          _setCell(sheet, rowCursor, 5, TextCellValue(actual.unit));
          _setCell(sheet, rowCursor, 6, TextCellValue(actual.source));
          rowCursor++;
        }
      }
    }

    await _recordPlanLongRangeWeekPerformanceSnapshot(
      exportWeekStart: previousWeekStartYmd,
      exportWeekEnd: previousWeekEndYmd,
      activeCycle: activeCycle,
      planDayByNumber: planDayByNumber,
      planSetsByDayId: planSetsByDayId,
      planRunByDayId: planRunByDayId,
      tenWeekPlanRows: tenWeekPlanRows,
    );

    final encoded = excel.encode();
    if (encoded == null) {
      throw StateError('Failed to encode workbook.');
    }
    final fileName = 'WeeklyExecution_wk_${previousWeekStartYmd}_to_'
        '${previousWeekEndYmd}__strength_${historyStartYmd}_to_'
        '${historyEndYmd}__run_${historyStartYmd}_to_'
        '$historyEndYmd.xlsx';
    final outFile = File(p.join(targetDir.path, fileName));
    await outFile.writeAsBytes(encoded, flush: true);
    return outFile.path;
  }

  @Deprecated(
      'Use exportStandardWorkbookXlsx. This wrapper is kept for backward compatibility.')
  Future<String> exportPreviousWeekExecutionWorkbook({
    String? outputDirectoryPath,
  }) {
    return exportStandardWorkbookXlsx(outputDirectoryPath: outputDirectoryPath);
  }

  Future<Directory> _resolveExportDirectory(String? outputDirectoryPath) async {
    if (outputDirectoryPath != null && outputDirectoryPath.trim().isNotEmpty) {
      final dir = Directory(outputDirectoryPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }

    final docs = await getApplicationDocumentsDirectory();
    return docs;
  }

  void _setCell(Sheet sheet, int row, int col, CellValue value) {
    sheet
        .cell(CellIndex.indexByColumnRow(rowIndex: row, columnIndex: col))
        .value = value;
  }

  List<List<dynamic>> _rowsFromSnapshotJson(String snapshotJson) {
    try {
      final decoded = jsonDecode(snapshotJson) as Map<String, dynamic>;
      final rows = decoded['rows'] as List<dynamic>? ?? const <dynamic>[];
      return rows
          .map((row) => (row as List<dynamic>)
              .map((cell) => cell == null ? '' : cell.toString())
              .toList())
          .toList();
    } catch (_) {
      return const <List<dynamic>>[];
    }
  }

  void _writeRows(Sheet sheet, List<List<dynamic>> rows) {
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      for (var c = 0; c < row.length; c++) {
        final value = row[c];
        if (value == null) {
          continue;
        }
        _setCell(sheet, r, c, TextCellValue(value.toString()));
      }
    }
  }

  List<List<dynamic>> _generateTenWeekPlanRows() {
    final rows = <List<dynamic>>[
      <dynamic>[
        'Week',
        'Week Start',
        'Week End',
        'Run Focus',
        'Strength Focus',
        'Strength Progression Expectation',
        'Primary Progression Target',
        'Recovery Emphasis',
        'Notes',
      ]
    ];
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    for (var i = 0; i < 10; i++) {
      final weekStart = startOfWeek.add(Duration(days: i * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));
      rows.add([
        'Week ${i + 1}',
        toYmd(weekStart),
        toYmd(weekEnd),
        '',
        '',
        '',
        '',
        '',
        '',
      ]);
    }
    return rows;
  }

  void _writeTenWeekExportContext({
    required Sheet sheet,
    required List<List<dynamic>> tenWeekPlanRows,
    required String exportWeekStart,
    required String exportWeekEnd,
  }) {
    final matchedWeekLabel = _findTenWeekWeekLabelForExport(
      tenWeekPlanRows: tenWeekPlanRows,
      exportWeekStart: exportWeekStart,
      exportWeekEnd: exportWeekEnd,
    );
    final matchedWeekNumber = matchedWeekLabel == null
        ? null
        : int.tryParse(
            RegExp(r'(\d+)').firstMatch(matchedWeekLabel)?.group(1) ?? '');

    // Write export context off to the right so the 10-week table shape remains unchanged.
    _setCell(sheet, 0, 10, TextCellValue('Export Context'));
    _setCell(sheet, 1, 10, TextCellValue('Exported Week Number'));
    _setCell(sheet, 1, 11, TextCellValue(matchedWeekNumber?.toString() ?? ''));
    _setCell(sheet, 2, 10, TextCellValue('Exported Week Label'));
    _setCell(sheet, 2, 11, TextCellValue(matchedWeekLabel ?? ''));
    _setCell(sheet, 3, 10, TextCellValue('Export Week Start'));
    _setCell(sheet, 3, 11, TextCellValue(exportWeekStart));
    _setCell(sheet, 4, 10, TextCellValue('Export Week End'));
    _setCell(sheet, 4, 11, TextCellValue(exportWeekEnd));
  }

  String? _findTenWeekWeekLabelForExport({
    required List<List<dynamic>> tenWeekPlanRows,
    required String exportWeekStart,
    required String exportWeekEnd,
  }) {
    for (var i = 1; i < tenWeekPlanRows.length; i++) {
      final row = tenWeekPlanRows[i];
      final weekLabel = row.isNotEmpty ? _cleanString(row[0]) : null;
      final weekStart = row.length > 1 ? _cleanString(row[1]) : null;
      final weekEnd = row.length > 2 ? _cleanString(row[2]) : null;
      if (weekStart == exportWeekStart && weekEnd == exportWeekEnd) {
        return weekLabel;
      }
    }
    return null;
  }

  _StrengthProgressionEvaluationResult _evaluateStrengthProgressionForWeek({
    required PlanLongRangeWeek? longRangeWeek,
    required Map<int, PlanDay> planDayByNumber,
    required Map<String, List<PlanPrescribedStrengthSet>> planSetsByDayId,
    required List<ActualStrengthSet> actualStrengthRows,
    required Map<String, String> workoutDateById,
  }) {
    final expectation =
        (longRangeWeek?.strengthProgressionExpectation ?? '').trim();
    if (expectation.isEmpty) {
      return const _StrengthProgressionEvaluationResult(
        evaluation: null,
        expectation: null,
        comparedSetCount: 0,
        metSetCount: 0,
        exceededSetCount: 0,
        underSetCount: 0,
        averageScore: null,
        expectedSetCount: 0,
        matchedSetCount: 0,
      );
    }

    final planDateByDayId = <String, String>{};
    for (final day in planDayByNumber.values) {
      final ymd = (day.estimatedDate ?? '').trim();
      if (ymd.isEmpty) {
        continue;
      }
      planDateByDayId[day.id] = ymd;
    }

    String planKey(String dateYmd, String exerciseCanonical, int setIndex) =>
        '$dateYmd|${ExerciseNormalizer.normalize(exerciseCanonical)}|$setIndex';

    final plannedByKey = <String, PlanPrescribedStrengthSet>{};
    for (final entry in planSetsByDayId.entries) {
      final planDate = planDateByDayId[entry.key];
      if (planDate == null) {
        continue;
      }
      for (final set in entry.value) {
        plannedByKey[planKey(planDate, set.exerciseCanonical, set.setIndex)] =
            set;
      }
    }
    if (plannedByKey.isEmpty) {
      return _StrengthProgressionEvaluationResult(
        evaluation: 'insufficient_data',
        expectation: expectation,
        comparedSetCount: 0,
        metSetCount: 0,
        exceededSetCount: 0,
        underSetCount: 0,
        averageScore: null,
        expectedSetCount: 0,
        matchedSetCount: 0,
      );
    }

    final bestScoreByPlanKey = <String, double>{};
    var matchedSetCount = 0;
    for (final actual in actualStrengthRows) {
      final workoutDate = workoutDateById[actual.workoutDayId];
      if (workoutDate == null || workoutDate.trim().isEmpty) {
        continue;
      }
      final prescribedCanonical =
          actual.prescribedExerciseCanonical ?? actual.exerciseCanonical;
      final key = planKey(workoutDate, prescribedCanonical, actual.setIndex);
      final planned = plannedByKey[key];
      if (planned == null) {
        continue;
      }
      matchedSetCount++;
      final score =
          _strengthSetAttainmentScore(planned: planned, actual: actual);
      if (score == null) {
        continue;
      }
      final existing = bestScoreByPlanKey[key];
      if (existing == null || score > existing) {
        bestScoreByPlanKey[key] = score;
      }
    }

    final comparedScores = bestScoreByPlanKey.values.toList(growable: false);
    if (comparedScores.isEmpty) {
      return _StrengthProgressionEvaluationResult(
        evaluation: 'insufficient_data',
        expectation: expectation,
        comparedSetCount: 0,
        metSetCount: 0,
        exceededSetCount: 0,
        underSetCount: 0,
        averageScore: null,
        expectedSetCount: plannedByKey.length,
        matchedSetCount: matchedSetCount,
      );
    }

    var metCount = 0;
    var exceededCount = 0;
    var underCount = 0;
    var scoreSum = 0.0;
    for (final score in comparedScores) {
      scoreSum += score;
      if (score > 1.03) {
        exceededCount++;
      } else if (score < 0.97) {
        underCount++;
      } else {
        metCount++;
      }
    }
    final avgScore = scoreSum / comparedScores.length;
    final coverage = plannedByKey.isEmpty
        ? 0.0
        : comparedScores.length / plannedByKey.length;

    String evaluation;
    if (coverage < 0.25) {
      evaluation = 'insufficient_data';
    } else if (avgScore > 1.03) {
      evaluation = 'exceeded';
    } else if (avgScore < 0.97) {
      evaluation = 'under';
    } else {
      evaluation = 'met';
    }

    return _StrengthProgressionEvaluationResult(
      evaluation: evaluation,
      expectation: expectation,
      comparedSetCount: comparedScores.length,
      metSetCount: metCount,
      exceededSetCount: exceededCount,
      underSetCount: underCount,
      averageScore: double.parse(avgScore.toStringAsFixed(4)),
      expectedSetCount: plannedByKey.length,
      matchedSetCount: matchedSetCount,
    );
  }

  double? _strengthSetAttainmentScore({
    required PlanPrescribedStrengthSet planned,
    required ActualStrengthSet actual,
  }) {
    final componentScores = <double>[];

    if (planned.weight != null && actual.weight != null) {
      final plannedWeight = planned.weight!;
      final actualWeight = actual.weight!;
      if (plannedWeight > 0) {
        componentScores.add(
            ((actualWeight / plannedWeight).clamp(0.5, 1.5) as num).toDouble());
      }
    }
    if (planned.reps != null && actual.reps != null) {
      final plannedReps = planned.reps!;
      final actualReps = actual.reps!;
      if (plannedReps > 0) {
        componentScores.add(
            ((actualReps / plannedReps).clamp(0.5, 1.5) as num).toDouble());
      }
    }
    if (planned.rir != null && actual.rir != null) {
      final rirDelta = (planned.rir! - actual.rir!).toDouble();
      componentScores
          .add((((1.0 + (rirDelta * 0.05)).clamp(0.8, 1.2)) as num).toDouble());
    }

    if (componentScores.isEmpty) {
      return null;
    }
    final avg = componentScores.fold<double>(0, (a, b) => a + b) /
        componentScores.length;
    return double.parse(avg.toStringAsFixed(4));
  }

  Future<void> _recordPlanLongRangeWeekPerformanceSnapshot({
    required String exportWeekStart,
    required String exportWeekEnd,
    required PlanCycle? activeCycle,
    required Map<int, PlanDay> planDayByNumber,
    required Map<String, List<PlanPrescribedStrengthSet>> planSetsByDayId,
    required Map<String, PlanPrescribedRun> planRunByDayId,
    required List<List<dynamic>> tenWeekPlanRows,
  }) async {
    final plannedDayCount = 7;
    final plannedDays = planDayByNumber.values.toList();
    final plannedSets = planSetsByDayId.values.expand((e) => e).toList();
    final plannedStrengthSets = plannedSets.length;
    final plannedStrengthExercises =
        plannedSets.map((s) => s.exerciseCanonical).toSet().length;
    final plannedRunRows = planRunByDayId.values
        .where((r) => (r.runType ?? '').trim().isNotEmpty)
        .toList();
    final plannedRunDays = plannedRunRows.length;
    final plannedRunSessions = plannedRunRows.length;

    final workoutDayRows = await (select(workoutDays)
          ..where((w) => w.workoutDate.isBiggerOrEqualValue(exportWeekStart))
          ..where((w) => w.workoutDate.isSmallerOrEqualValue(exportWeekEnd)))
        .get();
    final workoutDayIds = workoutDayRows.map((w) => w.id).toList();
    final workoutDateById = {
      for (final w in workoutDayRows) w.id: w.workoutDate
    };

    final actualStrengthRows = workoutDayIds.isEmpty
        ? const <ActualStrengthSet>[]
        : await (select(actualStrengthSets)
              ..where((a) => a.workoutDayId.isIn(workoutDayIds)))
            .get();
    final actualRunRows = workoutDayIds.isEmpty
        ? const <RunSession>[]
        : await (select(runSessions)
              ..where((r) => r.workoutDayId.isIn(workoutDayIds)))
            .get();

    final actualStrengthSetsCount = actualStrengthRows.length;
    final actualStrengthExercises = actualStrengthRows
        .map((a) => a.prescribedExerciseCanonical ?? a.exerciseCanonical)
        .map(ExerciseNormalizer.normalize)
        .toSet()
        .length;
    final actualRunSessions = actualRunRows.length;
    final actualRunDaySet = actualRunRows
        .map((r) => r.workoutDayId)
        .whereType<String>()
        .map((id) => workoutDateById[id])
        .whereType<String>()
        .toSet();
    final actualRunDays = actualRunDaySet.length;
    final actualStrengthDaySet = actualStrengthRows
        .map((a) => workoutDateById[a.workoutDayId])
        .whereType<String>()
        .toSet();
    final completedPlanDays = plannedDays
        .map((d) => d.estimatedDate)
        .whereType<String>()
        .where((ymd) =>
            actualRunDaySet.contains(ymd) || actualStrengthDaySet.contains(ymd))
        .toSet()
        .length;
    final totalRunDistanceM = actualRunRows
        .map((r) => r.distanceM)
        .whereType<double>()
        .fold<double>(0, (a, b) => a + b);
    final totalRunDurationS = actualRunRows
        .map((r) => r.durationS)
        .whereType<int>()
        .fold<int>(0, (a, b) => a + b);

    final longRangeWeek = await (select(planLongRangeWeeks)
          ..where((w) => w.weekStart.equals(exportWeekStart))
          ..where((w) => w.weekEnd.equals(exportWeekEnd))
          ..orderBy([
            (w) =>
                OrderingTerm(expression: w.updatedAt, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
    final fallbackWeekLabel = _findTenWeekWeekLabelForExport(
      tenWeekPlanRows: tenWeekPlanRows,
      exportWeekStart: exportWeekStart,
      exportWeekEnd: exportWeekEnd,
    );
    final fallbackWeekNumber = _weekNumberFromLabel(fallbackWeekLabel);
    final weekLabel = longRangeWeek?.weekLabel ?? fallbackWeekLabel;
    final weekNumber = longRangeWeek?.weekNumber ?? fallbackWeekNumber;
    final strengthProgressionEval = _evaluateStrengthProgressionForWeek(
      longRangeWeek: longRangeWeek,
      planDayByNumber: planDayByNumber,
      planSetsByDayId: planSetsByDayId,
      actualStrengthRows: actualStrengthRows,
      workoutDateById: workoutDateById,
    );

    final plannedRunDayAdherence =
        plannedRunDays == 0 ? null : actualRunDays / plannedRunDays;
    final strengthSetAdherence = plannedStrengthSets == 0
        ? null
        : actualStrengthSetsCount / plannedStrengthSets;
    final plannedDayCompletion =
        plannedDayCount == 0 ? null : completedPlanDays / plannedDayCount;
    final metricsJson = jsonEncode({
      'planned_day_completion': plannedDayCompletion,
      'planned_run_day_adherence': plannedRunDayAdherence,
      'strength_set_adherence': strengthSetAdherence,
      'actual_run_distance_m': totalRunDistanceM,
      'actual_run_duration_s': totalRunDurationS,
      'actual_strength_days': actualStrengthDaySet.length,
      'strength_progression_expectation': strengthProgressionEval.expectation,
      'strength_progression_evaluation': strengthProgressionEval.evaluation,
      'strength_progression_compared_set_count':
          strengthProgressionEval.comparedSetCount,
      'strength_progression_expected_set_count':
          strengthProgressionEval.expectedSetCount,
      'strength_progression_matched_set_count':
          strengthProgressionEval.matchedSetCount,
      'strength_progression_met_set_count': strengthProgressionEval.metSetCount,
      'strength_progression_exceeded_set_count':
          strengthProgressionEval.exceededSetCount,
      'strength_progression_under_set_count':
          strengthProgressionEval.underSetCount,
      'strength_progression_average_score':
          strengthProgressionEval.averageScore,
      'captured_from_export': true,
    });

    await into(planLongRangeWeekPerformance).insert(
      PlanLongRangeWeekPerformanceCompanion.insert(
        id: _uuid.v4(),
        planLongRangeWeekId: Value(longRangeWeek?.id),
        weekLabel: Value(weekLabel),
        weekNumber: Value(weekNumber),
        weekStart: exportWeekStart,
        weekEnd: exportWeekEnd,
        evaluatedPlanCycleId: Value(activeCycle?.id),
        evaluationSource: 'standard_workbook_export',
        plannedDayCount: plannedDayCount,
        completedPlanDays: completedPlanDays,
        plannedRunDays: plannedRunDays,
        actualRunDays: actualRunDays,
        plannedRunSessions: plannedRunSessions,
        actualRunSessions: actualRunSessions,
        plannedStrengthExercises: plannedStrengthExercises,
        actualStrengthExercises: actualStrengthExercises,
        plannedStrengthSets: plannedStrengthSets,
        actualStrengthSets: actualStrengthSetsCount,
        strengthProgressionExpectation:
            Value(strengthProgressionEval.expectation),
        strengthProgressionEvaluation:
            Value(strengthProgressionEval.evaluation),
        actualRunDistanceM: Value(totalRunDistanceM),
        actualRunDurationS: Value(totalRunDurationS),
        metricsJson: Value(metricsJson),
        capturedAt: unixMsNow(),
      ),
    );
  }

  List<List<dynamic>> _generateStrengthSummaryRows(
    Map<int, PlanDay> planDayByNumber,
    Map<String, List<PlanPrescribedStrengthSet>> planSetsByDayId,
  ) {
    final rows = <List<dynamic>>[
      <dynamic>[
        'Day',
        'Session',
        'Exercise',
        'Sets',
        'Reps',
        'Expected Weight',
        'Target RIR',
        'Notes / Adjustments'
      ]
    ];

    for (var dayNumber = 1; dayNumber <= 5; dayNumber++) {
      final day = planDayByNumber[dayNumber];
      if (day == null) {
        continue;
      }
      final sets =
          planSetsByDayId[day.id] ?? const <PlanPrescribedStrengthSet>[];
      final byExercise = <String, List<PlanPrescribedStrengthSet>>{};
      for (final set in sets) {
        final bucket = byExercise.putIfAbsent(
            set.exerciseCanonical, () => <PlanPrescribedStrengthSet>[]);
        bucket.add(set);
      }
      final exerciseKeys = byExercise.keys.toList()..sort();
      for (final exercise in exerciseKeys) {
        final exerciseSets = byExercise[exercise]!
          ..sort((a, b) => a.setIndex.compareTo(b.setIndex));
        final first = exerciseSets.first;
        final repsValues = exerciseSets
            .map((s) => s.reps?.toString() ?? '?')
            .toSet()
            .toList()
          ..sort();
        rows.add([
          'Day $dayNumber',
          _sessionTypeLabel(day.sessionType),
          exercise,
          exerciseSets.length.toString(),
          repsValues.join('/'),
          first.weight?.toString() ?? '',
          first.rir?.toString() ?? '',
          '',
        ]);
      }
    }
    return rows;
  }

  Future<void> clearLocalDomainData() async {
    await transaction(() async {
      await delete(runSegments).go();
      await delete(runSessionDetails).go();
      await delete(runSessions).go();
      await delete(runOverrideAudit).go();
      await delete(actualStrengthSets).go();
      await delete(prescribedStrengthSets).go();
      await delete(exerciseSubstitutions).go();
      await delete(planPrescribedStrengthSets).go();
      await delete(planPrescribedRuns).go();
      await delete(planExerciseAlternatives).go();
      await delete(planSummarySnapshots).go();
      await delete(planImportAudit).go();
      await delete(planDays).go();
      await delete(planCycles).go();
      await delete(ruleTriggers).go();
      await delete(aiAudit).go();
      await delete(sleepNights).go();
      await delete(workoutDays).go();
      await delete(planLongRangeWeekPerformance).go();
      await delete(planLongRangeWeeks).go();
    });
  }

  Future<void> replaceWorkspaceMetadata({
    required Iterable<CloudWorkspace> workspaces,
    required Iterable<CloudWorkspaceMembership> memberships,
    required Iterable<CloudAthleteProfile> profiles,
    required Iterable<CloudAthleteProfileAssignment> assignments,
    required Iterable<CloudWorkspaceInvite> invites,
  }) async {
    await transaction(() async {
      await delete(cloudWorkspaceInvites).go();
      await delete(cloudAthleteProfileAssignments).go();
      await delete(cloudAthleteProfiles).go();
      await delete(cloudWorkspaceMemberships).go();
      await delete(cloudWorkspaces).go();

      await batch((batch) {
        batch.insertAll(cloudWorkspaces, workspaces);
        batch.insertAll(cloudWorkspaceMemberships, memberships);
        batch.insertAll(cloudAthleteProfiles, profiles);
        batch.insertAll(cloudAthleteProfileAssignments, assignments);
        batch.insertAll(cloudWorkspaceInvites, invites);
      });
    });
  }

  Future<AppContextStateData?> getAppContextStateRow() {
    return (select(appContextState)..where((t) => t.id.equals('default')))
        .getSingleOrNull();
  }

  Future<void> upsertAppContextState({
    String? activeWorkspaceId,
    String? activeProfileId,
    String? activeRole,
    String? lastAuthUserId,
    bool? needsCloudClaim,
    String? pendingInviteToken,
  }) async {
    final current = await getAppContextStateRow();
    final now = DateTime.now().millisecondsSinceEpoch;
    await into(appContextState).insertOnConflictUpdate(
      AppContextStateCompanion(
        id: const Value('default'),
        activeWorkspaceId:
            Value(activeWorkspaceId ?? current?.activeWorkspaceId),
        activeProfileId: Value(activeProfileId ?? current?.activeProfileId),
        activeRole: Value(activeRole ?? current?.activeRole),
        lastAuthUserId: Value(lastAuthUserId ?? current?.lastAuthUserId),
        needsCloudClaim:
            Value(needsCloudClaim ?? current?.needsCloudClaim ?? false),
        pendingInviteToken:
            Value(pendingInviteToken ?? current?.pendingInviteToken),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> clearAppContextState() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await into(appContextState).insertOnConflictUpdate(
      AppContextStateCompanion(
        id: const Value('default'),
        activeWorkspaceId: const Value(null),
        activeProfileId: const Value(null),
        activeRole: const Value(null),
        lastAuthUserId: const Value(null),
        needsCloudClaim: const Value(false),
        pendingInviteToken: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> setPendingInviteToken(String? token) async {
    final current = await getAppContextStateRow();
    final now = DateTime.now().millisecondsSinceEpoch;
    await into(appContextState).insertOnConflictUpdate(
      AppContextStateCompanion(
        id: const Value('default'),
        activeWorkspaceId: Value(current?.activeWorkspaceId),
        activeProfileId: Value(current?.activeProfileId),
        activeRole: Value(current?.activeRole),
        lastAuthUserId: Value(current?.lastAuthUserId),
        needsCloudClaim: Value(current?.needsCloudClaim ?? false),
        pendingInviteToken: Value(token),
        updatedAt: Value(now),
      ),
    );
  }

  List<List<dynamic>> _generateRunSummaryRows(
    Map<int, PlanDay> planDayByNumber,
    Map<String, PlanPrescribedRun> planRunByDayId,
  ) {
    final rows = <List<dynamic>>[
      <dynamic>[
        'Day',
        'Lift Focus',
        'Run Type',
        'Duration',
        'Target Pace',
        'Effort / HR Guardrails',
        'Notes',
      ]
    ];
    for (var dayNumber = 1; dayNumber <= 5; dayNumber++) {
      final day = planDayByNumber[dayNumber];
      if (day == null) {
        continue;
      }
      final run = planRunByDayId[day.id];
      rows.add([
        'Day $dayNumber',
        run?.liftFocus ?? '',
        run?.runType ?? '',
        run?.durationText ?? '',
        run?.targetPace ?? '',
        run?.effortHrGuardrails ?? '',
        run?.notes ?? '',
      ]);
    }
    return rows;
  }

  String _formatPlannedSetForSheet(PlanPrescribedStrengthSet row) {
    if (row.rawSetString != null && row.rawSetString!.trim().isNotEmpty) {
      return row.rawSetString!;
    }
    final reps = row.reps;
    final rir = row.rir;
    final weight = row.weight;

    if (weight != null && reps != null) {
      final weightText = weight == weight.roundToDouble()
          ? weight.toInt().toString()
          : weight.toString();
      if (rir == null) {
        return '${weightText}x$reps';
      }
      return '${weightText}x${reps}r$rir';
    }
    if (row.unit.toLowerCase() == 'bw' && reps != null) {
      if (rir == null) {
        return 'BWx$reps';
      }
      return 'BWx${reps}r$rir';
    }
    if (reps != null) {
      if (rir == null) {
        return '$reps';
      }
      return '${reps}r$rir';
    }
    return '';
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'adaptive_athlete_local.db',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
