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
import 'tables/ai_audit.dart';
import 'tables/plan_cycles.dart';
import 'tables/plan_days.dart';
import 'tables/plan_import_audit.dart';
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
    required this.prescribed,
    required this.actual,
  });

  final String exercise;
  final List<PlannedStrengthSetView> prescribed;
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
    required this.warnings,
    required this.conflictReportPath,
  });

  final bool replacedCycle;
  final int insertedPlanDays;
  final int insertedStrengthSets;
  final int insertedRunPlans;
  final List<String> warnings;
  final String? conflictReportPath;

  Map<String, dynamic> toJson() => {
        'replaced_cycle': replacedCycle,
        'inserted_plan_days': insertedPlanDays,
        'inserted_strength_sets': insertedStrengthSets,
        'inserted_run_plans': insertedRunPlans,
        'warnings': warnings,
        'conflict_report_path': conflictReportPath,
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

class _PlanDaySnapshot {
  const _PlanDaySnapshot({
    required this.sheetName,
    required this.sessionType,
    required this.strengthSets,
    required this.runPlan,
  });

  final String sheetName;
  final String sessionType;
  final List<PlanPrescribedStrengthSet> strengthSets;
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
    SleepNights,
    RunSessions,
    RunSegments,
    RunSessionDetails,
    RunOverrideAudit,
    RuleTriggers,
    AiAudit,
    PlanCycles,
    PlanDays,
    PlanPrescribedStrengthSets,
    PlanPrescribedRuns,
    PlanSummarySnapshots,
    PlanImportAudit,
  ],
)
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  AppDb.forTesting(super.connection);

  final Uuid _uuid = const Uuid();

  @override
  int get schemaVersion => 4;

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
        },
        beforeOpen: (details) async {
          await _ensurePlanDaysSessionTypeColumn();
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

    return (select(planCycles)
          ..where((c) => c.weekStart.isSmallerOrEqualValue(ymd))
          ..where((c) => c.weekEnd.isBiggerOrEqualValue(ymd))
          ..orderBy([
            (c) =>
                OrderingTerm(expression: c.createdAt, mode: OrderingMode.desc)
          ]))
        .getSingleOrNull();
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

      final snapshots = days
          .map(
            (day) => _PlanDaySnapshot(
              sheetName: day.sheetName,
              sessionType:
                  _normalizeSessionType(day.sessionType ?? day.sheetName),
              strengthSets: List<PlanPrescribedStrengthSet>.from(
                  setsByDayId[day.id] ?? const <PlanPrescribedStrengthSet>[]),
              runPlan: runByDayId[day.id],
            ),
          )
          .toList();

      final restPlaceholder = _PlanDaySnapshot(
        sheetName: selected.sheetName,
        sessionType: 'rest',
        strengthSets: const <PlanPrescribedStrengthSet>[],
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
    final byEstimatedDate = await _getLatestPlanDayByEstimatedDate(ymd);
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
  }) async {
    final mappedPlanDayId =
        planDayId ?? await _resolvePlanDayIdForWorkoutDayId(workoutDayId);
    await into(actualStrengthSets).insert(
      ActualStrengthSetsCompanion.insert(
        id: _uuid.v4(),
        workoutDayId: workoutDayId,
        planDayId: Value(mappedPlanDayId),
        exerciseCanonical: exercise,
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
  }) async {
    final workoutDayId = await createOrGetWorkoutDayByDate(dateYmd);
    final mappedPlanDayId = await _resolvePlanDayIdForDate(dateYmd);
    final canonicalExercise = ExerciseNormalizer.normalize(exerciseCanonical);
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
          ..where((a) => a.exerciseCanonical.equals(canonicalExercise))
          ..where((a) => a.setIndex.equals(setIndex))
          ..orderBy([
            (a) =>
                OrderingTerm(expression: a.createdAt, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();

    if (existing == null) {
      await into(actualStrengthSets).insert(
        ActualStrengthSetsCompanion.insert(
          id: _uuid.v4(),
          workoutDayId: workoutDayId,
          planDayId: Value(mappedPlanDayId),
          exerciseCanonical: canonicalExercise,
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

    await (update(actualStrengthSets)..where((a) => a.id.equals(existing.id)))
        .write(
      ActualStrengthSetsCompanion(
        planDayId: Value(mappedPlanDayId),
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
      await _deletePlanCyclesForWeek(weekStart: weekStart, weekEnd: weekEnd);

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
    SpreadsheetDecoder decoder;
    try {
      decoder = SpreadsheetDecoder.decodeBytes(bytes, update: false);
    } catch (e) {
      throw StateError('Workbook parse failed: $e');
    }

    final sheetNames = decoder.tables.keys.toList();
    if (sheetNames.length < 11) {
      throw StateError(
          'Expected at least 11 sheets, found ${sheetNames.length}.');
    }
    const requiredPrefix = <String>[
      'Strength Data',
      'Run Data',
      '5-Day Push Pull Plan',
    ];
    for (var i = 0; i < requiredPrefix.length; i++) {
      if (sheetNames[i].trim() != requiredPrefix[i]) {
        throw StateError(
          'Sheet ${i + 1} must be "${requiredPrefix[i]}". Found "${sheetNames[i]}".',
        );
      }
    }

    final runPlanSheetName = sheetNames[3].trim();
    if (runPlanSheetName != 'Run Plan - 5mi @ 8 min' &&
        runPlanSheetName != 'Run Plan - 5mi @ 8') {
      throw StateError(
          'Sheet 4 must be "Run Plan - 5mi @ 8 min" (or legacy "Run Plan - 5mi @ 8").');
    }

    for (var dayNumber = 1; dayNumber <= 7; dayNumber++) {
      final idx = dayNumber + 3;
      final expectedPrefix = 'day $dayNumber';
      if (idx >= sheetNames.length ||
          !sheetNames[idx].trim().toLowerCase().startsWith(expectedPrefix)) {
        throw StateError(
          'Expected sheet ${idx + 1} to start with "Day $dayNumber". Found "${idx < sheetNames.length ? sheetNames[idx] : 'missing'}".',
        );
      }
    }

    final strengthSummaryRows =
        _decodeRows(decoder.tables['5-Day Push Pull Plan']?.rows);
    final runSummaryRows = _decodeRows(decoder.tables[runPlanSheetName]?.rows);
    final summarySessionByDay =
        _extractSummarySessionByDay(strengthSummaryRows);

    final parsedDays = <_ParsedDailyPlan>[];
    for (var dayNumber = 1; dayNumber <= 7; dayNumber++) {
      final sheetName = sheetNames[dayNumber + 3];
      final rows = _decodeRows(decoder.tables[sheetName]?.rows);
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
    late bool replacedCycle;

    await transaction(() async {
      replacedCycle = await _deletePlanCyclesForWeek(
        weekStart: weekStart,
        weekEnd: weekEnd,
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
        '5-Day Push Pull Plan': strengthSummaryRows,
        'Run Plan - 5mi @ 8 min': runSummaryRows,
      };
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
        }),
      ),
    );

    return StandardWorkbookImportResult(
      replacedCycle: replacedCycle,
      insertedPlanDays: insertedDayCount,
      insertedStrengthSets: insertedStrengthCount,
      insertedRunPlans: insertedRunCount,
      warnings: const <String>[],
      conflictReportPath: null,
    );
  }

  List<List<dynamic>> _decodeRows(List<List>? rows) {
    if (rows == null) {
      return const <List<dynamic>>[];
    }
    return rows.map((row) => List<dynamic>.from(row)).toList();
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
      if (lower.contains('run results') || lower.contains('strength results')) {
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
      rawRows: rows,
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

  Future<bool> _deletePlanCyclesForWeek({
    required String weekStart,
    required String weekEnd,
  }) async {
    final existing = await (select(planCycles)
          ..where((c) => c.weekStart.equals(weekStart))
          ..where((c) => c.weekEnd.equals(weekEnd)))
        .get();
    if (existing.isEmpty) {
      return false;
    }

    for (final cycle in existing) {
      final dayRows = await (select(planDays)
            ..where((d) => d.planCycleId.equals(cycle.id)))
          .get();
      final dayIds = dayRows.map((d) => d.id).toList();

      if (dayIds.isNotEmpty) {
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
    final day = await (select(workoutDays)
          ..where((d) => d.workoutDate.equals(dateString)))
        .getSingleOrNull();
    PlanDay? matchedPlanDay =
        await _getLatestPlanDayByEstimatedDate(dateString);
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
          matchedPlanDay = await (select(planDays)
                ..where((d) => d.planCycleId.equals(cycleId))
                ..where((d) => d.dayNumber.equals(dayNumber)))
              .getSingleOrNull();
        }
      }
    }

    final matchedPlanDayId = matchedPlanDay?.id;
    final plannedSets = matchedPlanDayId == null
        ? const <PlanPrescribedStrengthSet>[]
        : await (select(planPrescribedStrengthSets)
              ..where((s) => s.planDayId.equals(matchedPlanDayId))
              ..orderBy([
                (s) => OrderingTerm(
                    expression: s.createdAt, mode: OrderingMode.asc),
                (s) => OrderingTerm(
                    expression: s.setIndex, mode: OrderingMode.asc),
              ]))
            .get();
    final plannedRun = matchedPlanDayId == null
        ? null
        : await (select(planPrescribedRuns)
              ..where((r) => r.planDayId.equals(matchedPlanDayId)))
            .getSingleOrNull();
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

    if (day == null) {
      final fallbackGroups = _groupsFromPlannedAndActual(
        plannedRows: plannedSets,
        legacyRows: const <PrescribedStrengthSet>[],
        actualRows: const <ActualStrengthSet>[],
      );
      return WorkoutDayDetail(
        date: dateString,
        workoutDay: null,
        planCycleId: activeCycle?.id,
        planDayNumber: matchedPlanDay?.dayNumber,
        planSessionType: matchedPlanDay?.sessionType,
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
    );

    return WorkoutDayDetail(
      date: dateString,
      workoutDay: day,
      planCycleId: activeCycle?.id,
      planDayNumber: matchedPlanDay?.dayNumber,
      planSessionType: matchedPlanDay?.sessionType,
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
  }) {
    final byExercise = <String, ExerciseSetGroup>{};

    if (plannedRows.isNotEmpty) {
      for (final row in plannedRows) {
        final current = byExercise[row.exerciseCanonical] ??
            ExerciseSetGroup(
              exercise: row.exerciseCanonical,
              prescribed: const <PlannedStrengthSetView>[],
              actual: const <ActualStrengthSet>[],
            );
        byExercise[row.exerciseCanonical] = ExerciseSetGroup(
          exercise: current.exercise,
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
          actual: current.actual,
        );
      }
    } else {
      for (final row in legacyRows) {
        final current = byExercise[row.exerciseCanonical] ??
            ExerciseSetGroup(
              exercise: row.exerciseCanonical,
              prescribed: const <PlannedStrengthSetView>[],
              actual: const <ActualStrengthSet>[],
            );
        byExercise[row.exerciseCanonical] = ExerciseSetGroup(
          exercise: current.exercise,
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
          actual: current.actual,
        );
      }
    }

    for (final row in actualRows) {
      final current = byExercise[row.exerciseCanonical] ??
          ExerciseSetGroup(
            exercise: row.exerciseCanonical,
            prescribed: const <PlannedStrengthSetView>[],
            actual: const <ActualStrengthSet>[],
          );
      byExercise[row.exerciseCanonical] = ExerciseSetGroup(
        exercise: current.exercise,
        prescribed: current.prescribed,
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
    final startOfCurrentWeek =
        today.subtract(Duration(days: today.weekday - 1));
    final previousWeekStart =
        startOfCurrentWeek.subtract(const Duration(days: 7));
    final previousWeekEnd = previousWeekStart.add(const Duration(days: 6));
    final previousWeekStartYmd = toYmd(previousWeekStart);
    final previousWeekEndYmd = toYmd(previousWeekEnd);
    final historyStartYmd =
        toYmd(previousWeekEnd.subtract(const Duration(days: 20)));

    final excel = Excel.createExcel();
    final defaultSheetName = excel.getDefaultSheet();
    if (defaultSheetName != null && defaultSheetName != 'Strength Data') {
      excel.rename(defaultSheetName, 'Strength Data');
    }

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
          workoutDate.compareTo(previousWeekEndYmd) > 0) {
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
          workoutDate.compareTo(previousWeekEndYmd) > 0) {
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
      }

      final snapshots = await (select(planSummarySnapshots)
            ..where((s) => s.planCycleId.equals(activeCycle.id)))
          .get();
      for (final snapshot in snapshots) {
        snapshotsByTab[snapshot.tabName] =
            _rowsFromSnapshotJson(snapshot.snapshotJson);
      }
    }

    final strengthSummaryRows = snapshotsByTab['5-Day Push Pull Plan'] ??
        _generateStrengthSummaryRows(planDayByNumber, planSetsByDayId);
    final runSummaryRows = snapshotsByTab['Run Plan - 5mi @ 8 min'] ??
        snapshotsByTab['Run Plan - 5mi @ 8'] ??
        _generateRunSummaryRows(planDayByNumber, planRunByDayId);
    _writeRows(excel['5-Day Push Pull Plan'], strengthSummaryRows);
    _writeRows(excel['Run Plan - 5mi @ 8 min'], runSummaryRows);

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

    final encoded = excel.encode();
    if (encoded == null) {
      throw StateError('Failed to encode workbook.');
    }
    final fileName = 'WeeklyExecution_wk_${previousWeekStartYmd}_to_'
        '${previousWeekEndYmd}__strength_${historyStartYmd}_to_'
        '${previousWeekEndYmd}__run_${historyStartYmd}_to_'
        '$previousWeekEndYmd.xlsx';
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
  return driftDatabase(name: 'adaptive_athlete_local.db');
}
