import 'package:supabase_flutter/supabase_flutter.dart';

import '../../db/app_db.dart';

class SyncService {
  SyncService({required this.db, required this.client});

  final AppDb db;
  final SupabaseClient client;

  Future<String> syncNow() async {
    final user = client.auth.currentUser;
    if (user == null) {
      return 'Sign in first to sync with Supabase.';
    }

    try {
      await _upsertWorkoutDays();
      await _upsertActualStrengthSets();
      await _upsertPrescribedStrengthSets();
      await _upsertSleepNights();
      await _upsertRunSessions();
      await _upsertRunSegments();
      await _upsertRunSessionDetails();
      await _upsertRunOverrideAudit();
      await _upsertRuleTriggers();
      await _upsertAiAudit();
      await _upsertPlanCycles();
      await _upsertPlanDays();
      await _upsertPlanPrescribedStrengthSets();
      await _upsertPlanPrescribedRuns();
      await _upsertPlanSummarySnapshots();
      await _upsertPlanImportAudit();
      return 'Sync complete: local Drift data pushed to Supabase.';
    } catch (e) {
      return 'Sync failed: $e';
    }
  }

  Future<void> _upsertWorkoutDays() async {
    final rows = await db.select(db.workoutDays).get();
    if (rows.isEmpty) {
      return;
    }
    await client.from('workout_days').upsert(
          rows
              .map((r) => {
                    'id': r.id,
                    'workout_date': r.workoutDate,
                    'created_at': r.createdAt,
                    'notes': r.notes,
                  })
              .toList(),
          onConflict: 'id',
        );
  }

  Future<void> _upsertActualStrengthSets() async {
    final rows = await db.select(db.actualStrengthSets).get();
    if (rows.isEmpty) {
      return;
    }
    await client.from('actual_strength_sets').upsert(
          rows
              .map((r) => {
                    'id': r.id,
                    'workout_day_id': r.workoutDayId,
                    'plan_day_id': r.planDayId,
                    'performed_at': r.performedAt,
                    'exercise_canonical': r.exerciseCanonical,
                    'set_index': r.setIndex,
                    'weight': r.weight,
                    'reps': r.reps,
                    'rir': r.rir,
                    'unit': r.unit,
                    'source': r.source,
                    'raw_set_string': r.rawSetString,
                    'created_at': r.createdAt,
                  })
              .toList(),
          onConflict: 'id',
        );
  }

  Future<void> _upsertPrescribedStrengthSets() async {
    final rows = await db.select(db.prescribedStrengthSets).get();
    if (rows.isEmpty) {
      return;
    }
    await client.from('prescribed_strength_sets').upsert(
          rows
              .map((r) => {
                    'id': r.id,
                    'workout_day_id': r.workoutDayId,
                    'exercise_canonical': r.exerciseCanonical,
                    'set_index': r.setIndex,
                    'weight': r.weight,
                    'reps': r.reps,
                    'rir': r.rir,
                    'unit': r.unit,
                  })
              .toList(),
          onConflict: 'id',
        );
  }

  Future<void> _upsertSleepNights() async {
    final rows = await db.select(db.sleepNights).get();
    if (rows.isEmpty) {
      return;
    }
    await client.from('sleep_nights').upsert(
          rows
              .map((r) => {
                    'id': r.id,
                    'sleep_date': r.sleepDate,
                    'start_time': r.startTime,
                    'end_time': r.endTime,
                    'total_sleep_min': r.totalSleepMin,
                    'rem_min': r.remMin,
                    'deep_min': r.deepMin,
                    'light_min': r.lightMin,
                    'awake_min': r.awakeMin,
                    'source': r.source,
                  })
              .toList(),
          onConflict: 'id',
        );
  }

  Future<void> _upsertRunSessions() async {
    final rows = await db.select(db.runSessions).get();
    if (rows.isEmpty) {
      return;
    }
    await client.from('run_sessions').upsert(
          rows
              .map((r) => {
                    'id': r.id,
                    'run_key': r.runKey,
                    'workout_day_id': r.workoutDayId,
                    'plan_day_id': r.planDayId,
                    'start_time': r.startTime,
                    'end_time': r.endTime,
                    'duration_s': r.durationS,
                    'distance_m': r.distanceM,
                    'avg_hr': r.avgHr,
                    'max_hr': r.maxHr,
                    'treadmill': r.treadmill,
                    'title': r.title,
                    'activity_type': r.activityType,
                    'calories': r.calories,
                    'moving_time_s': r.movingTimeS,
                    'elapsed_time_s': r.elapsedTimeS,
                    'source_priority': r.sourcePriority,
                    'import_file_name': r.importFileName,
                    'raw_metrics_json': r.rawMetricsJson,
                    'source': r.source,
                  })
              .toList(),
          onConflict: 'id',
        );
  }

  Future<void> _upsertRunSegments() async {
    final rows = await db.select(db.runSegments).get();
    if (rows.isEmpty) {
      return;
    }
    await client.from('run_segments').upsert(
          rows
              .map((r) => {
                    'id': r.id,
                    'run_session_id': r.runSessionId,
                    'idx': r.idx,
                    'duration_s': r.durationS,
                    'distance_m': r.distanceM,
                    'speed_mps': r.speedMps,
                  })
              .toList(),
          onConflict: 'id',
        );
  }

  Future<void> _upsertRunSessionDetails() async {
    final rows = await db.select(db.runSessionDetails).get();
    if (rows.isEmpty) {
      return;
    }
    await client.from('run_session_details').upsert(
          rows
              .map((r) => {
                    'run_session_id': r.runSessionId,
                    'favorite': r.favorite,
                    'aerobic_te': r.aerobicTe,
                    'avg_run_cadence': r.avgRunCadence,
                    'max_run_cadence': r.maxRunCadence,
                    'avg_pace_s': r.avgPaceS,
                    'best_pace_s': r.bestPaceS,
                    'total_ascent': r.totalAscent,
                    'total_descent': r.totalDescent,
                    'avg_stride_length_m': r.avgStrideLengthM,
                    'training_stress_score': r.trainingStressScore,
                    'steps': r.steps,
                    'min_temp': r.minTemp,
                    'max_temp': r.maxTemp,
                    'decompression': r.decompression,
                    'best_lap_time_s': r.bestLapTimeS,
                    'number_of_laps': r.numberOfLaps,
                    'min_elevation': r.minElevation,
                    'max_elevation': r.maxElevation,
                    'raw_metrics_json': r.rawMetricsJson,
                  })
              .toList(),
          onConflict: 'run_session_id',
        );
  }

  Future<void> _upsertRunOverrideAudit() async {
    final rows = await db.select(db.runOverrideAudit).get();
    if (rows.isEmpty) {
      return;
    }
    await client.from('run_override_audit').upsert(
          rows
              .map((r) => {
                    'id': r.id,
                    'run_key': r.runKey,
                    'workout_day_id': r.workoutDayId,
                    'old_source': r.oldSource,
                    'new_source': r.newSource,
                    'old_snapshot_json': r.oldSnapshotJson,
                    'new_snapshot_json': r.newSnapshotJson,
                    'reason': r.reason,
                    'created_at': r.createdAt,
                  })
              .toList(),
          onConflict: 'id',
        );
  }

  Future<void> _upsertRuleTriggers() async {
    final rows = await db.select(db.ruleTriggers).get();
    if (rows.isEmpty) {
      return;
    }
    await client.from('rule_triggers').upsert(
          rows
              .map((r) => {
                    'id': r.id,
                    'trigger_date': r.triggerDate,
                    'rule_code': r.ruleCode,
                    'triggered': r.triggered,
                    'details_json': r.detailsJson,
                    'created_at': r.createdAt,
                  })
              .toList(),
          onConflict: 'id',
        );
  }

  Future<void> _upsertAiAudit() async {
    final rows = await db.select(db.aiAudit).get();
    if (rows.isEmpty) {
      return;
    }
    await client.from('ai_audit').upsert(
          rows
              .map((r) => {
                    'id': r.id,
                    'requested_at': r.requestedAt,
                    'date_window_start': r.dateWindowStart,
                    'date_window_end': r.dateWindowEnd,
                    'input_snapshot_json': r.inputSnapshotJson,
                    'response_json': r.responseJson,
                    'schema_valid': r.schemaValid,
                    'notes': r.notes,
                  })
              .toList(),
          onConflict: 'id',
        );
  }

  Future<void> _upsertPlanCycles() async {
    final rows = await db.select(db.planCycles).get();
    if (rows.isEmpty) {
      return;
    }
    await client.from('plan_cycles').upsert(
          rows
              .map((r) => {
                    'id': r.id,
                    'cycle_key': r.cycleKey,
                    'week_start': r.weekStart,
                    'week_end': r.weekEnd,
                    'source': r.source,
                    'created_at': r.createdAt,
                  })
              .toList(),
          onConflict: 'id',
        );
  }

  Future<void> _upsertPlanDays() async {
    final rows = await db.select(db.planDays).get();
    if (rows.isEmpty) {
      return;
    }
    await client.from('plan_days').upsert(
          rows
              .map((r) => {
                    'id': r.id,
                    'plan_cycle_id': r.planCycleId,
                    'day_number': r.dayNumber,
                    'sheet_name': r.sheetName,
                    'estimated_date': r.estimatedDate,
                    'session_type': r.sessionType,
                    'created_at': r.createdAt,
                  })
              .toList(),
          onConflict: 'id',
        );
  }

  Future<void> _upsertPlanPrescribedStrengthSets() async {
    final rows = await db.select(db.planPrescribedStrengthSets).get();
    if (rows.isEmpty) {
      return;
    }
    await client.from('plan_prescribed_strength_sets').upsert(
          rows
              .map((r) => {
                    'id': r.id,
                    'plan_day_id': r.planDayId,
                    'exercise_canonical': r.exerciseCanonical,
                    'set_index': r.setIndex,
                    'weight': r.weight,
                    'reps': r.reps,
                    'rir': r.rir,
                    'unit': r.unit,
                    'raw_set_string': r.rawSetString,
                    'created_at': r.createdAt,
                  })
              .toList(),
          onConflict: 'id',
        );
  }

  Future<void> _upsertPlanPrescribedRuns() async {
    final rows = await db.select(db.planPrescribedRuns).get();
    if (rows.isEmpty) {
      return;
    }
    await client.from('plan_prescribed_runs').upsert(
          rows
              .map((r) => {
                    'id': r.id,
                    'plan_day_id': r.planDayId,
                    'day_label': r.dayLabel,
                    'lift_focus': r.liftFocus,
                    'run_type': r.runType,
                    'duration_text': r.durationText,
                    'target_pace': r.targetPace,
                    'effort_hr_guardrails': r.effortHrGuardrails,
                    'notes': r.notes,
                    'created_at': r.createdAt,
                  })
              .toList(),
          onConflict: 'id',
        );
  }

  Future<void> _upsertPlanSummarySnapshots() async {
    final rows = await db.select(db.planSummarySnapshots).get();
    if (rows.isEmpty) {
      return;
    }
    await client.from('plan_summary_snapshots').upsert(
          rows
              .map((r) => {
                    'id': r.id,
                    'plan_cycle_id': r.planCycleId,
                    'tab_name': r.tabName,
                    'snapshot_json': r.snapshotJson,
                    'created_at': r.createdAt,
                  })
              .toList(),
          onConflict: 'id',
        );
  }

  Future<void> _upsertPlanImportAudit() async {
    final rows = await db.select(db.planImportAudit).get();
    if (rows.isEmpty) {
      return;
    }
    await client.from('plan_import_audit').upsert(
          rows
              .map((r) => {
                    'id': r.id,
                    'imported_at': r.importedAt,
                    'file_name': r.fileName,
                    'success': r.success,
                    'details_json': r.detailsJson,
                    'conflict_report_path': r.conflictReportPath,
                  })
              .toList(),
          onConflict: 'id',
        );
  }
}
