import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/rules/recovery_gating.dart';
import '../../core/rules/treadmill_artifact_detector.dart';
import '../../core/utils/app_providers.dart';
import '../../core/utils/date_utils.dart';
import '../../db/app_db.dart';
import '../ai/ai_analyze_service.dart';
import '../ui/clinical_theme.dart';
import '../ui/clinical_widgets.dart';
import 'run_inputs_screen.dart';
import 'workout_day_detail_screen.dart';

String _formatMinutesAsHoursMinutes(int? totalMinutes) {
  if (totalMinutes == null) {
    return 'unknown';
  }
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return '${hours}h ${minutes}m';
}

String _formatDuration(int? seconds) {
  if (seconds == null) {
    return 'unknown';
  }
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  return '${minutes}m ${remaining.toString().padLeft(2, '0')}s';
}

String _formatDistanceKm(double? meters) {
  if (meters == null) {
    return 'unknown';
  }
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

String _formatHeaderDate(String ymd) {
  final date = parseYmd(ymd);
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

Map<int, String> _manualSegmentLabelsByIdx(String? rawMetricsJson) {
  if (rawMetricsJson == null || rawMetricsJson.trim().isEmpty) {
    return const <int, String>{};
  }
  try {
    final decoded = jsonDecode(rawMetricsJson);
    if (decoded is! Map) {
      return const <int, String>{};
    }
    final rawSegments = decoded['manual_segments'];
    if (rawSegments is! List) {
      return const <int, String>{};
    }

    final labels = <int, String>{};
    for (final segment in rawSegments) {
      if (segment is! Map) {
        continue;
      }
      final idx = int.tryParse('${segment['idx'] ?? ''}');
      if (idx == null) {
        continue;
      }
      final kind = '${segment['kind'] ?? ''}'.trim().toLowerCase();
      if (kind == 'rest') {
        labels[idx] = 'Rest';
      } else if (kind == 'interval') {
        labels[idx] = 'Interval';
      }
    }
    return labels;
  } catch (_) {
    return const <int, String>{};
  }
}

class DailyScreen extends ConsumerStatefulWidget {
  const DailyScreen({super.key});

  @override
  ConsumerState<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends ConsumerState<DailyScreen> {
  late String _selectedDate;
  int _refresh = 0;

  String _sessionTypeLabel(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized.contains('push')) {
      return 'Push';
    }
    if (normalized.contains('pull')) {
      return 'Pull';
    }
    if (normalized.contains('leg')) {
      return 'Legs';
    }
    if (normalized.contains('rest')) {
      return 'Rest';
    }
    return 'Unknown';
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = toYmd(DateTime.now());
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: parseYmd(_selectedDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = toYmd(picked);
      });
    }
  }

  Future<void> _runMockAi(WorkoutDayDetail detail, int treadmillExcluded,
      RecoveryGateResult gate) async {
    final aiService = ref.read(aiAnalyzeServiceProvider);
    final db = ref.read(appDbProvider);

    final actualCount =
        detail.groups.fold<int>(0, (sum, group) => sum + group.actual.length);
    final sleepMin = detail.sleepNights.isEmpty
        ? null
        : detail.sleepNights.first.totalSleepMin;

    final request = AiAnalyzeRequest(
      date: _selectedDate,
      runsCount: detail.runSessions.length,
      sleepMinutes: sleepMin,
      strengthSetsCount: actualCount,
      treadmillExcludedSegments: treadmillExcluded,
      progressionAllowed: gate.progressionAllowed,
      progressionReasoning: gate.reasoning,
      dataUsedIds: [
        if (detail.workoutDay != null) detail.workoutDay!.id,
        ...detail.runSessions.map((r) => r.session.id),
        ...detail.sleepNights.map((s) => s.id),
      ],
      rulesTriggered: [
        if (!gate.progressionAllowed) 'RECOVERY_GATE_BLOCK',
        if (treadmillExcluded > 0) 'TREADMILL_ARTIFACT_EXCLUDED',
      ],
    );

    final response = await aiService.analyze(request);

    await db.insertAiAudit(
      requestedAt: unixMsNow(),
      dateWindowStart: _selectedDate,
      dateWindowEnd: _selectedDate,
      inputSnapshot: request.toSnapshotJson(),
      response: response.toJson(),
      schemaValid: true,
      notes: 'mocked AI service',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mock AI analysis saved to audit.')));
      setState(() => _refresh++);
    }
  }

  Future<void> _openSleepEditor(SleepNight? existing) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _SleepEditorDialog(
        selectedDate: _selectedDate,
        existing: existing,
      ),
    );
    if (mounted) {
      setState(() => _refresh++);
    }
  }

  Future<String?> _pickSkipTypeDialog(List<String> options) async {
    if (options.isEmpty) {
      return null;
    }
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Future Rest Day'),
        content: const Text('Choose a day type to skip to push the split.'),
        actions: [
          for (final type in options)
            TextButton(
              onPressed: () => Navigator.of(context).pop(type),
              child: Text('Skip ${_sessionTypeLabel(type)}'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _markRestDayAndPush(WorkoutDayDetail detail) async {
    final db = ref.read(appDbProvider);
    if ((detail.planSessionType ?? '').toLowerCase().contains('rest')) {
      _showSnack('Selected day is already marked as rest.');
      return;
    }

    try {
      await db.markRestDayAndPushSplit(dateYmd: _selectedDate);
      if (!mounted) {
        return;
      }
      _showSnack('Split updated. Rest day inserted and future days shifted.');
      setState(() => _refresh++);
    } on StateError catch (e) {
      final message = e.message.toString();
      if (!message.contains('Choose a day type to skip')) {
        _showSnack(message);
        return;
      }
      final options = await db.getAvailableSkipDayTypesForDate(_selectedDate);
      if (options.isEmpty) {
        _showSnack(
            'No future Push/Pull/Legs day is available to skip in this split.');
        return;
      }
      final selected = await _pickSkipTypeDialog(options);
      if (selected == null) {
        return;
      }
      try {
        await db.markRestDayAndPushSplit(
          dateYmd: _selectedDate,
          skipSessionType: selected,
        );
        if (!mounted) {
          return;
        }
        _showSnack(
            'Split updated. Rest day inserted and ${_sessionTypeLabel(selected)} skipped.');
        setState(() => _refresh++);
      } on StateError catch (inner) {
        _showSnack(inner.message.toString());
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  AiAnalyzeResponse? _latestAiSummary(WorkoutDayDetail detail) {
    if (detail.aiAudits.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(detail.aiAudits.first.responseJson);
      if (decoded is Map<String, dynamic>) {
        return AiAnalyzeResponse.fromJson(decoded);
      }
      if (decoded is Map) {
        return AiAnalyzeResponse.fromJson(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  List<double> _sparklineSeries(WorkoutDayDetail detail) {
    if (detail.runSessions.isEmpty) {
      return const <double>[0.16, 0.24, 0.21, 0.44, 0.58, 0.52, 0.56];
    }

    final raw = detail.runSessions
        .map((run) {
          final distance = run.session.distanceM;
          if (distance != null && distance > 0) {
            return distance / 1000;
          }
          final duration = run.session.durationS;
          if (duration != null && duration > 0) {
            return duration / 600;
          }
          return 0.2;
        })
        .toList()
        .cast<double>();

    final start = math.max(0, raw.length - 7);
    final sliced = raw.sublist(start);

    while (sliced.length < 7) {
      sliced.insert(0, 0.15);
    }

    final maxVal = sliced.reduce(math.max);
    if (maxVal <= 0) {
      return List<double>.filled(7, 0.2);
    }

    return sliced
        .map((value) => (value / maxVal).clamp(0.08, 1.0).toDouble())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(appDbProvider);

    return FutureBuilder<WorkoutDayDetail>(
      key: ValueKey('daily-$_selectedDate-$_refresh'),
      future: db
          .getWorkoutDayDetail(_selectedDate)
          .timeout(const Duration(seconds: 12)),
      builder: (context, snapshot) {
        final detail = snapshot.data;
        final loading = snapshot.connectionState == ConnectionState.waiting;

        if (loading && detail == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError && detail == null) {
          final error = snapshot.error;
          final timeout = error is TimeoutException;
          return _DailyLoadError(
            message: timeout
                ? 'Daily page load timed out. Try again.'
                : 'Daily page failed to load.',
            details: error?.toString(),
            onRetry: () => setState(() => _refresh++),
            onOpenRunInputs: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RunInputsScreen()),
              );
            },
          );
        }

        final safeDetail = detail ??
            WorkoutDayDetail(
              date: _selectedDate,
              workoutDay: null,
              planCycleId: null,
              planDayNumber: null,
              planSessionType: null,
              prescribedRun: null,
              sleepNights: const <SleepNight>[],
              runSessions: const <RunSessionWithSegments>[],
              groups: const <ExerciseSetGroup>[],
              ruleTriggers: const <RuleTrigger>[],
              aiAudits: const <AiAuditData>[],
              runOverrideAudits: const <RunOverrideAuditData>[],
            );

        final sleepNight = safeDetail.sleepNights.isEmpty
            ? null
            : safeDetail.sleepNights.first;
        final sleepMin = sleepNight?.totalSleepMin;
        final gate = RecoveryGating.evaluate(sleepMin);

        var excluded = 0;
        for (final run in safeDetail.runSessions) {
          final detectorResult = TreadmillArtifactDetector.filter(
            run.segments
                .map(
                  (s) => SegmentInput(
                    id: s.id,
                    idx: s.idx,
                    speedMps: s.speedMps,
                    durationS: s.durationS,
                    distanceM: s.distanceM,
                  ),
                )
                .toList(),
          );
          excluded += detectorResult.excludedCount;
        }

        final aiSummary = _latestAiSummary(safeDetail);
        final runSeries = _sparklineSeries(safeDetail);
        final runProgress = safeDetail.runSessions.isEmpty
            ? 0.0
            : (safeDetail.runSessions.length / 7).clamp(0.0, 1.0).toDouble();
        final totalRunDistance = safeDetail.runSessions.fold<double>(
          0,
          (sum, run) => sum + (run.session.distanceM ?? 0),
        );

        return _DailyClinicalContent(
          selectedDate: _selectedDate,
          safeDetail: safeDetail,
          sleepNight: sleepNight,
          sleepMin: sleepMin,
          gate: gate,
          excluded: excluded,
          aiSummary: aiSummary,
          runSeries: runSeries,
          runProgress: runProgress,
          totalRunDistance: totalRunDistance,
          sessionTypeLabel: _sessionTypeLabel,
          onPickDate: _pickDate,
          onOpenSleepEditor: _openSleepEditor,
          onRunInputs: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RunInputsScreen()),
            );
          },
          onOpenWorkoutDetail: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WorkoutDayDetailScreen(date: _selectedDate),
              ),
            );
          },
          onMarkRest: safeDetail.planDayNumber == null
              ? null
              : () => _markRestDayAndPush(safeDetail),
          onRunMockAi: () => _runMockAi(safeDetail, excluded, gate),
          onRefresh: () async => setState(() => _refresh++),
        );
      },
    );
  }
}

class _DailyClinicalContent extends StatelessWidget {
  const _DailyClinicalContent({
    required this.selectedDate,
    required this.safeDetail,
    required this.sleepNight,
    required this.sleepMin,
    required this.gate,
    required this.excluded,
    required this.aiSummary,
    required this.runSeries,
    required this.runProgress,
    required this.totalRunDistance,
    required this.sessionTypeLabel,
    required this.onPickDate,
    required this.onOpenSleepEditor,
    required this.onRunInputs,
    required this.onOpenWorkoutDetail,
    required this.onMarkRest,
    required this.onRunMockAi,
    required this.onRefresh,
  });

  final String selectedDate;
  final WorkoutDayDetail safeDetail;
  final SleepNight? sleepNight;
  final int? sleepMin;
  final RecoveryGateResult gate;
  final int excluded;
  final AiAnalyzeResponse? aiSummary;
  final List<double> runSeries;
  final double runProgress;
  final double totalRunDistance;
  final String Function(String?) sessionTypeLabel;
  final VoidCallback onPickDate;
  final void Function(SleepNight?) onOpenSleepEditor;
  final VoidCallback onRunInputs;
  final VoidCallback onOpenWorkoutDetail;
  final VoidCallback? onMarkRest;
  final VoidCallback onRunMockAi;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 14),
            const ClinicalBanner(
              text: 'Clinical Focus: Sustainable Progress & Recovery',
            ),
            const SizedBox(height: 14),
            _buildMetricGrid(context),
            const SizedBox(height: 14),
            _buildAiSummary(context),
            const SizedBox(height: 12),
            _buildPrimaryLargeActions(context),
            const SizedBox(height: 10),
            _buildSecondaryActionRow(context),
            const SizedBox(height: 16),
            const ClinicalDivider(),
            const SectionHeader(text: 'Prescribed Run'),
            const SizedBox(height: 8),
            _buildPrescribedRun(context),
            const SizedBox(height: 16),
            const SectionHeader(text: 'Runs'),
            const SizedBox(height: 8),
            RunsTrack(value: runProgress),
            const SizedBox(height: 6),
            Text(
              '${safeDetail.runSessions.length} session${safeDetail.runSessions.length == 1 ? '' : 's'} logged • '
              '${totalRunDistance <= 0 ? 'No total distance' : _formatDistanceKm(totalRunDistance)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            _buildRunsList(context),
            const SizedBox(height: 8),
            const SectionHeader(text: 'Strength'),
            const SizedBox(height: 8),
            _buildStrength(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final compact = constraints.maxWidth < 680 || textScale > 1.15;
        final title = Text(
          'ATHLETIC ADAPTATION PROGRESS - ${_formatHeaderDate(selectedDate)}',
          maxLines: compact ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
        );

        final pickDateButton = SizedBox(
          width: compact ? double.infinity : 160,
          child: PrimaryPillButton(
            text: 'Pick Date',
            icon: Icons.calendar_month_outlined,
            variant: PillButtonVariant.outlined,
            onPressed: onPickDate,
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 12),
              pickDateButton,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: 12),
            pickDateButton,
          ],
        );
      },
    );
  }

  Widget _buildMetricGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final singleColumn = constraints.maxWidth < 390 || textScale >= 1.25;
        final ratio = singleColumn
            ? 2.2
            : (constraints.maxWidth < 450 || textScale > 1.1 ? 1.15 : 1.75);
        return GridView.count(
          crossAxisCount: singleColumn ? 1 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: ratio,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            MetricTile(
              title: 'Sleep',
              leadingIcon: Icons.bedtime_outlined,
              valueText: _formatMinutesAsHoursMinutes(sleepMin),
              subtitleText: 'Tap to view/edit',
              trailingWidget: Icon(
                Icons.monitor_heart_outlined,
                color: const Color(0xFFF08A7F).withValues(alpha: 0.95),
              ),
              onTap: () => onOpenSleepEditor(sleepNight),
            ),
            MetricTile(
              title: 'Run',
              leadingIcon: Icons.directions_run_rounded,
              valueText:
                  '${safeDetail.runSessions.length} session${safeDetail.runSessions.length == 1 ? '' : 's'}',
              subtitleText: totalRunDistance <= 0
                  ? 'No distance captured yet'
                  : _formatDistanceKm(totalRunDistance),
              trailingWidget: SizedBox(
                width: 96,
                height: 36,
                child: CustomPaint(
                  painter: _RunSparklinePainter(values: runSeries),
                ),
              ),
            ),
            MetricTile(
              title: 'Health Alerts',
              leadingIcon: Icons.health_and_safety_outlined,
              valueText: gate.progressionAllowed
                  ? 'Recovery stable'
                  : 'Needs recovery',
              subtitleText: '${gate.reasoning}; artifacts: $excluded',
              trailingWidget: _AlertIconStrip(
                progressionAllowed: gate.progressionAllowed,
                artifacts: excluded,
              ),
            ),
            MetricTile(
              title: 'Split',
              leadingIcon: Icons.fitness_center_outlined,
              valueText: safeDetail.planDayNumber == null
                  ? 'No split linked'
                  : 'Day ${safeDetail.planDayNumber} • ${sessionTypeLabel(safeDetail.planSessionType)}',
              subtitleText: 'Tap Open Workout Day Detail below',
              trailingWidget: const Icon(
                Icons.fitness_center,
                color: Color(0xFFE4B6FF),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAiSummary(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.analytics_outlined, size: 18),
              Text(
                'Clinical AI Snapshot',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (aiSummary == null)
            Text(
              'No AI audits yet. Run Mock AI Analysis to generate a summary.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else ...[
            Text(
              aiSummary!.reasoning,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FlagChip(
                  label: aiSummary!.progressionAllowed
                      ? 'Progression allowed'
                      : 'Progression held',
                  color: aiSummary!.progressionAllowed
                      ? ClinicalPalette.accentSecondary
                      : ClinicalPalette.warningMuted,
                ),
                if (aiSummary!.flags.lowSleep)
                  const _FlagChip(
                    label: 'Low sleep',
                    color: ClinicalPalette.warningMuted,
                  ),
                if (aiSummary!.flags.treadmillArtifactsDetected)
                  const _FlagChip(
                    label: 'Treadmill artifacts',
                    color: ClinicalPalette.warningMuted,
                  ),
                if (aiSummary!.flags.missingMetrics)
                  const _FlagChip(
                    label: 'Missing metrics',
                    color: ClinicalPalette.warningMuted,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Runs: ${aiSummary!.extractedDataSummary.runsSummary} | '
              'Sleep: ${aiSummary!.extractedDataSummary.sleepSummary} | '
              'Strength: ${aiSummary!.extractedDataSummary.strengthSummary}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrimaryLargeActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: PrimaryPillButton(
            text: 'Run Inputs',
            variant: PillButtonVariant.tonal,
            onPressed: onRunInputs,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: PrimaryPillButton(
            text: 'Open Workout Day Detail',
            variant: PillButtonVariant.tonal,
            onPressed: onOpenWorkoutDetail,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryActionRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final compact = constraints.maxWidth < 680 || textScale > 1.15;
        if (compact) {
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: PrimaryPillButton(
                  text: 'Mark Rest Day + Push Split',
                  icon: Icons.playlist_add_check_circle_outlined,
                  variant: PillButtonVariant.tonal,
                  onPressed: onMarkRest,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: PrimaryPillButton(
                  text: 'Run Mock AI Analysis',
                  variant: PillButtonVariant.outlined,
                  onPressed: onRunMockAi,
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: PrimaryPillButton(
                text: 'Mark Rest Day + Push Split',
                icon: Icons.playlist_add_check_circle_outlined,
                variant: PillButtonVariant.tonal,
                onPressed: onMarkRest,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryPillButton(
                text: 'Run Mock AI Analysis',
                variant: PillButtonVariant.outlined,
                onPressed: onRunMockAi,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrescribedRun(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final stackIcon = textScale > 1.2;

    final content = safeDetail.prescribedRun?.runType == null
        ? const Text('No prescribed run linked to this day.')
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clinical Prescription',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              _LabeledLine(
                label: 'Type',
                value: safeDetail.prescribedRun?.runType ?? 'unknown',
              ),
              _LabeledLine(
                label: 'Duration',
                value: safeDetail.prescribedRun?.durationText ?? 'unknown',
              ),
              _LabeledLine(
                label: 'Pace',
                value: safeDetail.prescribedRun?.targetPace ?? 'unknown',
              ),
              _LabeledLine(
                label: 'HR Zone',
                value:
                    safeDetail.prescribedRun?.effortHrGuardrails ?? 'unknown',
              ),
              _LabeledLine(
                label: 'Focus',
                value: safeDetail.prescribedRun?.notes ??
                    safeDetail.prescribedRun?.liftFocus ??
                    'Mechanics & Recovery',
              ),
            ],
          );

    final iconBubble = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.directions_run),
    );

    return GlassCard(
      child: stackIcon
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: iconBubble),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: content),
                const SizedBox(width: 12),
                iconBubble,
              ],
            ),
    );
  }

  Widget _buildRunsList(BuildContext context) {
    if (safeDetail.runSessions.isEmpty) {
      return const GlassCard(child: Text('No runs logged for this date.'));
    }

    return Column(
      children: safeDetail.runSessions.map((run) {
        final segmentLabels =
            _manualSegmentLabelsByIdx(run.session.rawMetricsJson);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(run.session.source)),
                    if (run.overrodeManual)
                      const Chip(label: Text('overrode manual')),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  run.session.title ?? 'untitled run',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Duration: ${_formatDuration(run.session.durationS)} | '
                  'Distance: ${_formatDistanceKm(run.session.distanceM)}',
                ),
                Text(
                  'Avg HR: ${run.session.avgHr ?? 'unknown'} | '
                  'Max HR: ${run.session.maxHr ?? 'unknown'}',
                ),
                if (run.segments.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Segments',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  ...run.segments.map(
                    (segment) => Text(
                      '${segmentLabels[segment.idx] ?? 'Segment'} ${segment.idx}: '
                      '${_formatDuration(segment.durationS)} | '
                      '${_formatDistanceKm(segment.distanceM)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStrength(BuildContext context) {
    if (safeDetail.groups.isEmpty) {
      return const GlassCard(
        child: Text('No prescribed/actual sets for this day.'),
      );
    }

    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final stackCounts = textScale > 1.2;

    if (stackCounts) {
      return Column(
        children: safeDetail.groups.map((group) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.exercise,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${group.prescribed.length + group.actual.length} total sets tracked',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StrengthCountPill(
                        label: 'Prescribed',
                        value: group.prescribed.length,
                      ),
                      _StrengthCountPill(
                        label: 'Actual',
                        value: group.actual.length,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Exercise',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  'Prescribed',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  'Actual',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ),
        ...safeDetail.groups.map((group) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.exercise,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${group.prescribed.length + group.actual.length} total sets tracked',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    child: Text(
                      '${group.prescribed.length}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text(
                      '${group.actual.length}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.fitness_center, size: 20),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _LabeledLine extends StatelessWidget {
  const _LabeledLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _StrengthCountPill extends StatelessWidget {
  const _StrengthCountPill({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

class _AlertIconStrip extends StatelessWidget {
  const _AlertIconStrip({
    required this.progressionAllowed,
    required this.artifacts,
  });

  final bool progressionAllowed;
  final int artifacts;

  @override
  Widget build(BuildContext context) {
    final iconColor = progressionAllowed
        ? ClinicalPalette.accentSecondary
        : ClinicalPalette.warningMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.warning_amber_rounded, size: 18, color: iconColor),
        const SizedBox(width: 3),
        Icon(
          Icons.warning_amber_rounded,
          size: 18,
          color: artifacts > 0
              ? ClinicalPalette.warningMuted
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 3),
        Icon(
          Icons.error_outline,
          size: 18,
          color: artifacts > 0
              ? const Color(0xFFE7A17E)
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _RunSparklinePainter extends CustomPainter {
  const _RunSparklinePainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final lowerGrid = Path()
      ..moveTo(0, size.height * 0.75)
      ..lineTo(size.width, size.height * 0.75);
    final midGrid = Path()
      ..moveTo(0, size.height * 0.45)
      ..lineTo(size.width, size.height * 0.45);

    canvas.drawPath(lowerGrid, gridPaint);
    canvas.drawPath(midGrid, gridPaint);

    final path = Path();
    final n = values.length;
    for (var i = 0; i < n; i++) {
      final x = n == 1 ? size.width / 2 : size.width * (i / (n - 1));
      final y = size.height - (values[i].clamp(0.0, 1.0) * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final areaPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          ClinicalPalette.accent.withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final linePaint = Paint()
      ..color = const Color(0xFFF38E71)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2;

    canvas.drawPath(areaPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = const Color(0xFFF38E71);
    for (var i = 0; i < n; i++) {
      final x = n == 1 ? size.width / 2 : size.width * (i / (n - 1));
      final y = size.height - (values[i].clamp(0.0, 1.0) * size.height);
      canvas.drawCircle(Offset(x, y), 2.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RunSparklinePainter oldDelegate) {
    if (oldDelegate.values.length != values.length) {
      return true;
    }
    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) {
        return true;
      }
    }
    return false;
  }
}

class _DailyLoadError extends StatelessWidget {
  const _DailyLoadError({
    required this.message,
    required this.details,
    required this.onRetry,
    required this.onOpenRunInputs,
  });

  final String message;
  final String? details;
  final VoidCallback onRetry;
  final VoidCallback onOpenRunInputs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                details ?? 'No additional error detail available.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                  OutlinedButton(
                    onPressed: onOpenRunInputs,
                    child: const Text('Open Run Inputs'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SleepEditorDialog extends ConsumerStatefulWidget {
  const _SleepEditorDialog({
    required this.selectedDate,
    required this.existing,
  });

  final String selectedDate;
  final SleepNight? existing;

  @override
  ConsumerState<_SleepEditorDialog> createState() => _SleepEditorDialogState();
}

class _SleepEditorDialogState extends ConsumerState<_SleepEditorDialog> {
  late final TextEditingController _deepHoursController;
  late final TextEditingController _deepMinutesController;
  late final TextEditingController _lightHoursController;
  late final TextEditingController _lightMinutesController;
  late final TextEditingController _remHoursController;
  late final TextEditingController _remMinutesController;
  late final TextEditingController _awakeHoursController;
  late final TextEditingController _awakeMinutesController;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _deepHoursController = TextEditingController(
        text: _hoursFromMinutes(widget.existing?.deepMin));
    _deepMinutesController = TextEditingController(
        text: _minutesFromMinutes(widget.existing?.deepMin));
    _lightHoursController = TextEditingController(
        text: _hoursFromMinutes(widget.existing?.lightMin));
    _lightMinutesController = TextEditingController(
        text: _minutesFromMinutes(widget.existing?.lightMin));
    _remHoursController =
        TextEditingController(text: _hoursFromMinutes(widget.existing?.remMin));
    _remMinutesController = TextEditingController(
        text: _minutesFromMinutes(widget.existing?.remMin));
    _awakeHoursController = TextEditingController(
        text: _hoursFromMinutes(widget.existing?.awakeMin));
    _awakeMinutesController = TextEditingController(
        text: _minutesFromMinutes(widget.existing?.awakeMin));
  }

  @override
  void dispose() {
    _deepHoursController.dispose();
    _deepMinutesController.dispose();
    _lightHoursController.dispose();
    _lightMinutesController.dispose();
    _remHoursController.dispose();
    _remMinutesController.dispose();
    _awakeHoursController.dispose();
    _awakeMinutesController.dispose();
    super.dispose();
  }

  String _hoursFromMinutes(int? totalMinutes) {
    if (totalMinutes == null || totalMinutes < 0) {
      return '0';
    }
    return (totalMinutes ~/ 60).toString();
  }

  String _minutesFromMinutes(int? totalMinutes) {
    if (totalMinutes == null || totalMinutes < 0) {
      return '0';
    }
    return (totalMinutes % 60).toString();
  }

  int? _readInt(TextEditingController controller) {
    final value = controller.text.trim();
    if (value.isEmpty) {
      return null;
    }
    return int.tryParse(value);
  }

  int? _categoryMinutes({
    required TextEditingController hoursController,
    required TextEditingController minutesController,
  }) {
    final hours = _readInt(hoursController);
    final minutes = _readInt(minutesController);
    if (hours == null || minutes == null) {
      return null;
    }
    if (hours < 0 || minutes < 0 || minutes > 59) {
      return null;
    }
    return (hours * 60) + minutes;
  }

  int? get _totalSleepMin {
    final deep = _categoryMinutes(
      hoursController: _deepHoursController,
      minutesController: _deepMinutesController,
    );
    final light = _categoryMinutes(
      hoursController: _lightHoursController,
      minutesController: _lightMinutesController,
    );
    final rem = _categoryMinutes(
      hoursController: _remHoursController,
      minutesController: _remMinutesController,
    );
    final awake = _categoryMinutes(
      hoursController: _awakeHoursController,
      minutesController: _awakeMinutesController,
    );
    if (deep == null || light == null || rem == null || awake == null) {
      return null;
    }
    return deep + light + rem + awake;
  }

  Future<void> _save() async {
    final deep = _categoryMinutes(
      hoursController: _deepHoursController,
      minutesController: _deepMinutesController,
    );
    final light = _categoryMinutes(
      hoursController: _lightHoursController,
      minutesController: _lightMinutesController,
    );
    final rem = _categoryMinutes(
      hoursController: _remHoursController,
      minutesController: _remMinutesController,
    );
    final awake = _categoryMinutes(
      hoursController: _awakeHoursController,
      minutesController: _awakeMinutesController,
    );
    final total = _totalSleepMin;

    if (deep == null || light == null || rem == null || awake == null) {
      setState(() => _error = 'Enter valid hours and minutes (minutes: 0-59).');
      return;
    }
    if (total == null) {
      setState(() => _error = 'Total sleep could not be calculated.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(appDbProvider).upsertSleepNight(
            date: widget.selectedDate,
            totalSleepMin: total,
            source: 'manual',
            startTime: widget.existing?.startTime,
            endTime: widget.existing?.endTime,
            remMin: rem,
            deepMin: deep,
            lightMin: light,
            awakeMin: awake,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _error = 'Failed to save sleep data: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalSleepMin;
    return AlertDialog(
      title: Text('Sleep Data ${widget.selectedDate}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _durationRow(
              label: 'Deep',
              hoursController: _deepHoursController,
              minutesController: _deepMinutesController,
            ),
            _durationRow(
              label: 'Light',
              hoursController: _lightHoursController,
              minutesController: _lightMinutesController,
            ),
            _durationRow(
              label: 'REM',
              hoursController: _remHoursController,
              minutesController: _remMinutesController,
            ),
            _durationRow(
              label: 'Awake',
              hoursController: _awakeHoursController,
              minutesController: _awakeMinutesController,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total Sleep (auto)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  total == null
                      ? 'invalid'
                      : _formatMinutesAsHoursMinutes(total),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Save Sleep'),
        ),
      ],
    );
  }

  Widget _durationRow({
    required String label,
    required TextEditingController hoursController,
    required TextEditingController minutesController,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label)),
          Expanded(
            child: TextField(
              controller: hoursController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: false, signed: false),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                labelText: 'Hours',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: minutesController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: false, signed: false),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                labelText: 'Minutes',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
