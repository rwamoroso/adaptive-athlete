import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/rules/recovery_gating.dart';
import '../../core/rules/treadmill_artifact_detector.dart';
import '../../core/utils/app_providers.dart';
import '../../core/utils/date_utils.dart';
import '../../db/app_db.dart';
import '../ai/ai_analyze_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(appDbProvider);

    return FutureBuilder<WorkoutDayDetail>(
      key: ValueKey('daily-$_selectedDate-$_refresh'),
      future: db.getWorkoutDayDetail(_selectedDate),
      builder: (context, snapshot) {
        final detail = snapshot.data;
        final loading = snapshot.connectionState == ConnectionState.waiting;

        if (loading && detail == null) {
          return const Center(child: CircularProgressIndicator());
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

        return RefreshIndicator(
          onRefresh: () async => setState(() => _refresh++),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: Text('Selected Date: $_selectedDate')),
                  OutlinedButton(
                      onPressed: _pickDate, child: const Text('Pick Date')),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryCard(
                    title: 'Sleep',
                    value: _formatMinutesAsHoursMinutes(sleepMin),
                    subtitle: 'Tap to view/edit',
                    onTap: () => _openSleepEditor(sleepNight),
                  ),
                  _SummaryCard(
                      title: 'Run',
                      value: '${safeDetail.runSessions.length} sessions'),
                  _SummaryCard(
                    title: 'Flags',
                    value:
                        '${gate.progressionAllowed ? 'ok' : gate.reasoning}; artifacts: $excluded',
                  ),
                  _SummaryCard(
                    title: 'Split',
                    value: safeDetail.planDayNumber == null
                        ? 'No split linked'
                        : 'Day ${safeDetail.planDayNumber} • ${_sessionTypeLabel(safeDetail.planSessionType)}',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RunInputsScreen()),
                      );
                    },
                    child: const Text('Run Inputs'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                WorkoutDayDetailScreen(date: _selectedDate)),
                      );
                    },
                    child: const Text('Open Workout Day Detail'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: safeDetail.planDayNumber == null
                    ? null
                    : () => _markRestDayAndPush(safeDetail),
                child: const Text('Mark Rest Day + Push Split'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _runMockAi(safeDetail, excluded, gate),
                child: const Text('Run Mock AI Analysis'),
              ),
              const SizedBox(height: 16),
              Text('Prescribed Run',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    safeDetail.prescribedRun?.runType == null
                        ? 'No prescribed run linked to this day.'
                        : 'Type: ${safeDetail.prescribedRun?.runType}\n'
                            'Duration: ${safeDetail.prescribedRun?.durationText ?? 'unknown'}\n'
                            'Pace: ${safeDetail.prescribedRun?.targetPace ?? 'unknown'}\n'
                            'Guardrails: ${safeDetail.prescribedRun?.effortHrGuardrails ?? 'unknown'}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Runs', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (safeDetail.runSessions.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No runs logged for this date.'),
                  ),
                )
              else
                ...safeDetail.runSessions.map(
                  (run) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
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
                          Text(run.session.title ?? 'untitled run'),
                          Text(
                            'Duration: ${run.session.durationS ?? 'unknown'} s | Distance: ${run.session.distanceM?.toStringAsFixed(1) ?? 'unknown'} m',
                          ),
                          Text(
                            'Avg HR: ${run.session.avgHr ?? 'unknown'} | Max HR: ${run.session.maxHr ?? 'unknown'}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text('Strength', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (safeDetail.groups.isEmpty)
                const Card(
                    child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('No prescribed/actual sets for this day.')))
              else
                ...safeDetail.groups.map((group) {
                  return Card(
                    child: ListTile(
                      title: Text(group.exercise),
                      subtitle: Text(
                          'Prescribed: ${group.prescribed.length} | Actual: ${group.actual.length}'),
                    ),
                  );
                }),
              const SizedBox(height: 16),
              Text('Latest AI Output (summary first):',
                  style: Theme.of(context).textTheme.titleMedium),
              if (safeDetail.aiAudits.isEmpty)
                const Text('No AI audits yet.')
              else
                Text(
                  const JsonEncoder.withIndent('  ').convert(
                    jsonDecode(safeDetail.aiAudits.first.responseJson)
                        as Map<String, dynamic>,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(value),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
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
