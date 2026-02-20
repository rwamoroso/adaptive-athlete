import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_providers.dart';
import '../../core/utils/date_utils.dart';
import '../../db/app_db.dart';
import 'garmin_csv_import_service.dart';

enum DistanceUnit { miles, kilometers }

enum IntervalSegmentType { interval, rest }

class RunInputsScreen extends ConsumerStatefulWidget {
  const RunInputsScreen({super.key});

  @override
  ConsumerState<RunInputsScreen> createState() => _RunInputsScreenState();
}

class _RunInputsScreenState extends ConsumerState<RunInputsScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  DistanceUnit _distanceUnit = DistanceUnit.miles;
  GarminActivityFilter _activityFilter = GarminActivityFilter.runningOnly;
  bool _intervalLoggingEnabled = false;
  bool _intervalModeTouched = false;
  String? _prescribedRunType;
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

  String _formatDistanceInSelectedUnit(double valueMeters) {
    final converted = _distanceUnit == DistanceUnit.miles
        ? valueMeters / GarminCsvImportService.metersPerMile
        : valueMeters / 1000;
    return '${converted.toStringAsFixed(2)} ${_distanceUnitLabel()}';
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
      setState(() {
        _prescribedRunType = runType;
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
      setState(() => _loadingRunType = false);
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

      final distanceText = segment.distanceController.text.trim();
      var distanceRaw = 0.0;
      if (distanceText.isNotEmpty) {
        final parsedDistance = double.tryParse(distanceText);
        if (parsedDistance == null || parsedDistance < 0) {
          _showMessage(
              'Segment ${i + 1} distance must be a non-negative number.');
          return null;
        }
        distanceRaw = parsedDistance;
      }

      final distanceM = _distanceUnit == DistanceUnit.miles
          ? distanceRaw * GarminCsvImportService.metersPerMile
          : distanceRaw * 1000;
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

      final distanceText = segment.distanceController.text.trim();
      var distanceRaw = 0.0;
      if (distanceText.isNotEmpty) {
        final parsed = double.tryParse(distanceText);
        if (parsed == null || parsed < 0) {
          hasInvalidInput = true;
          continue;
        }
        distanceRaw = parsed;
      }

      totalDurationS += duration.round();
      totalDistanceM += _distanceUnit == DistanceUnit.miles
          ? distanceRaw * GarminCsvImportService.metersPerMile
          : distanceRaw * 1000;
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
      final outcome = await ref.read(appDbProvider).insertOrUpdateManualRun(
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
        _showMessage(
          _intervalLoggingEnabled
              ? 'Manual interval run saved.'
              : 'Manual run saved.',
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
    final preview = _intervalLoggingEnabled
        ? _previewSegments()
        : const _IntervalSegmentPreview(
            totalDurationS: 0,
            totalDistanceM: 0,
            hasInvalidInput: false,
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Run Inputs')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manual Run Entry',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: Text('Date: ${toYmd(_selectedDate)}')),
                      OutlinedButton(
                          onPressed: _pickDate, child: const Text('Pick Date')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child:
                              Text('Start: ${_selectedTime.format(context)}')),
                      OutlinedButton(
                          onPressed: _pickTime, child: const Text('Pick Time')),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Distance unit:'),
                      const SizedBox(width: 8),
                      DropdownButton<DistanceUnit>(
                        value: _distanceUnit,
                        items: const [
                          DropdownMenuItem(
                              value: DistanceUnit.miles, child: Text('mi')),
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
                  if (_intervalLoggingEnabled) ...[
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              _addIntervalSegment(IntervalSegmentType.interval),
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
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(8),
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
                              TextField(
                                controller: segment.durationController,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Duration',
                                  hintText: 'HH:MM:SS',
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: segment.distanceController,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText:
                                      'Distance (${_distanceUnitLabel()}) optional',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    Text(
                      'Calculated total: ${_formatSecondsAsHms(preview.totalDurationS)} | '
                      '${_formatDistanceInSelectedUnit(preview.totalDistanceM)}'
                      '${preview.hasInvalidInput ? ' (check invalid segment values)' : ''}',
                    ),
                  ] else ...[
                    TextField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        hintText: 'HH:MM:SS',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _distanceController,
                      decoration: InputDecoration(
                        labelText: 'Distance (${_distanceUnitLabel()})',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: _maxHrController,
                    decoration:
                        const InputDecoration(labelText: 'Max HR (optional)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _avgHrController,
                    decoration:
                        const InputDecoration(labelText: 'Avg HR (optional)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _savingManual ? null : _saveManualRun,
                    child: const Text('Save Manual Run'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                        value: GarminActivityFilter.runningOnly,
                        label: Text('Running Only'),
                      ),
                      ButtonSegment(
                        value: GarminActivityFilter.allActivities,
                        label: Text('All Activities'),
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
                        border: Border.all(
                            color: Theme.of(context).colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_importResult!.pretty()),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
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
  final TextEditingController distanceController = TextEditingController();

  void dispose() {
    durationController.dispose();
    distanceController.dispose();
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
