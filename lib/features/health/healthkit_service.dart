import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/app_db_operation_gate.dart';
import '../../core/utils/date_utils.dart';
import '../../db/app_db.dart';

class HealthKitSyncResult {
  const HealthKitSyncResult({
    required this.available,
    required this.enabled,
    required this.workoutsImported,
    required this.workoutsUpdated,
    required this.workoutsPreserved,
    required this.sleepNightsImported,
    required this.message,
  });

  const HealthKitSyncResult.unavailable(this.message)
      : available = false,
        enabled = false,
        workoutsImported = 0,
        workoutsUpdated = 0,
        workoutsPreserved = 0,
        sleepNightsImported = 0;

  final bool available;
  final bool enabled;
  final int workoutsImported;
  final int workoutsUpdated;
  final int workoutsPreserved;
  final int sleepNightsImported;
  final String message;
}

class HealthKitService {
  HealthKitService({
    required this.db,
    required this.preferences,
    this.workspaceId = 'local_workspace',
    this.athleteProfileId = 'local_profile',
    Health? health,
  }) : _health = health ?? Health();

  final AppDb db;
  final SharedPreferences? preferences;
  final String workspaceId;
  final String athleteProfileId;
  final Health _health;

  static const _enabledKey = 'healthkit_sync_enabled_v1';
  static const _cursorKey = 'healthkit_sync_cursor_ms_v1';
  static final Expando<Future<HealthKitSyncResult>> _inFlight =
      Expando<Future<HealthKitSyncResult>>();

  static const _sleepTypes = <HealthDataType>[
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_AWAKE,
  ];
  static const _readTypes = <HealthDataType>[
    HealthDataType.WORKOUT,
    HealthDataType.HEART_RATE,
    HealthDataType.WEIGHT,
    ..._sleepTypes,
  ];

  bool get isAvailable => !kIsWeb && Platform.isIOS;
  bool get isEnabled =>
      isAvailable && (preferences?.getBool(_enabledKey) ?? false);
  DateTime? get lastSuccessfulSync {
    final millis = preferences?.getInt(_cursorKey);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<HealthKitSyncResult> connectAndSync() async {
    if (!isAvailable) {
      return const HealthKitSyncResult.unavailable(
        'Apple Health is available only on a supported iPhone.',
      );
    }
    final preferences = this.preferences;
    if (preferences == null) {
      return const HealthKitSyncResult.unavailable(
        'App settings are still loading. Try again in a moment.',
      );
    }
    try {
      await _health.configure();
      final requested = await _health.requestAuthorization(
        _readTypes,
        permissions: List<HealthDataAccess>.filled(
          _readTypes.length,
          HealthDataAccess.READ,
        ),
      );
      if (!requested) {
        await preferences.setBool(_enabledKey, false);
        return const HealthKitSyncResult(
          available: true,
          enabled: false,
          workoutsImported: 0,
          workoutsUpdated: 0,
          workoutsPreserved: 0,
          sleepNightsImported: 0,
          message: 'Apple Health access was not completed.',
        );
      }
      await preferences.setBool(_enabledKey, true);
      return syncIfEnabled();
    } catch (error) {
      return HealthKitSyncResult(
        available: true,
        enabled: false,
        workoutsImported: 0,
        workoutsUpdated: 0,
        workoutsPreserved: 0,
        sleepNightsImported: 0,
        message: _friendlyError(error),
      );
    }
  }

  Future<void> disconnect() async {
    await preferences?.setBool(_enabledKey, false);
  }

  Future<HealthKitSyncResult> syncIfEnabled() {
    final running = _inFlight[db];
    if (running != null) return running;
    final future = AppDbOperationGate.run(db, _syncIfEnabled);
    _inFlight[db] = future;
    unawaited(future.whenComplete(() {
      if (identical(_inFlight[db], future)) _inFlight[db] = null;
    }));
    return future;
  }

  Future<HealthKitSyncResult> _syncIfEnabled() async {
    if (!isAvailable) {
      return const HealthKitSyncResult.unavailable(
        'Apple Health is available only on a supported iPhone.',
      );
    }
    if (!isEnabled) {
      return const HealthKitSyncResult(
        available: true,
        enabled: false,
        workoutsImported: 0,
        workoutsUpdated: 0,
        workoutsPreserved: 0,
        sleepNightsImported: 0,
        message: 'Apple Health is not connected.',
      );
    }
    final preferences = this.preferences;
    if (preferences == null) {
      return const HealthKitSyncResult.unavailable(
        'App settings are still loading. Try again in a moment.',
      );
    }

    try {
      await _health.configure();
      final now = DateTime.now();
      final previous = lastSuccessfulSync;
      final start = previous == null
          ? now.subtract(const Duration(days: 30))
          : previous.subtract(const Duration(days: 2));
      final end = now.add(const Duration(minutes: 5));
      final points = await _health.getHealthDataFromTypes(
        types: const [
          HealthDataType.WORKOUT,
          HealthDataType.WEIGHT,
          ..._sleepTypes
        ],
        startTime: start,
        endTime: end,
      );

      var inserted = 0;
      var updated = 0;
      var preserved = 0;
      final bodyWeights = points
          .where((point) => point.type == HealthDataType.WEIGHT)
          .where((point) => point.value is NumericHealthValue)
          .toList()
        ..sort((a, b) => b.dateTo.compareTo(a.dateTo));
      var bodyWeightImported = false;
      for (final point in bodyWeights) {
        final value = point.value as NumericHealthValue;
        bodyWeightImported = await db.saveAppleHealthBodyWeight(
          workspaceId: workspaceId,
          athleteProfileId: athleteProfileId,
          kilograms: value.numericValue.toDouble(),
          measuredAt: point.dateTo,
        );
        if (bodyWeightImported) break;
      }
      final workouts = points
          .where((point) => point.type == HealthDataType.WORKOUT)
          .toList()
        ..sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
      for (final point in workouts) {
        final value = point.value;
        if (value is! WorkoutHealthValue ||
            !point.dateTo.isAfter(point.dateFrom)) {
          continue;
        }
        final heartRate = await _heartRateForWorkout(point);
        final activity = _activityCode(value.workoutActivityType);
        final outcome = await db.upsertAppleHealthWorkout(
          healthKitUuid: point.uuid.isEmpty
              ? '${point.dateFrom.millisecondsSinceEpoch}_$activity'
              : point.uuid,
          start: point.dateFrom.toLocal(),
          end: point.dateTo.toLocal(),
          activityType: activity,
          title: _activityTitle(value.workoutActivityType),
          distanceM: value.totalDistance?.toDouble(),
          avgHr: heartRate.$1,
          maxHr: heartRate.$2,
          calories: value.totalEnergyBurned,
          rawMetrics: {
            'healthkit_uuid': point.uuid,
            'source_id': point.sourceId,
            'source_name': point.sourceName,
            'device_model': point.deviceModel,
            'recording_method': point.recordingMethod.name,
            'workout_type': value.workoutActivityType.name,
            'total_steps': value.totalSteps,
          },
        );
        if (outcome.inserted) {
          inserted++;
        } else if (outcome.updated) {
          updated++;
        } else {
          preserved++;
        }
      }

      final sleepNights = await _importSleep(points);
      await preferences.setInt(_cursorKey, now.millisecondsSinceEpoch);
      return HealthKitSyncResult(
        available: true,
        enabled: true,
        workoutsImported: inserted,
        workoutsUpdated: updated,
        workoutsPreserved: preserved,
        sleepNightsImported: sleepNights,
        message: inserted + updated + sleepNights == 0
            ? 'Apple Health is connected. No new shared workouts or sleep were found.'
            : 'Imported $inserted new and $updated updated workout${inserted + updated == 1 ? '' : 's'}, plus $sleepNights sleep night${sleepNights == 1 ? '' : 's'}${bodyWeightImported ? ' and the latest body-weight measurement' : ''}.',
      );
    } catch (error) {
      return HealthKitSyncResult(
        available: true,
        enabled: true,
        workoutsImported: 0,
        workoutsUpdated: 0,
        workoutsPreserved: 0,
        sleepNightsImported: 0,
        message: _friendlyError(error),
      );
    }
  }

  Future<(double?, double?)> _heartRateForWorkout(
      HealthDataPoint workout) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.HEART_RATE],
        startTime: workout.dateFrom,
        endTime: workout.dateTo,
      );
      final values = points
          .map((point) => point.value)
          .whereType<NumericHealthValue>()
          .map((value) => value.numericValue.toDouble())
          .where((value) => value > 0 && value < 300)
          .toList(growable: false);
      if (values.isEmpty) return (null, null);
      final total = values.fold<double>(0, (sum, value) => sum + value);
      final maximum = values.reduce((a, b) => a > b ? a : b);
      // Apple Health may return a slightly different sample set on a later
      // read. Average heart rate is presented in whole BPM, so avoid syncing
      // insignificant fractional changes as edits to historical workouts.
      return ((total / values.length).roundToDouble(), maximum.roundToDouble());
    } catch (_) {
      // Heart rate can be withheld while workout access remains available.
      return (null, null);
    }
  }

  Future<int> _importSleep(List<HealthDataPoint> points) async {
    final nights = <String, _SleepNightBucket>{};
    for (final point in points) {
      if (!_sleepTypes.contains(point.type) ||
          !point.dateTo.isAfter(point.dateFrom)) {
        continue;
      }
      final end = point.dateTo.toLocal();
      final date = toYmd(DateTime(end.year, end.month, end.day));
      final bucket = nights.putIfAbsent(date, _SleepNightBucket.new);
      bucket.add(point.type, point.dateFrom.toLocal(), end);
    }

    var imported = 0;
    for (final entry in nights.entries) {
      final summary = entry.value.summary();
      if (summary.totalSleepMin <= 0) continue;
      final existing = await db.getSleepNightByDate(entry.key);
      if (existing != null && existing.source != 'apple_health') {
        continue;
      }
      await db.upsertSleepNight(
        date: entry.key,
        totalSleepMin: summary.totalSleepMin,
        source: 'apple_health',
        startTime: summary.start.millisecondsSinceEpoch,
        endTime: summary.end.millisecondsSinceEpoch,
        remMin: summary.remMin,
        deepMin: summary.deepMin,
        lightMin: summary.lightMin,
        awakeMin: summary.awakeMin,
      );
      imported++;
    }
    return imported;
  }

  String _activityCode(HealthWorkoutActivityType type) =>
      type.name.toLowerCase();

  String _activityTitle(HealthWorkoutActivityType type) => type.name
      .toLowerCase()
      .split('_')
      .map((part) => part.isEmpty
          ? part
          : '${part.substring(0, 1).toUpperCase()}${part.substring(1)}')
      .join(' ');

  String _friendlyError(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('protected health data is inaccessible')) {
      return 'Unlock the iPhone, then try the Apple Health sync again.';
    }
    if (raw.contains('not available') || raw.contains('missingplugin')) {
      return 'Apple Health is not available on this device or build.';
    }
    return 'Apple Health could not sync. Your existing training data was not changed.';
  }
}

class _SleepNightBucket {
  final Map<HealthDataType, List<(DateTime, DateTime)>> _intervals = {};
  DateTime? _start;
  DateTime? _end;

  void add(HealthDataType type, DateTime start, DateTime end) {
    (_intervals[type] ??= []).add((start, end));
    if (_start == null || start.isBefore(_start!)) _start = start;
    if (_end == null || end.isAfter(_end!)) _end = end;
  }

  _SleepSummary summary() {
    final light = _minutes(HealthDataType.SLEEP_LIGHT);
    final deep = _minutes(HealthDataType.SLEEP_DEEP);
    final rem = _minutes(HealthDataType.SLEEP_REM);
    final staged = light + deep + rem;
    final generic = _minutes(HealthDataType.SLEEP_ASLEEP);
    return _SleepSummary(
      start: _start!,
      end: _end!,
      totalSleepMin: staged > 0 ? staged : generic,
      lightMin: light,
      deepMin: deep,
      remMin: rem,
      awakeMin: _minutes(HealthDataType.SLEEP_AWAKE),
    );
  }

  int _minutes(HealthDataType type) {
    final intervals = [...?_intervals[type]]
      ..sort((a, b) => a.$1.compareTo(b.$1));
    if (intervals.isEmpty) return 0;
    var start = intervals.first.$1;
    var end = intervals.first.$2;
    var total = Duration.zero;
    for (final interval in intervals.skip(1)) {
      if (!interval.$1.isAfter(end)) {
        if (interval.$2.isAfter(end)) end = interval.$2;
      } else {
        total += end.difference(start);
        start = interval.$1;
        end = interval.$2;
      }
    }
    total += end.difference(start);
    return total.inMinutes;
  }
}

class _SleepSummary {
  const _SleepSummary({
    required this.start,
    required this.end,
    required this.totalSleepMin,
    required this.lightMin,
    required this.deepMin,
    required this.remMin,
    required this.awakeMin,
  });

  final DateTime start;
  final DateTime end;
  final int totalSleepMin;
  final int lightMin;
  final int deepMin;
  final int remMin;
  final int awakeMin;
}
