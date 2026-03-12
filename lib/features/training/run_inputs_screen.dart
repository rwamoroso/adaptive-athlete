import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_providers.dart';
import '../../core/utils/date_utils.dart';
import '../../db/app_db.dart';
import '../ui/clinical_theme.dart';
import '../ui/clinical_widgets.dart';
import 'garmin_csv_import_service.dart';

enum DistanceUnit { miles, kilometers }

enum IntervalSegmentType { interval, rest }

Map<int, String> _manualRunSegmentLabelsByIdx(String? rawMetricsJson) {
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
      labels[idx] = kind == 'rest' ? 'Rest' : 'Interval';
    }
    return labels;
  } catch (_) {
    return const <int, String>{};
  }
}

class RunInputsScreen extends ConsumerStatefulWidget {
  const RunInputsScreen({super.key});

  @override
  ConsumerState<RunInputsScreen> createState() => _RunInputsScreenState();
}

class _RunInputsScreenState extends ConsumerState<RunInputsScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  DistanceUnit _distanceUnit = DistanceUnit.miles;
  GarminActivityFilter _activityFilter = GarminActivityFilter.cardioOnly;
  bool _intervalLoggingEnabled = false;
  bool _intervalModeTouched = false;
  String? _prescribedRunType;
  String? _prescribedLiftFocus;
  String? _prescribedDurationText;
  String? _prescribedTargetPace;
  String? _prescribedEffortHrGuardrails;
  String? _prescribedRunNotes;
  bool _loadingRunType = false;
  int _nextSegmentId = 1;
  final List<_ManualIntervalSegmentDraft> _intervalSegments =
      <_ManualIntervalSegmentDraft>[];

  final TextEditingController _durationController =
      TextEditingController(text: '00:30:00');
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _maxHrController = TextEditingController();
  final TextEditingController _avgHrController = TextEditingController();

  String? _selectedCsvPath;
  GarminImportResult? _importResult;
  bool _savingManual = false;
  bool _importing = false;
  List<RunSessionWithSegments> _loggedRunsForSelectedDate =
      const <RunSessionWithSegments>[];
  String? _editingRunSessionId;

  @override
  void initState() {
    super.initState();
    _refreshRunTypeForSelectedDate();
  }

  @override
  void dispose() {
    for (final segment in _intervalSegments) {
      segment.dispose();
    }
    _durationController.dispose();
    _distanceController.dispose();
    _maxHrController.dispose();
    _avgHrController.dispose();
    super.dispose();
  }

  bool _isIntervalRunType(String? raw) {
    final value = raw?.trim().toLowerCase() ?? '';
    return value.contains('interval') ||
        value.contains('repeat') ||
        value.contains('fartlek');
  }

  String _distanceUnitLabel() {
    return _distanceUnit == DistanceUnit.miles ? 'mi' : 'km';
  }

  String _formatSecondsAsHms(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  void _adjustDurationBySeconds({
    required TextEditingController controller,
    required int deltaSeconds,
  }) {
    final parsed = GarminCsvImportService.parseDurationSeconds(
      controller.text.trim(),
    );
    final currentSeconds = parsed?.round() ?? 0;
    final nextSeconds = currentSeconds + deltaSeconds;
    final clampedSeconds = nextSeconds < 0 ? 0 : nextSeconds;
    setState(() {
      controller.text = _formatSecondsAsHms(clampedSeconds);
    });
  }

  double? _parsePaceSecondsPerMile(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      if (parts.length != 2) {
        return null;
      }
      final minutes = int.tryParse(parts[0]);
      final seconds = int.tryParse(parts[1]);
      if (minutes == null || seconds == null || minutes < 0) {
        return null;
      }
      if (seconds < 0 || seconds > 59) {
        return null;
      }
      final total = (minutes * 60) + seconds;
      return total <= 0 ? null : total.toDouble();
    }

    final decimalMinutes = double.tryParse(trimmed);
    if (decimalMinutes == null || decimalMinutes <= 0) {
      return null;
    }
    return decimalMinutes * 60;
  }

  String _formatPaceTextMinPerMile(double paceSecondsPerMile) {
    final rounded = paceSecondsPerMile.round();
    final minutes = rounded ~/ 60;
    final seconds = rounded % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')} min/mi';
  }

  String _formatPaceInputMinPerMile(double paceSecondsPerMile) {
    final rounded = paceSecondsPerMile.round();
    final minutes = rounded ~/ 60;
    final seconds = rounded % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatPaceFromDurationAndDistance({
    required int? durationS,
    required double? distanceM,
  }) {
    if (durationS == null ||
        durationS <= 0 ||
        distanceM == null ||
        distanceM <= 0) {
      return 'unknown min/mi';
    }
    final miles = distanceM / GarminCsvImportService.metersPerMile;
    if (miles <= 0) {
      return 'unknown min/mi';
    }
    final secondsPerMile = durationS / miles;
    if (secondsPerMile <= 0 || !secondsPerMile.isFinite) {
      return 'unknown min/mi';
    }
    return _formatPaceTextMinPerMile(secondsPerMile);
  }

  Future<void> _refreshRunTypeForSelectedDate() async {
    final dateYmd = toYmd(_selectedDate);
    setState(() => _loadingRunType = true);
    try {
      final detail = await ref.read(appDbProvider).getWorkoutDayDetail(dateYmd);
      if (!mounted) {
        return;
      }
      final runType = detail.prescribedRun?.runType;
      final liftFocus = detail.prescribedRun?.liftFocus;
      final durationText = detail.prescribedRun?.durationText;
      final targetPace = detail.prescribedRun?.targetPace;
      final effortHrGuardrails = detail.prescribedRun?.effortHrGuardrails;
      final notes = detail.prescribedRun?.notes;
      setState(() {
        _prescribedRunType = runType;
        _prescribedLiftFocus = liftFocus;
        _prescribedDurationText = durationText;
        _prescribedTargetPace = targetPace;
        _prescribedEffortHrGuardrails = effortHrGuardrails;
        _prescribedRunNotes = notes;
        _loggedRunsForSelectedDate = detail.runSessions;
        _loadingRunType = false;
        if (!_intervalModeTouched && _isIntervalRunType(runType)) {
          _intervalLoggingEnabled = true;
          _seedDefaultIntervalRowsIfEmpty();
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingRunType = false;
        _prescribedRunType = null;
        _prescribedLiftFocus = null;
        _prescribedDurationText = null;
        _prescribedTargetPace = null;
        _prescribedEffortHrGuardrails = null;
        _prescribedRunNotes = null;
        _loggedRunsForSelectedDate = const <RunSessionWithSegments>[];
      });
    }
  }

  void _seedDefaultIntervalRowsIfEmpty() {
    if (_intervalSegments.isNotEmpty) {
      return;
    }
    _intervalSegments.add(
      _ManualIntervalSegmentDraft(
        id: _nextSegmentId++,
        type: IntervalSegmentType.interval,
        durationText: '00:01:00',
      ),
    );
    _intervalSegments.add(
      _ManualIntervalSegmentDraft(
        id: _nextSegmentId++,
        type: IntervalSegmentType.rest,
        durationText: '00:01:00',
      ),
    );
  }

  void _setIntervalLoggingEnabled(bool enabled) {
    setState(() {
      _intervalModeTouched = true;
      _intervalLoggingEnabled = enabled;
      if (enabled) {
        _seedDefaultIntervalRowsIfEmpty();
      }
    });
  }

  void _addIntervalSegment(IntervalSegmentType type) {
    setState(() {
      _intervalSegments.add(
        _ManualIntervalSegmentDraft(
          id: _nextSegmentId++,
          type: type,
          durationText: '00:01:00',
        ),
      );
    });
  }

  void _removeIntervalSegment(_ManualIntervalSegmentDraft segment) {
    if (_intervalSegments.length <= 1) {
      _showMessage('At least one segment is required in interval mode.');
      return;
    }
    setState(() {
      _intervalSegments.remove(segment);
      segment.dispose();
    });
  }

  _IntervalSegmentSaveData? _buildSegmentsForSave() {
    if (_intervalSegments.isEmpty) {
      _showMessage('Add at least one segment.');
      return null;
    }

    final built = <ManualRunSegmentInput>[];
    var totalDurationS = 0;
    var totalDistanceM = 0.0;
    var hasIntervalSegment = false;

    for (var i = 0; i < _intervalSegments.length; i++) {
      final segment = _intervalSegments[i];
      final durationSeconds = GarminCsvImportService.parseDurationSeconds(
        segment.durationController.text.trim(),
      );
      if (durationSeconds == null || durationSeconds <= 0) {
        _showMessage(
          'Segment ${i + 1} duration must be valid (HH:MM:SS).',
        );
        return null;
      }

      final paceText = segment.paceController.text.trim();
      double distanceM = 0.0;
      if (paceText.isNotEmpty) {
        final paceSecondsPerMile = _parsePaceSecondsPerMile(paceText);
        if (paceSecondsPerMile == null) {
          _showMessage(
              'Segment ${i + 1} pace must be MM:SS min/mi (or decimal minutes).');
          return null;
        }
        final miles = durationSeconds / paceSecondsPerMile;
        distanceM = miles * GarminCsvImportService.metersPerMile;
      }

      final segmentDuration = durationSeconds.round();
      final speedMps = distanceM <= 0 ? null : distanceM / segmentDuration;
      final kind =
          segment.type == IntervalSegmentType.rest ? 'rest' : 'interval';
      if (kind == 'interval') {
        hasIntervalSegment = true;
      }

      built.add(
        ManualRunSegmentInput(
          idx: i + 1,
          durationS: segmentDuration,
          distanceM: distanceM,
          kind: kind,
          speedMps: speedMps,
        ),
      );

      totalDurationS += segmentDuration;
      totalDistanceM += distanceM;
    }

    if (!hasIntervalSegment) {
      _showMessage('Add at least one interval segment.');
      return null;
    }

    return _IntervalSegmentSaveData(
      segments: built,
      totalDurationS: totalDurationS,
      totalDistanceM: totalDistanceM,
    );
  }

  _IntervalSegmentPreview _previewSegments() {
    var totalDurationS = 0;
    var totalDistanceM = 0.0;
    var hasInvalidInput = false;

    for (final segment in _intervalSegments) {
      final duration = GarminCsvImportService.parseDurationSeconds(
        segment.durationController.text.trim(),
      );
      if (duration == null || duration <= 0) {
        hasInvalidInput = true;
        continue;
      }

      final paceText = segment.paceController.text.trim();
      var distanceM = 0.0;
      if (paceText.isNotEmpty) {
        final paceSecondsPerMile = _parsePaceSecondsPerMile(paceText);
        if (paceSecondsPerMile == null) {
          hasInvalidInput = true;
          continue;
        }
        final miles = duration / paceSecondsPerMile;
        distanceM = miles * GarminCsvImportService.metersPerMile;
      }

      totalDurationS += duration.round();
      totalDistanceM += distanceM;
    }

    return _IntervalSegmentPreview(
      totalDurationS: totalDurationS,
      totalDistanceM: totalDistanceM,
      hasInvalidInput: hasInvalidInput,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _refreshRunTypeForSelectedDate();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickCsvFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: false,
    );

    final path = result?.files.single.path;
    if (path == null) {
      return;
    }

    setState(() {
      _selectedCsvPath = path;
    });
  }

  String _formatRunStartTime(int? startTimeMs) {
    if (startTimeMs == null) {
      return 'Unknown start';
    }
    final dt = DateTime.fromMillisecondsSinceEpoch(startTimeMs);
    final tod = TimeOfDay.fromDateTime(dt);
    return '${toYmd(dt)} • ${tod.format(context)}';
  }

  void _clearIntervalSegments() {
    for (final segment in _intervalSegments) {
      segment.dispose();
    }
    _intervalSegments.clear();
  }

  void _startNewManualEntry() {
    setState(() {
      _editingRunSessionId = null;
      _durationController.text = '00:30:00';
      _distanceController.clear();
      _maxHrController.clear();
      _avgHrController.clear();
      _intervalModeTouched = false;
      _intervalLoggingEnabled = _isIntervalRunType(_prescribedRunType);
      _clearIntervalSegments();
      if (_intervalLoggingEnabled) {
        _seedDefaultIntervalRowsIfEmpty();
      }
    });
  }

  void _loadRunIntoManualForm(RunSessionWithSegments run) {
    final session = run.session;
    final startTime = session.startTime;
    final startDt = startTime == null
        ? DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _selectedTime.hour,
            _selectedTime.minute,
          )
        : DateTime.fromMillisecondsSinceEpoch(startTime);

    final segmentKinds = _manualRunSegmentLabelsByIdx(session.rawMetricsJson);
    final hasSegments = run.segments.isNotEmpty;
    final nextSegments = <_ManualIntervalSegmentDraft>[];
    var nextSegmentId = 1;
    if (hasSegments) {
      for (final seg in run.segments) {
        final label = (segmentKinds[seg.idx] ?? 'Interval').toLowerCase();
        final type = label == 'rest'
            ? IntervalSegmentType.rest
            : IntervalSegmentType.interval;
        final durationS = seg.durationS ?? 0;
        final safeDurationS = durationS < 0 ? 0 : durationS;
        final draft = _ManualIntervalSegmentDraft(
          id: nextSegmentId++,
          type: type,
          durationText: _formatSecondsAsHms(safeDurationS),
        );
        final distanceM = seg.distanceM ?? 0.0;
        if (distanceM > 0 && safeDurationS > 0) {
          final miles = distanceM / GarminCsvImportService.metersPerMile;
          if (miles > 0) {
            final secondsPerMile = safeDurationS / miles;
            draft.paceController.text =
                _formatPaceInputMinPerMile(secondsPerMile);
          }
        }
        nextSegments.add(draft);
      }
    }

    setState(() {
      _editingRunSessionId = session.id;
      _selectedDate = DateTime(startDt.year, startDt.month, startDt.day);
      _selectedTime = TimeOfDay.fromDateTime(startDt);
      _durationController.text = session.durationS == null
          ? '00:30:00'
          : _formatSecondsAsHms(session.durationS!);
      if ((session.distanceM ?? 0) > 0) {
        final converted = _distanceUnit == DistanceUnit.miles
            ? session.distanceM! / GarminCsvImportService.metersPerMile
            : session.distanceM! / 1000;
        _distanceController.text = converted.toStringAsFixed(2);
      } else {
        _distanceController.clear();
      }
      _avgHrController.text = session.avgHr?.toStringAsFixed(0) ?? '';
      _maxHrController.text = session.maxHr?.toStringAsFixed(0) ?? '';
      _intervalModeTouched = true;
      _intervalLoggingEnabled = hasSegments;
      _clearIntervalSegments();
      _intervalSegments.addAll(nextSegments);
      _nextSegmentId = nextSegmentId;
    });

    _refreshRunTypeForSelectedDate();
    _showMessage('Loaded run into form for editing.');
  }

  Future<void> _saveManualRun() async {
    var durationSeconds = 0;
    var distanceM = 0.0;
    var manualSegments = const <ManualRunSegmentInput>[];

    if (_intervalLoggingEnabled) {
      final segmentData = _buildSegmentsForSave();
      if (segmentData == null) {
        return;
      }
      durationSeconds = segmentData.totalDurationS;
      distanceM = segmentData.totalDistanceM;
      manualSegments = segmentData.segments;
    } else {
      final parsedDuration = GarminCsvImportService.parseDurationSeconds(
        _durationController.text.trim(),
      );
      final distanceRaw = double.tryParse(_distanceController.text.trim());

      if (parsedDuration == null || parsedDuration <= 0) {
        _showMessage('Duration must be valid (e.g. 00:45:30).');
        return;
      }
      if (distanceRaw == null || distanceRaw <= 0) {
        _showMessage('Distance must be a positive number.');
        return;
      }

      durationSeconds = parsedDuration.round();
      distanceM = _distanceUnit == DistanceUnit.miles
          ? distanceRaw * GarminCsvImportService.metersPerMile
          : distanceRaw * 1000;
    }

    final maxHr = _maxHrController.text.trim().isEmpty
        ? null
        : double.tryParse(_maxHrController.text.trim());
    final avgHr = _avgHrController.text.trim().isEmpty
        ? null
        : double.tryParse(_avgHrController.text.trim());

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    setState(() => _savingManual = true);
    try {
      final db = ref.read(appDbProvider);
      final editingRunSessionId = _editingRunSessionId;
      final outcome = editingRunSessionId == null
          ? await db.insertOrUpdateManualRun(
              dateString: toYmd(_selectedDate),
              startTimeMs: startDateTime.millisecondsSinceEpoch,
              durationS: durationSeconds,
              distanceM: distanceM,
              avgHr: avgHr,
              maxHr: maxHr,
              manualSegments: manualSegments,
            )
          : await db.updateExistingRunFromManualEntry(
              runSessionId: editingRunSessionId,
              dateString: toYmd(_selectedDate),
              startTimeMs: startDateTime.millisecondsSinceEpoch,
              durationS: durationSeconds,
              distanceM: distanceM,
              avgHr: avgHr,
              maxHr: maxHr,
              manualSegments: manualSegments,
            );

      if (!mounted) {
        return;
      }

      if (outcome.preservedGarmin) {
        _showMessage(
            'Garmin data already exists for that run start time. Manual entry was not applied.');
      } else {
        final wasEditing = editingRunSessionId != null;
        if (wasEditing) {
          _editingRunSessionId = null;
        }
        await _refreshRunTypeForSelectedDate();
        _showMessage(
          _intervalLoggingEnabled
              ? (wasEditing
                  ? 'Run updated from manual interval entry.'
                  : 'Manual interval run saved.')
              : (wasEditing ? 'Run updated.' : 'Manual run saved.'),
        );
      }
    } catch (e) {
      _showMessage('Manual save failed: $e');
    } finally {
      if (mounted) {
        setState(() => _savingManual = false);
      }
    }
  }

  Future<void> _importGarminCsv() async {
    final path = _selectedCsvPath;
    if (path == null) {
      _showMessage('Pick a Garmin CSV file first.');
      return;
    }

    setState(() => _importing = true);
    try {
      final result = await ref.read(appDbProvider).importGarminCsv(
            filePath: path,
            options: GarminImportOptions(activityFilter: _activityFilter),
          );

      if (!mounted) {
        return;
      }

      setState(() => _importResult = result);
      await _refreshRunTypeForSelectedDate();
      _showMessage(
        'Import done. inserted=${result.insertedCount}, updated=${result.updatedCount}, overridden=${result.overriddenCount}, skipped=${result.skippedCount}',
      );
    } catch (e) {
      _showMessage('Import failed: $e');
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final pageTheme = buildClinicalTheme();
    final runHeaderTitle = ((_prescribedRunType ?? '').trim().isEmpty)
        ? 'Run Inputs'
        : (_prescribedRunType ?? '').trim();
    final splitContextTitle = ((_prescribedLiftFocus ?? '').trim().isEmpty)
        ? null
        : (_prescribedLiftFocus ?? '').trim();
    final preview = _intervalLoggingEnabled
        ? _previewSegments()
        : const _IntervalSegmentPreview(
            totalDurationS: 0,
            totalDistanceM: 0,
            hasInvalidInput: false,
          );
    RunSessionWithSegments? editingRun;
    final editingRunId = _editingRunSessionId;
    if (editingRunId != null) {
      for (final run in _loggedRunsForSelectedDate) {
        if (run.session.id == editingRunId) {
          editingRun = run;
          break;
        }
      }
    }

    return Theme(
      data: pageTheme,
      child: Scaffold(
        appBar: AppBar(title: Text(runHeaderTitle)),
        body: Stack(
          children: [
            const Positioned.fill(child: _RunInputsPageBackground()),
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                Text(
                  splitContextTitle == null
                      ? 'RUN DATA CAPTURE'
                      : '${splitContextTitle.toUpperCase()} • RUN DATA CAPTURE',
                  style: pageTheme.textTheme.headlineSmall?.copyWith(
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const ClinicalBanner(
                  text:
                      'Log manual runs or import Garmin CSV. Interval mode supports work/rest segment tracking.',
                ),
                const SizedBox(height: 10),
                GlassCard(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Run Prescription',
                        style: pageTheme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_loadingRunType)
                        Text(
                          'Loading run prescription...',
                          style: pageTheme.textTheme.bodySmall,
                        )
                      else if ((_prescribedRunType ?? '').trim().isEmpty)
                        Text(
                          'No prescribed run for ${toYmd(_selectedDate)}.',
                          style: pageTheme.textTheme.bodySmall,
                        )
                      else ...[
                        Text(
                          _prescribedRunType!.trim(),
                          style: pageTheme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Duration: ${(_prescribedDurationText ?? '').trim().isEmpty ? 'unknown' : _prescribedDurationText!.trim()}'
                          ' | Pace: ${(_prescribedTargetPace ?? '').trim().isEmpty ? 'unknown' : _prescribedTargetPace!.trim()}',
                          style: pageTheme.textTheme.bodySmall?.copyWith(
                            fontSize: 11.5,
                            height: 1.15,
                          ),
                        ),
                        if ((_prescribedEffortHrGuardrails ?? '')
                            .trim()
                            .isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Guardrails: ${_prescribedEffortHrGuardrails!.trim()}',
                              style: pageTheme.textTheme.bodySmall?.copyWith(
                                fontSize: 11.5,
                                height: 1.15,
                              ),
                            ),
                          ),
                        if ((_prescribedRunNotes ?? '').trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Notes: ${_prescribedRunNotes!.trim()}',
                              style: pageTheme.textTheme.bodySmall?.copyWith(
                                fontSize: 11.5,
                                height: 1.15,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SectionHeader(
                  text: 'Logged Runs (${toYmd(_selectedDate)})',
                  trailing: _loggedRunsForSelectedDate.isEmpty
                      ? null
                      : Text(
                          '${_loggedRunsForSelectedDate.length}',
                          style: pageTheme.textTheme.labelLarge,
                        ),
                ),
                const SizedBox(height: 8),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_loadingRunType)
                        const Text('Loading runs...')
                      else if (_loggedRunsForSelectedDate.isEmpty)
                        const Text('No logged runs for this date yet.')
                      else
                        ..._loggedRunsForSelectedDate.map((run) {
                          final session = run.session;
                          final isEditing = session.id == _editingRunSessionId;
                          final durationText = session.durationS == null
                              ? 'unknown'
                              : _formatSecondsAsHms(session.durationS!);
                          final subtitleParts = <String>[
                            _formatRunStartTime(session.startTime),
                            '${session.source} • $durationText',
                            _formatPaceFromDurationAndDistance(
                              durationS: session.durationS,
                              distanceM: session.distanceM,
                            ),
                            if (run.segments.isNotEmpty)
                              '${run.segments.length} segment${run.segments.length == 1 ? '' : 's'}',
                          ];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isEditing
                                    ? pageTheme.colorScheme.primary
                                        .withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        (session.title?.trim().isNotEmpty ??
                                                false)
                                            ? session.title!.trim()
                                            : ((session.activityType
                                                        ?.trim()
                                                        .isNotEmpty ??
                                                    false)
                                                ? session.activityType!.trim()
                                                : 'Run'),
                                        style: pageTheme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (isEditing)
                                      const Chip(label: Text('Editing')),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(subtitleParts.join(' | ')),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    FilledButton.tonal(
                                      onPressed: () =>
                                          _loadRunIntoManualForm(run),
                                      child: const Text('Load for Edit'),
                                    ),
                                    if (isEditing)
                                      OutlinedButton(
                                        onPressed: _startNewManualEntry,
                                        child: const Text('Stop Editing'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SectionHeader(text: 'Manual Entry'),
                const SizedBox(height: 8),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Manual Run Entry',
                          style: Theme.of(context).textTheme.titleMedium),
                      if (editingRun != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: pageTheme.colorScheme.tertiaryContainer
                                .withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: pageTheme.colorScheme.outline,
                            ),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Editing existing run: ${_formatRunStartTime(editingRun.session.startTime)}',
                              ),
                              OutlinedButton(
                                onPressed: _startNewManualEntry,
                                child: const Text('New Run Instead'),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: Text('Date: ${toYmd(_selectedDate)}')),
                          OutlinedButton(
                              onPressed: _pickDate,
                              child: const Text('Pick Date')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                              child: Text(
                                  'Start: ${_selectedTime.format(context)}')),
                          OutlinedButton(
                              onPressed: _pickTime,
                              child: const Text('Pick Time')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_loadingRunType)
                        const Text('Checking prescribed run type...')
                      else if (_prescribedRunType != null)
                        Text('Prescribed run type: $_prescribedRunType'),
                      const SizedBox(height: 6),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Interval Run Logging'),
                        subtitle: Text(
                          _isIntervalRunType(_prescribedRunType)
                              ? 'Interval day detected. Log each work/rest segment.'
                              : 'Enable to log each interval and rest segment.',
                        ),
                        value: _intervalLoggingEnabled,
                        onChanged: _setIntervalLoggingEnabled,
                      ),
                      if (!_intervalLoggingEnabled) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Distance unit:'),
                            const SizedBox(width: 8),
                            DropdownButton<DistanceUnit>(
                              value: _distanceUnit,
                              items: const [
                                DropdownMenuItem(
                                    value: DistanceUnit.miles,
                                    child: Text('mi')),
                                DropdownMenuItem(
                                    value: DistanceUnit.kilometers,
                                    child: Text('km')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _distanceUnit = value);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_intervalLoggingEnabled) ...[
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _addIntervalSegment(
                                  IntervalSegmentType.interval),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Interval'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _addIntervalSegment(IntervalSegmentType.rest),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Rest'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._intervalSegments.asMap().entries.map((entry) {
                          final index = entry.key;
                          final segment = entry.value;
                          return Padding(
                            key: ValueKey('interval-segment-${segment.id}'),
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Segment ${index + 1}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const Spacer(),
                                      DropdownButton<IntervalSegmentType>(
                                        value: segment.type,
                                        items: const [
                                          DropdownMenuItem(
                                            value: IntervalSegmentType.interval,
                                            child: Text('Interval'),
                                          ),
                                          DropdownMenuItem(
                                            value: IntervalSegmentType.rest,
                                            child: Text('Rest'),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value == null) {
                                            return;
                                          }
                                          setState(() => segment.type = value);
                                        },
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            _removeIntervalSegment(segment),
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        tooltip: 'Decrease by 30 seconds',
                                        onPressed: () =>
                                            _adjustDurationBySeconds(
                                          controller:
                                              segment.durationController,
                                          deltaSeconds: -30,
                                        ),
                                        icon: const Icon(Icons.remove_circle),
                                      ),
                                      Expanded(
                                        child: TextField(
                                          controller:
                                              segment.durationController,
                                          onChanged: (_) => setState(() {}),
                                          decoration: const InputDecoration(
                                            labelText: 'Duration',
                                            hintText: 'HH:MM:SS',
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Increase by 30 seconds',
                                        onPressed: () =>
                                            _adjustDurationBySeconds(
                                          controller:
                                              segment.durationController,
                                          deltaSeconds: 30,
                                        ),
                                        icon: const Icon(Icons.add_circle),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: segment.paceController,
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      labelText: 'Pace (min/mi) optional',
                                      hintText: 'e.g. 8:30',
                                    ),
                                    keyboardType: TextInputType.text,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        Text(
                          'Calculated total: ${_formatSecondsAsHms(preview.totalDurationS)} | '
                          '${_formatPaceFromDurationAndDistance(durationS: preview.totalDurationS, distanceM: preview.totalDistanceM)}'
                          '${preview.hasInvalidInput ? ' (check invalid segment values)' : ''}',
                        ),
                      ] else ...[
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Decrease by 30 seconds',
                              onPressed: () => _adjustDurationBySeconds(
                                controller: _durationController,
                                deltaSeconds: -30,
                              ),
                              icon: const Icon(Icons.remove_circle),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _durationController,
                                decoration: const InputDecoration(
                                  labelText: 'Duration',
                                  hintText: 'HH:MM:SS',
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Increase by 30 seconds',
                              onPressed: () => _adjustDurationBySeconds(
                                controller: _durationController,
                                deltaSeconds: 30,
                              ),
                              icon: const Icon(Icons.add_circle),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _distanceController,
                          decoration: InputDecoration(
                            labelText: 'Distance (${_distanceUnitLabel()})',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ],
                      const SizedBox(height: 8),
                      TextField(
                        controller: _maxHrController,
                        decoration: const InputDecoration(
                            labelText: 'Max HR (optional)'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _avgHrController,
                        decoration: const InputDecoration(
                            labelText: 'Avg HR (optional)'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _savingManual ? null : _saveManualRun,
                        child: Text(
                          _editingRunSessionId == null
                              ? 'Save Manual Run'
                              : 'Update Run',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SectionHeader(text: 'Garmin Import'),
                const SizedBox(height: 8),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Garmin CSV Import',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedCsvPath ?? 'No CSV selected',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _pickCsvFile,
                            child: const Text('Pick CSV'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<GarminActivityFilter>(
                        segments: const [
                          ButtonSegment(
                            value: GarminActivityFilter.cardioOnly,
                            label: Text('Cardio Only'),
                          ),
                          ButtonSegment(
                            value: GarminActivityFilter.runningOnly,
                            label: Text('Running Only'),
                          ),
                        ],
                        selected: {_activityFilter},
                        onSelectionChanged: (selection) {
                          setState(() => _activityFilter = selection.first);
                        },
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: _importing ? null : _importGarminCsv,
                        child: const Text('Import Garmin CSV'),
                      ),
                      if (_importResult != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_importResult!.pretty()),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RunInputsPageBackground extends StatelessWidget {
  const _RunInputsPageBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ClinicalPalette.bgTop,
            ClinicalPalette.bgMid,
            ClinicalPalette.bgBottom,
          ],
        ),
        backgroundBlendMode: BlendMode.srcOver,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.15, -0.95),
            radius: 1.3,
            colors: [
              Colors.white.withValues(alpha: 0.05),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.22),
            ],
            stops: const [0, 0.55, 1],
          ),
        ),
      ),
    );
  }
}

class _ManualIntervalSegmentDraft {
  _ManualIntervalSegmentDraft({
    required this.id,
    required this.type,
    required String durationText,
  }) : durationController = TextEditingController(text: durationText);

  final int id;
  IntervalSegmentType type;
  final TextEditingController durationController;
  final TextEditingController paceController = TextEditingController();

  void dispose() {
    durationController.dispose();
    paceController.dispose();
  }
}

class _IntervalSegmentSaveData {
  const _IntervalSegmentSaveData({
    required this.segments,
    required this.totalDurationS,
    required this.totalDistanceM,
  });

  final List<ManualRunSegmentInput> segments;
  final int totalDurationS;
  final double totalDistanceM;
}

class _IntervalSegmentPreview {
  const _IntervalSegmentPreview({
    required this.totalDurationS,
    required this.totalDistanceM,
    required this.hasInvalidInput,
  });

  final int totalDurationS;
  final double totalDistanceM;
  final bool hasInvalidInput;
}
