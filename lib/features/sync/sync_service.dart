import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../db/app_db.dart';
import '../workspace/workspace_service.dart';

class SyncService {
  SyncService({
    required this.db,
    required this.client,
    WorkspaceService? workspaceService,
  }) : workspaceService =
            workspaceService ?? WorkspaceService(db: db, client: client);

  final AppDb db;
  final SupabaseClient client;
  final WorkspaceService workspaceService;
  late final _ScopedSyncContext _context;

  Future<String> syncNow() async {
    final user = client.auth.currentUser;
    if (user == null) {
      return 'Sign in first to sync with Supabase.';
    }

    try {
      final activeContext = await workspaceService.requireContext();
      _context = _ScopedSyncContext(
        workspaceId: activeContext.workspaceId,
        athleteProfileId: activeContext.profileId,
      );
      if (activeContext.needsCloudClaim &&
          activeContext.role.toLowerCase() == 'owner') {
        await workspaceService.claimLegacyRowsForActiveProfile(
          context: activeContext,
        );
      }

      final hasLocalRows = await _hasAnyLocalRows();
      if (hasLocalRows) {
        await _pushToSupabase();
        await _pullFromSupabase();
        return 'Sync complete: local pushed to cloud, then cloud pulled to local.';
      }

      await _pullFromSupabase();
      await _pushToSupabase();
      return 'Sync complete: cloud pulled to empty local, then local pushed to cloud.';
    } catch (e) {
      return 'Sync failed: $e';
    }
  }

  Future<bool> _hasAnyLocalRows() async {
    if (await (db.select(db.workoutDays)..limit(1)).getSingleOrNull() != null) {
      return true;
    }
    if (await (db.select(db.planCycles)..limit(1)).getSingleOrNull() != null) {
      return true;
    }
    if (await (db.select(db.actualStrengthSets)..limit(1)).getSingleOrNull() !=
        null) {
      return true;
    }
    if (await (db.select(db.runSessions)..limit(1)).getSingleOrNull() != null) {
      return true;
    }
    if (await (db.select(db.sleepNights)..limit(1)).getSingleOrNull() != null) {
      return true;
    }
    if (await (db.select(db.athletePlanningProfiles)..limit(1))
            .getSingleOrNull() !=
        null) {
      return true;
    }
    return false;
  }

  Future<void> _pushToSupabase() async {
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
    await _upsertExerciseSubstitutions();
    await _upsertPlanPrescribedStrengthSets();
    await _upsertPlanPrescribedRuns();
    await _upsertPlanExerciseAlternatives();
    await _upsertPlanSummarySnapshots();
    await _upsertPlanImportAudit();
    await _upsertAthletePlanningProfiles();
    await _upsertWeeklyPlanBuildRequests();
  }

  Future<void> _pullFromSupabase() async {
    await _pullWorkoutDays();
    await _pullPlanCycles();
    await _pullPlanDays();
    await _pullExerciseSubstitutions();
    await _pullPlanPrescribedStrengthSets();
    await _pullPlanPrescribedRuns();
    await _pullPlanExerciseAlternatives();
    await _pullPlanSummarySnapshots();
    await _pullPlanImportAudit();
    await _pullAthletePlanningProfiles();
    await _pullWeeklyPlanBuildRequests();
    await _pullActualStrengthSets();
    await _pullPrescribedStrengthSets();
    await _pullSleepNights();
    await _pullRunSessions();
    await _pullRunSegments();
    await _pullRunSessionDetails();
    await _pullRunOverrideAudit();
    await _pullRuleTriggers();
    await _pullAiAudit();
  }

  Future<List<Map<String, dynamic>>> _fetchRows(
    String table, {
    String? columns,
  }) async {
    const pageSize = 1000;
    final allRows = <Map<String, dynamic>>[];
    var from = 0;

    while (true) {
      final query = columns == null
          ? client.from(table).select()
          : client.from(table).select(columns);
      final response = await query
          .eq('workspace_id', _context.workspaceId)
          .eq('athlete_profile_id', _context.athleteProfileId)
          .range(from, from + pageSize - 1);

      final rows = (response as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      allRows.addAll(rows);

      if (rows.length < pageSize) {
        break;
      }
      from += pageSize;
    }

    return allRows;
  }

  String _requiredString(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value == null) {
      throw StateError('Missing required field "$key".');
    }
    return value.toString();
  }

  int _requiredInt(Map<String, dynamic> row, String key) {
    final value = _asInt(row[key]);
    if (value == null) {
      throw StateError('Missing required int field "$key".');
    }
    return value;
  }

  bool _requiredBool(Map<String, dynamic> row, String key) {
    final value = _asBool(row[key]);
    if (value == null) {
      throw StateError('Missing required bool field "$key".');
    }
    return value;
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
    return int.tryParse(value.toString());
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
    return double.tryParse(value.toString());
  }

  bool? _asBool(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final normalized = value.toString().toLowerCase();
    if (normalized == 'true' || normalized == 't' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == 'f' || normalized == '0') {
      return false;
    }
    return null;
  }

  Map<String, dynamic> _scopedRow(Map<String, dynamic> row) => {
        ...row,
        'workspace_id': _context.workspaceId,
        'athlete_profile_id': _context.athleteProfileId,
      };

  Future<void> _pullWorkoutDays() async {
    final rows = await _fetchRows('workout_days');
    await db.batch((batch) {
      for (final r in rows) {
        batch.insert(
          db.workoutDays,
          WorkoutDaysCompanion(
            id: Value(_requiredString(r, 'id')),
            workoutDate: Value(_requiredString(r, 'workout_date')),
            createdAt: Value(_requiredInt(r, 'created_at')),
            notes: Value(r['notes']?.toString()),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _pullActualStrengthSets() async {
    final rows = await _fetchRows('actual_strength_sets');
    await db.batch((batch) {
      for (final r in rows) {
        batch.insert(
          db.actualStrengthSets,
          ActualStrengthSetsCompanion(
            id: Value(_requiredString(r, 'id')),
            workoutDayId: Value(_requiredString(r, 'workout_day_id')),
            planDayId: Value(r['plan_day_id']?.toString()),
            performedAt: Value(_asInt(r['performed_at'])),
            exerciseCanonical: Value(_requiredString(r, 'exercise_canonical')),
            setIndex: Value(_requiredInt(r, 'set_index')),
            weight: Value(_asDouble(r['weight'])),
            reps: Value(_asInt(r['reps'])),
            rir: Value(_asInt(r['rir'])),
            unit: Value(_requiredString(r, 'unit')),
            source: Value(_requiredString(r, 'source')),
            rawSetString: Value(r['raw_set_string']?.toString()),
            createdAt: Value(_requiredInt(r, 'created_at')),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _pullPrescribedStrengthSets() async {
    final rows = await _fetchRows('prescribed_strength_sets');
    await db.batch((batch) {
      for (final r in rows) {
        batch.insert(
          db.prescribedStrengthSets,
          PrescribedStrengthSetsCompanion(
            id: Value(_requiredString(r, 'id')),
            workoutDayId: Value(_requiredString(r, 'workout_day_id')),
            exerciseCanonical: Value(_requiredString(r, 'exercise_canonical')),
            setIndex: Value(_requiredInt(r, 'set_index')),
            weight: Value(_asDouble(r['weight'])),
            reps: Value(_asInt(r['reps'])),
            rir: Value(_asInt(r['rir'])),
            unit: Value(_requiredString(r, 'unit')),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _pullSleepNights() async {
    final rows = await _fetchRows('sleep_nights');
    await db.batch((batch) {
      for (final r in rows) {
        batch.insert(
          db.sleepNights,
          SleepNightsCompanion(
            id: Value(_requiredString(r, 'id')),
            sleepDate: Value(_requiredString(r, 'sleep_date')),
            startTime: Value(_asInt(r['start_time'])),
            endTime: Value(_asInt(r['end_time'])),
            totalSleepMin: Value(_asInt(r['total_sleep_min'])),
            remMin: Value(_asInt(r['rem_min'])),
            deepMin: Value(_asInt(r['deep_min'])),
            lightMin: Value(_asInt(r['light_min'])),
            awakeMin: Value(_asInt(r['awake_min'])),
            source: Value(_requiredString(r, 'source')),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _pullRunSessions() async {
    final rows = await _fetchRows('run_sessions');
    await db.batch((batch) {
      for (final r in rows) {
        batch.insert(
          db.runSessions,
          RunSessionsCompanion(
            id: Value(_requiredString(r, 'id')),
            runKey: Value(_requiredString(r, 'run_key')),
            workoutDayId: Value(r['workout_day_id']?.toString()),
            planDayId: Value(r['plan_day_id']?.toString()),
            startTime: Value(_asInt(r['start_time'])),
            endTime: Value(_asInt(r['end_time'])),
            durationS: Value(_asInt(r['duration_s'])),
            distanceM: Value(_asDouble(r['distance_m'])),
            avgHr: Value(_asDouble(r['avg_hr'])),
            maxHr: Value(_asDouble(r['max_hr'])),
            treadmill: Value(_asBool(r['treadmill'])),
            title: Value(r['title']?.toString()),
            activityType: Value(r['activity_type']?.toString()),
            calories: Value(_asInt(r['calories'])),
            movingTimeS: Value(_asInt(r['moving_time_s'])),
            elapsedTimeS: Value(_asInt(r['elapsed_time_s'])),
            sourcePriority: Value(_asInt(r['source_priority']) ?? 0),
            importFileName: Value(r['import_file_name']?.toString()),
            rawMetricsJson: Value(r['raw_metrics_json']?.toString()),
            source: Value(_requiredString(r, 'source')),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _pullRunSegments() async {
    final rows = await _fetchRows('run_segments');
    await db.batch((batch) {
      for (final r in rows) {
        batch.insert(
          db.runSegments,
          RunSegmentsCompanion(
            id: Value(_requiredString(r, 'id')),
            runSessionId: Value(_requiredString(r, 'run_session_id')),
            idx: Value(_requiredInt(r, 'idx')),
            durationS: Value(_asInt(r['duration_s'])),
            distanceM: Value(_asDouble(r['distance_m'])),
            speedMps: Value(_asDouble(r['speed_mps'])),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _pullRunSessionDetails() async {
    final rows = await _fetchRows('run_session_details');
    await db.batch((batch) {
      for (final r in rows) {
        batch.insert(
          db.runSessionDetails,
          RunSessionDetailsCompanion(
            runSessionId: Value(_requiredString(r, 'run_session_id')),
            favorite: Value(_asBool(r['favorite'])),
            aerobicTe: Value(_asDouble(r['aerobic_te'])),
            avgRunCadence: Value(_asDouble(r['avg_run_cadence'])),
            maxRunCadence: Value(_asDouble(r['max_run_cadence'])),
            avgPaceS: Value(_asDouble(r['avg_pace_s'])),
            bestPaceS: Value(_asDouble(r['best_pace_s'])),
            totalAscent: Value(_asDouble(r['total_ascent'])),
            totalDescent: Value(_asDouble(r['total_descent'])),
            avgStrideLengthM: Value(_asDouble(r['avg_stride_length_m'])),
            trainingStressScore: Value(_asDouble(r['training_stress_score'])),
            steps: Value(_asInt(r['steps'])),
            minTemp: Value(_asDouble(r['min_temp'])),
            maxTemp: Value(_asDouble(r['max_temp'])),
            decompression: Value(r['decompression']?.toString()),
            bestLapTimeS: Value(_asDouble(r['best_lap_time_s'])),
            numberOfLaps: Value(_asInt(r['number_of_laps'])),
            minElevation: Value(_asDouble(r['min_elevation'])),
            maxElevation: Value(_asDouble(r['max_elevation'])),
            rawMetricsJson: Value(r['raw_metrics_json']?.toString() ?? '{}'),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _pullRunOverrideAudit() async {
    final rows = await _fetchRows('run_override_audit');
    await db.batch((batch) {
      for (final r in rows) {
        batch.insert(
          db.runOverrideAudit,
          RunOverrideAuditCompanion(
            id: Value(_requiredString(r, 'id')),
            runKey: Value(_requiredString(r, 'run_key')),
            workoutDayId: Value(r['workout_day_id']?.toString()),
            oldSource: Value(_requiredString(r, 'old_source')),
            newSource: Value(_requiredString(r, 'new_source')),
            oldSnapshotJson: Value(_requiredString(r, 'old_snapshot_json')),
            newSnapshotJson: Value(_requiredString(r, 'new_snapshot_json')),
            reason: Value(_requiredString(r, 'reason')),
            createdAt: Value(_requiredInt(r, 'created_at')),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _pullRuleTriggers() async {
    final rows = await _fetchRows('rule_triggers');
    await db.batch((batch) {
      for (final r in rows) {
        batch.insert(
          db.ruleTriggers,
          RuleTriggersCompanion(
            id: Value(_requiredString(r, 'id')),
            triggerDate: Value(_requiredString(r, 'trigger_date')),
            ruleCode: Value(_requiredString(r, 'rule_code')),
            triggered: Value(_requiredBool(r, 'triggered')),
            detailsJson: Value(_requiredString(r, 'details_json')),
            createdAt: Value(_requiredInt(r, 'created_at')),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _pullAiAudit() async {
    final rows = await _fetchRows('ai_audit');
    await db.batch((batch) {
      for (final r in rows) {
        batch.insert(
          db.aiAudit,
          AiAuditCompanion(
            id: Value(_requiredString(r, 'id')),
            requestedAt: Value(_requiredInt(r, 'requested_at')),
            dateWindowStart: Value(r['date_window_start']?.toString()),
            dateWindowEnd: Value(r['date_window_end']?.toString()),
            inputSnapshotJson: Value(_requiredString(r, 'input_snapshot_json')),
            responseJson: Value(_requiredString(r, 'response_json')),
            schemaValid: Value(_requiredBool(r, 'schema_valid')),
            notes: Value(r['notes']?.toString()),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _pullPlanCycles() async {
    final rows = await _fetchRows('plan_cycles');
    await db.batch((batch) {
      for (final r in rows) {
        batch.insert(
          db.planCycles,
          PlanCyclesCompanion(
            id: Value(_requiredString(r, 'id')),
            cycleKey: Value(_requiredString(r, 'cycle_key')),
            weekStart: Value(_requiredString(r, 'week_start')),
            weekEnd: Value(_requiredString(r, 'week_end')),
            source: Value(_requiredString(r, 'source')),
            createdAt: Value(_requiredInt(r, 'created_at')),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _pullPlanDays() async {
    final rows = await _fetchRows('plan_days');
    await db.batch((batch) {
      for (final r in rows) {
        batch.insert(
          db.planDays,
          PlanDaysCompanion(
            id: Value(_requiredString(r, 'id')),
            planCycleId: Value(_requiredString(r, 'plan_cycle_id')),
            dayNumber: Value(_requiredInt(r, 'day_number')),
            sheetName: Value(_requiredString(r, 'sheet_name')),
            estimatedDate: Value(r['estimated_date']?.toString()),
            sessionType: Value(r['session_type']?.toString()),
            createdAt: Value(_requiredInt(r, 'created_at')),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _pullPlanPrescribedStrengthSets() async {
    final rows = await _fetchRows('plan_prescribed_strength_sets');
    await db.batch((batch) {
      for (final r in rows) {
        batch.insert(
          db.planPrescribedStrengthSets,
          PlanPrescribedStrengthSetsCompanion(
            id: Value(_requiredString(r, 'id')),
            planDayId: Value(_requiredString(r, 'plan_day_id')),
            exerciseCanonical: Value(_requiredString(r, 'exercise_canonical')),
            setIndex: Value(_requiredInt(r, 'set_index')),
            weight: Value(_asDouble(r['weight'])),
            reps: Value(_asInt(r['reps'])),
            rir: Value(_asInt(r['rir'])),
            unit: Value(_requiredString(r, 'unit')),
            rawSetString: Value(r['raw_set_string']?.toString()),
            createdAt: Value(_requiredInt(r, 'created_at')),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _pullPlanPrescribedRuns() async {
    final rows = await _fetchRows('plan_prescribed_runs');
    await db.batch((batch) {
      for (final r in rows) {
        batch.insert(
          db.planPrescribedRuns,
          PlanPrescribedRunsCompanion(
            id: Value(_requiredString(r, 'id')),
            planDayId: Value(_requiredString(r, 'plan_day_id')),
            dayLabel: Value(r['day_label']?.toString()),
            liftFocus: Value(r['lift_focus']?.toString()),
            runType: Value(r['run_type']?.toString()),
            durationText: Value(r['duration_text']?.toString()),
            targetPace: Value(r['target_pace']?.toString()),
            effortHrGuardrails: Value(r['effort_hr_guardrails']?.toString()),
            notes: Value(r['notes']?.toString()),
            createdAt: Value(_requiredInt(r, 'created_at')),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _pullPlanExerciseAlternatives() async {
    final rows = await _fetchRows('plan_exercise_alternatives');
    await db.batch((batch) {
      for (final r in rows) {
        batch.insert(
          db.planExerciseAlternatives,
          PlanExerciseAlternativesCompanion(
            id: Value(_requiredString(r, 'id')),
            planDayId: Value(r['plan_day_id']?.toString()),
            prescribedExerciseCanonical:
                Value(_requiredString(r, 'prescribed_exercise_canonical')),
            alternativeExerciseCanonical:
                Value(_requiredString(r, 'alternative_exercise_canonical')),
            priority: Value(_asInt(r['priority']) ?? 0),
            notes: Value(r['notes']?.toString()),
            createdAt: Value(_requiredInt(r, 'created_at')),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _pullExerciseSubstitutions() async {
    final rows = await _fetchRows('exercise_substitutions');
    await db.batch((batch) {
      for (final r in rows) {
        batch.insert(
          db.exerciseSubstitutions,
          ExerciseSubstitutionsCompanion(
            id: Value(_requiredString(r, 'id')),
            workoutDayId: Value(_requiredString(r, 'workout_day_id')),
            planDayId: Value(r['plan_day_id']?.toString()),
            prescribedExerciseCanonical:
                Value(_requiredString(r, 'prescribed_exercise_canonical')),
            substituteExerciseCanonical:
                Value(_requiredString(r, 'substitute_exercise_canonical')),
            reasonCode: Value(_requiredString(r, 'reason_code')),
            reasonNotes: Value(r['reason_notes']?.toString()),
            selectedAt: Value(_requiredInt(r, 'selected_at')),
            selectedBy: Value(r['selected_by']?.toString()),
            matchScore: Value(_asDouble(r['match_score'])),
            matchExplanationJson:
                Value(r['match_explanation_json']?.toString()),
            warningAcknowledged:
                Value(_asBool(r['warning_acknowledged']) ?? false),
            createdAt: Value(_requiredInt(r, 'created_at')),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _pullPlanSummarySnapshots() async {
    final rows = await _fetchRows('plan_summary_snapshots');
    await db.batch((batch) {
      for (final r in rows) {
        batch.insert(
          db.planSummarySnapshots,
          PlanSummarySnapshotsCompanion(
            id: Value(_requiredString(r, 'id')),
            planCycleId: Value(_requiredString(r, 'plan_cycle_id')),
            tabName: Value(_requiredString(r, 'tab_name')),
            snapshotJson: Value(_requiredString(r, 'snapshot_json')),
            createdAt: Value(_requiredInt(r, 'created_at')),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _pullPlanImportAudit() async {
    final rows = await _fetchRows('plan_import_audit');
    await db.batch((batch) {
      for (final r in rows) {
        batch.insert(
          db.planImportAudit,
          PlanImportAuditCompanion(
            id: Value(_requiredString(r, 'id')),
            importedAt: Value(_requiredInt(r, 'imported_at')),
            fileName: Value(_requiredString(r, 'file_name')),
            success: Value(_requiredBool(r, 'success')),
            detailsJson: Value(_requiredString(r, 'details_json')),
            conflictReportPath: Value(r['conflict_report_path']?.toString()),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _pullAthletePlanningProfiles() async {
    final rows = await _fetchRows('athlete_planning_profiles');
    await db.batch((batch) {
      for (final r in rows) {
        batch.insert(
          db.athletePlanningProfiles,
          AthletePlanningProfilesCompanion(
            id: Value(_requiredString(r, 'id')),
            workspaceId: Value(_requiredString(r, 'workspace_id')),
            athleteProfileId: Value(_requiredString(r, 'athlete_profile_id')),
            primaryGoal: Value(_requiredString(r, 'primary_goal')),
            goalTargetJson: Value(_requiredString(r, 'goal_target_json')),
            experienceLevel: Value(_requiredString(r, 'experience_level')),
            preferredSplit: Value(_requiredString(r, 'preferred_split')),
            daysPerWeek: Value(_requiredInt(r, 'days_per_week')),
            availableEquipmentJson:
                Value(_requiredString(r, 'available_equipment_json')),
            contraindicationsJson:
                Value(_requiredString(r, 'contraindications_json')),
            scheduleConstraintsJson:
                Value(_requiredString(r, 'schedule_constraints_json')),
            createdAt: Value(_requiredInt(r, 'created_at')),
            updatedAt: Value(_requiredInt(r, 'updated_at')),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _pullWeeklyPlanBuildRequests() async {
    final rows = await _fetchRows('weekly_plan_build_requests');
    await db.batch((batch) {
      for (final r in rows) {
        batch.insert(
          db.weeklyPlanBuildRequests,
          WeeklyPlanBuildRequestsCompanion(
            id: Value(_requiredString(r, 'id')),
            workspaceId: Value(_requiredString(r, 'workspace_id')),
            athleteProfileId: Value(_requiredString(r, 'athlete_profile_id')),
            weekStart: Value(_requiredString(r, 'week_start')),
            weekEnd: Value(_requiredString(r, 'week_end')),
            splitType: Value(_requiredString(r, 'split_type')),
            modifier: Value(_requiredString(r, 'modifier')),
            mode: Value(_requiredString(r, 'mode')),
            promptSnapshot: Value(_requiredString(r, 'prompt_snapshot')),
            requestPayloadJson:
                Value(_requiredString(r, 'request_payload_json')),
            responsePayloadJson: Value(r['response_payload_json']?.toString()),
            success: Value(_requiredBool(r, 'success')),
            errorText: Value(r['error_text']?.toString()),
            createdAt: Value(_requiredInt(r, 'created_at')),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _upsertWorkoutDays() async {
    final rows = await db.select(db.workoutDays).get();
    if (rows.isEmpty) {
      return;
    }
    await client.from('workout_days').upsert(
          rows
              .map((r) => _scopedRow({
                    'id': r.id,
                    'workout_date': r.workoutDate,
                    'created_at': r.createdAt,
                    'notes': r.notes,
                  }))
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
              .map((r) => _scopedRow({
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
                  }))
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
              .map((r) => _scopedRow({
                    'id': r.id,
                    'workout_day_id': r.workoutDayId,
                    'exercise_canonical': r.exerciseCanonical,
                    'set_index': r.setIndex,
                    'weight': r.weight,
                    'reps': r.reps,
                    'rir': r.rir,
                    'unit': r.unit,
                  }))
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
              .map((r) => _scopedRow({
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
                  }))
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
              .map((r) => _scopedRow({
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
                  }))
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
              .map((r) => _scopedRow({
                    'id': r.id,
                    'run_session_id': r.runSessionId,
                    'idx': r.idx,
                    'duration_s': r.durationS,
                    'distance_m': r.distanceM,
                    'speed_mps': r.speedMps,
                  }))
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
              .map((r) => _scopedRow({
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
                  }))
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
              .map((r) => _scopedRow({
                    'id': r.id,
                    'run_key': r.runKey,
                    'workout_day_id': r.workoutDayId,
                    'old_source': r.oldSource,
                    'new_source': r.newSource,
                    'old_snapshot_json': r.oldSnapshotJson,
                    'new_snapshot_json': r.newSnapshotJson,
                    'reason': r.reason,
                    'created_at': r.createdAt,
                  }))
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
              .map((r) => _scopedRow({
                    'id': r.id,
                    'trigger_date': r.triggerDate,
                    'rule_code': r.ruleCode,
                    'triggered': r.triggered,
                    'details_json': r.detailsJson,
                    'created_at': r.createdAt,
                  }))
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
              .map((r) => _scopedRow({
                    'id': r.id,
                    'requested_at': r.requestedAt,
                    'date_window_start': r.dateWindowStart,
                    'date_window_end': r.dateWindowEnd,
                    'input_snapshot_json': r.inputSnapshotJson,
                    'response_json': r.responseJson,
                    'schema_valid': r.schemaValid,
                    'notes': r.notes,
                  }))
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
              .map((r) => _scopedRow({
                    'id': r.id,
                    'cycle_key': r.cycleKey,
                    'week_start': r.weekStart,
                    'week_end': r.weekEnd,
                    'source': r.source,
                    'created_at': r.createdAt,
                  }))
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
              .map((r) => _scopedRow({
                    'id': r.id,
                    'plan_cycle_id': r.planCycleId,
                    'day_number': r.dayNumber,
                    'sheet_name': r.sheetName,
                    'estimated_date': r.estimatedDate,
                    'session_type': r.sessionType,
                    'created_at': r.createdAt,
                  }))
              .toList(),
          onConflict: 'id',
        );
  }

  Future<void> _upsertExerciseSubstitutions() async {
    final rows = await db.select(db.exerciseSubstitutions).get();
    await _deleteRemoteRowsMissingLocally(
      table: 'exercise_substitutions',
      localIds: rows.map((r) => r.id),
    );
    if (rows.isEmpty) {
      return;
    }
    await client.from('exercise_substitutions').upsert(
          rows
              .map((r) => _scopedRow({
                    'id': r.id,
                    'workout_day_id': r.workoutDayId,
                    'plan_day_id': r.planDayId,
                    'prescribed_exercise_canonical':
                        r.prescribedExerciseCanonical,
                    'substitute_exercise_canonical':
                        r.substituteExerciseCanonical,
                    'reason_code': r.reasonCode,
                    'reason_notes': r.reasonNotes,
                    'selected_at': r.selectedAt,
                    'selected_by': r.selectedBy,
                    'match_score': r.matchScore,
                    'match_explanation_json': r.matchExplanationJson,
                    'warning_acknowledged': r.warningAcknowledged,
                    'created_at': r.createdAt,
                  }))
              .toList(),
          onConflict: 'id',
        );
  }

  Future<void> _upsertPlanPrescribedStrengthSets() async {
    final rows = await db.select(db.planPrescribedStrengthSets).get();
    await _deleteRemoteRowsMissingLocally(
      table: 'plan_prescribed_strength_sets',
      localIds: rows.map((r) => r.id),
    );
    if (rows.isEmpty) {
      return;
    }
    await client.from('plan_prescribed_strength_sets').upsert(
          rows
              .map((r) => _scopedRow({
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
                  }))
              .toList(),
          onConflict: 'id',
        );
  }

  Future<void> _upsertPlanPrescribedRuns() async {
    final rows = await db.select(db.planPrescribedRuns).get();
    await _deleteRemoteRowsMissingLocally(
      table: 'plan_prescribed_runs',
      localIds: rows.map((r) => r.id),
    );
    if (rows.isEmpty) {
      return;
    }
    await client.from('plan_prescribed_runs').upsert(
          rows
              .map((r) => _scopedRow({
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
                  }))
              .toList(),
          onConflict: 'id',
        );
  }

  Future<void> _upsertPlanExerciseAlternatives() async {
    final rows = await db.select(db.planExerciseAlternatives).get();
    await _deleteRemoteRowsMissingLocally(
      table: 'plan_exercise_alternatives',
      localIds: rows.map((r) => r.id),
    );
    if (rows.isEmpty) {
      return;
    }
    await client.from('plan_exercise_alternatives').upsert(
          rows
              .map((r) => _scopedRow({
                    'id': r.id,
                    'plan_day_id': r.planDayId,
                    'prescribed_exercise_canonical':
                        r.prescribedExerciseCanonical,
                    'alternative_exercise_canonical':
                        r.alternativeExerciseCanonical,
                    'priority': r.priority,
                    'notes': r.notes,
                    'created_at': r.createdAt,
                  }))
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
              .map((r) => _scopedRow({
                    'id': r.id,
                    'plan_cycle_id': r.planCycleId,
                    'tab_name': r.tabName,
                    'snapshot_json': r.snapshotJson,
                    'created_at': r.createdAt,
                  }))
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
              .map((r) => _scopedRow({
                    'id': r.id,
                    'imported_at': r.importedAt,
                    'file_name': r.fileName,
                    'success': r.success,
                    'details_json': r.detailsJson,
                    'conflict_report_path': r.conflictReportPath,
                  }))
              .toList(),
          onConflict: 'id',
        );
  }

  Future<void> _upsertAthletePlanningProfiles() async {
    final rows = (await db.select(db.athletePlanningProfiles).get())
        .where((r) =>
            r.workspaceId == _context.workspaceId &&
            r.athleteProfileId == _context.athleteProfileId)
        .toList();
    if (rows.isEmpty) {
      return;
    }
    await client.from('athlete_planning_profiles').upsert(
          rows
              .map((r) => _scopedRow({
                    'id': r.id,
                    'primary_goal': r.primaryGoal,
                    'goal_target_json': r.goalTargetJson,
                    'experience_level': r.experienceLevel,
                    'preferred_split': r.preferredSplit,
                    'days_per_week': r.daysPerWeek,
                    'available_equipment_json': r.availableEquipmentJson,
                    'contraindications_json': r.contraindicationsJson,
                    'schedule_constraints_json': r.scheduleConstraintsJson,
                    'created_at': r.createdAt,
                    'updated_at': r.updatedAt,
                  }))
              .toList(),
          onConflict: 'id',
        );
  }

  Future<void> _upsertWeeklyPlanBuildRequests() async {
    final rows = (await db.select(db.weeklyPlanBuildRequests).get())
        .where((r) =>
            r.workspaceId == _context.workspaceId &&
            r.athleteProfileId == _context.athleteProfileId)
        .toList();
    if (rows.isEmpty) {
      return;
    }
    await client.from('weekly_plan_build_requests').upsert(
          rows
              .map((r) => _scopedRow({
                    'id': r.id,
                    'week_start': r.weekStart,
                    'week_end': r.weekEnd,
                    'split_type': r.splitType,
                    'modifier': r.modifier,
                    'mode': r.mode,
                    'prompt_snapshot': r.promptSnapshot,
                    'request_payload_json': r.requestPayloadJson,
                    'response_payload_json': r.responsePayloadJson,
                    'success': r.success,
                    'error_text': r.errorText,
                    'created_at': r.createdAt,
                  }))
              .toList(),
          onConflict: 'id',
        );
  }

  Future<void> _deleteRemoteRowsMissingLocally({
    required String table,
    required Iterable<String> localIds,
  }) async {
    final localIdSet = localIds.toSet();
    if (localIdSet.isEmpty) {
      return;
    }
    final remoteRows = await _fetchRows(table, columns: 'id');
    final staleIds = remoteRows
        .map((r) => r['id']?.toString())
        .whereType<String>()
        .where((id) => !localIdSet.contains(id))
        .toList();
    if (staleIds.isEmpty) {
      return;
    }
    const chunkSize = 200;
    for (var i = 0; i < staleIds.length; i += chunkSize) {
      final end =
          (i + chunkSize < staleIds.length) ? i + chunkSize : staleIds.length;
      final chunk = staleIds.sublist(i, end);
      await client
          .from(table)
          .delete()
          .eq('workspace_id', _context.workspaceId)
          .eq('athlete_profile_id', _context.athleteProfileId)
          .inFilter('id', chunk);
    }
  }
}

class _ScopedSyncContext {
  const _ScopedSyncContext({
    required this.workspaceId,
    required this.athleteProfileId,
  });

  final String workspaceId;
  final String athleteProfileId;
}
