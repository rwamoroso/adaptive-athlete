import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_providers.dart';
import '../../db/app_db.dart';
import '../training/garmin_csv_import_service.dart';
import '../ui/clinical_widgets.dart';
import '../training/run_inputs_screen.dart';
import '../training/strength_history_import_service.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  Map<String, String> _paths = const <String, String>{};
  GarminImportResult? _importResult;
  StrengthImportResult? _strengthImportResult;
  StandardWorkbookImportResult? _standardImportResult;
  String? _weeklyWorkbookPath;
  String? _exportDirectoryPath;
  GarminActivityFilter _activityFilter = GarminActivityFilter.runningOnly;
  bool _exporting = false;
  bool _importing = false;
  bool _strengthImporting = false;
  bool _standardImporting = false;
  bool _weeklyExporting = false;
  String? _selectedCsvPath;
  String? _selectedStrengthPath;
  String? _selectedStandardWorkbookPath;
  DateTime _standardSplitStartDate = DateTime.now();

  Future<void> _pickExportDirectory() async {
    try {
      final path = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select export folder',
      );
      if (!mounted) {
        return;
      }
      if (path != null && path.isNotEmpty) {
        setState(() => _exportDirectoryPath = path);
      }
    } catch (e) {
      _showMessage('Folder picker unavailable: $e');
    }
  }

  Future<String?> _ensureExportDirectory() async {
    if (_exportDirectoryPath != null && _exportDirectoryPath!.isNotEmpty) {
      return _exportDirectoryPath;
    }
    await _pickExportDirectory();
    return _exportDirectoryPath;
  }

  Future<void> _export() async {
    final dir = await _ensureExportDirectory();
    if (dir == null) {
      _showMessage('Export cancelled. No folder selected.');
      return;
    }
    setState(() => _exporting = true);
    final db = ref.read(appDbProvider);
    final paths = await db.exportCsvs(outputDirectoryPath: dir);
    if (mounted) {
      setState(() {
        _paths = paths;
        _exporting = false;
      });
    }
  }

  Future<void> _exportStandardWorkbook() async {
    final dir = await _ensureExportDirectory();
    if (dir == null) {
      _showMessage('Export cancelled. No folder selected.');
      return;
    }
    setState(() => _weeklyExporting = true);
    try {
      final db = ref.read(appDbProvider);
      final path =
          await db.exportStandardWorkbookXlsx(outputDirectoryPath: dir);
      if (!mounted) {
        return;
      }
      setState(() => _weeklyWorkbookPath = path);
      _showMessage('Standard workbook exported.');
    } catch (e) {
      _showMessage('Standard workbook export failed: $e');
    } finally {
      if (mounted) {
        setState(() => _weeklyExporting = false);
      }
    }
  }

  Future<void> _pickCsvFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: false,
    );
    final path = result?.files.single.path;
    if (path != null) {
      setState(() => _selectedCsvPath = path);
    }
  }

  Future<void> _pickStrengthFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: false,
    );
    final path = result?.files.single.path;
    if (path != null) {
      setState(() => _selectedStrengthPath = path);
    }
  }

  Future<void> _pickStandardWorkbookFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: false,
    );
    final path = result?.files.single.path;
    if (path != null) {
      setState(() => _selectedStandardWorkbookPath = path);
    }
  }

  Future<void> _pickStandardSplitStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _standardSplitStartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() => _standardSplitStartDate = selected);
    }
  }

  Future<void> _importGarminCsv() async {
    if (_selectedCsvPath == null) {
      _showMessage('Pick a Garmin CSV file first.');
      return;
    }
    setState(() => _importing = true);
    try {
      final result = await ref.read(appDbProvider).importGarminCsv(
            filePath: _selectedCsvPath!,
            options: GarminImportOptions(activityFilter: _activityFilter),
          );
      if (!mounted) {
        return;
      }
      setState(() => _importResult = result);
      _showMessage(
        'Import complete: inserted=${result.insertedCount}, '
        'updated=${result.updatedCount}, overridden=${result.overriddenCount}, skipped=${result.skippedCount}',
      );
    } catch (e) {
      _showMessage('Import failed: $e');
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  Future<void> _importStrengthHistory() async {
    if (_selectedStrengthPath == null) {
      _showMessage('Pick a strength XLSX file first.');
      return;
    }
    setState(() => _strengthImporting = true);
    try {
      final result = await ref.read(appDbProvider).importStrengthHistoryXlsx(
            filePath: _selectedStrengthPath!,
          );
      if (!mounted) {
        return;
      }
      setState(() => _strengthImportResult = result);
      _showMessage(
        'Strength import complete: inserted=${result.insertedCount}, skipped=${result.skippedCount}',
      );
    } catch (e) {
      _showMessage('Strength import failed: $e');
    } finally {
      if (mounted) {
        setState(() => _strengthImporting = false);
      }
    }
  }

  Future<void> _importStandardWorkbook() async {
    if (_selectedStandardWorkbookPath == null) {
      _showMessage('Pick a standard workbook XLSX first.');
      return;
    }
    setState(() => _standardImporting = true);
    try {
      final result = await ref.read(appDbProvider).importStandardWorkbookXlsx(
            filePath: _selectedStandardWorkbookPath!,
            splitStartDate: _standardSplitStartDate,
          );
      if (!mounted) {
        return;
      }
      setState(() => _standardImportResult = result);
      _showMessage(
        'Standard import complete: '
        'days=${result.insertedPlanDays}, '
        'strength=${result.insertedStrengthSets}, '
        'runs=${result.insertedRunPlans}',
      );
    } catch (e) {
      _showMessage('Standard workbook import failed: $e');
    } finally {
      if (mounted) {
        setState(() => _standardImporting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(text: 'Import / Export'),
        const SizedBox(height: 8),
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import Garmin CSV',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const RunInputsScreen()),
                    );
                  },
                  child: const Text('Open Manual Run Inputs'),
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
        const SizedBox(height: 16),
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import Standard Workbook (XLSX)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedStandardWorkbookPath ?? 'No XLSX selected',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _pickStandardWorkbookFile,
                      child: const Text('Pick XLSX'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'First Day of Split: '
                        '${_standardSplitStartDate.year.toString().padLeft(4, '0')}-'
                        '${_standardSplitStartDate.month.toString().padLeft(2, '0')}-'
                        '${_standardSplitStartDate.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _pickStandardSplitStartDate,
                      child: const Text('Change Date'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed:
                      _standardImporting ? null : _importStandardWorkbook,
                  child: const Text('Import Standard Workbook'),
                ),
                if (_standardImportResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_standardImportResult!.pretty()),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import Strength History (XLSX)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedStrengthPath ?? 'No XLSX selected',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _pickStrengthFile,
                      child: const Text('Pick XLSX'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: _strengthImporting ? null : _importStrengthHistory,
                  child: const Text('Import Strength XLSX'),
                ),
                if (_strengthImportResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_strengthImportResult!.pretty()),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Standard Split Workbook',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _exportDirectoryPath ?? 'No export folder selected',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _pickExportDirectory,
                      child: const Text('Choose Folder'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: _weeklyExporting ? null : _exportStandardWorkbook,
                  child: const Text('Export Standard Workbook'),
                ),
                if (_weeklyWorkbookPath != null) ...[
                  const SizedBox(height: 8),
                  SelectableText('Workbook: $_weeklyWorkbookPath'),
                ],
                const SizedBox(height: 16),
                Text(
                  'Export CSVs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _exporting ? null : _export,
                  child: const Text('Export CSVs'),
                ),
                const SizedBox(height: 12),
                if (_paths.isEmpty)
                  const Text('No exports yet.')
                else
                  ..._paths.entries
                      .map((e) => SelectableText('${e.key}: ${e.value}')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
