import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_providers.dart';
import '../../core/utils/date_utils.dart';
import 'garmin_csv_import_service.dart';

enum DistanceUnit { miles, kilometers }

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
  void dispose() {
    _durationController.dispose();
    _distanceController.dispose();
    _maxHrController.dispose();
    _avgHrController.dispose();
    super.dispose();
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
    final durationSeconds = GarminCsvImportService.parseDurationSeconds(
        _durationController.text.trim());
    final distanceRaw = double.tryParse(_distanceController.text.trim());

    if (durationSeconds == null || durationSeconds <= 0) {
      _showMessage('Duration must be valid (e.g. 00:45:30).');
      return;
    }
    if (distanceRaw == null || distanceRaw <= 0) {
      _showMessage('Distance must be a positive number.');
      return;
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

    final distanceM = _distanceUnit == DistanceUnit.miles
        ? distanceRaw * GarminCsvImportService.metersPerMile
        : distanceRaw * 1000;

    setState(() => _savingManual = true);
    try {
      final outcome = await ref.read(appDbProvider).insertOrUpdateManualRun(
            dateString: toYmd(_selectedDate),
            startTimeMs: startDateTime.millisecondsSinceEpoch,
            durationS: durationSeconds.round(),
            distanceM: distanceM,
            avgHr: avgHr,
            maxHr: maxHr,
          );

      if (!mounted) {
        return;
      }

      if (outcome.preservedGarmin) {
        _showMessage(
            'Garmin data already exists for that run start time. Manual entry was not applied.');
      } else {
        _showMessage('Manual run saved.');
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
                  TextField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration',
                      hintText: 'HH:MM:SS',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _distanceController,
                          decoration:
                              const InputDecoration(labelText: 'Distance'),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
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
