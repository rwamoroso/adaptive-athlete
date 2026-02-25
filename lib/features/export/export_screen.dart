import 'package:file_picker/file_picker.dart';
import 'package:drift/drift.dart' show OrderingMode, OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/utils/app_providers.dart';
import '../../core/utils/date_utils.dart';
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
  String? _standardImportFailureMessage;
  String? _standardImportConflictReportPath;
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
      setState(() {
        _selectedStandardWorkbookPath = path;
        _standardImportFailureMessage = null;
        _standardImportConflictReportPath = null;
      });
    }
  }

  Future<PlanImportAuditData?> _getLatestFailedPlanImportAuditForFile(
    String filePath,
  ) async {
    final db = ref.read(appDbProvider);
    final fileName = p.basename(filePath);
    return (db.select(db.planImportAudit)
          ..where((t) => t.fileName.equals(fileName))
          ..where((t) => t.success.equals(false))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.importedAt, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
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

  Future<bool> _confirmPlanCycleOverrideIfNeeded({
    required DateTime splitStartDate,
    required String actionLabel,
  }) async {
    final normalizedStart = DateTime(
      splitStartDate.year,
      splitStartDate.month,
      splitStartDate.day,
    );
    final weekStart = toYmd(normalizedStart);
    final weekEnd = toYmd(normalizedStart.add(const Duration(days: 6)));
    final existing = await ref.read(appDbProvider).findOverlappingPlanCycles(
          rangeStartYmd: weekStart,
          rangeEndYmd: weekEnd,
        );
    if (existing.isEmpty) {
      return true;
    }
    if (!mounted) {
      return false;
    }

    final message = existing
        .map((c) => '${c.weekStart} to ${c.weekEnd} (${c.source})')
        .join('\n');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace Existing Plan Cycle?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A plan cycle already exists for the selected dates ($weekStart to $weekEnd).',
            ),
            const SizedBox(height: 8),
            const Text(
              'Continuing will delete the overlapping plan cycle(s) before importing the new one.',
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    return confirmed ?? false;
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
    final confirmed = await _confirmPlanCycleOverrideIfNeeded(
      splitStartDate: _standardSplitStartDate,
      actionLabel: 'Replace & Import',
    );
    if (!confirmed) {
      _showMessage('Standard workbook import cancelled.');
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
      setState(() {
        _standardImportResult = result;
        _standardImportFailureMessage = null;
        _standardImportConflictReportPath = null;
      });
      _showMessage(
        'Standard import complete: '
        'days=${result.insertedPlanDays}, '
        'strength=${result.insertedStrengthSets}, '
        'runs=${result.insertedRunPlans}, '
        'alternatives=${result.insertedAlternatives}',
      );
    } catch (e) {
      final audit = _selectedStandardWorkbookPath == null
          ? null
          : await _getLatestFailedPlanImportAuditForFile(
              _selectedStandardWorkbookPath!,
            );
      final reportPath = audit?.conflictReportPath;
      if (!mounted) {
        return;
      }
      setState(() {
        _standardImportFailureMessage = e.toString();
        _standardImportConflictReportPath = reportPath;
      });
      final suffix = reportPath == null ? '' : ' Conflict report: $reportPath';
      _showMessage('Standard workbook import failed: $e$suffix');
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
    final selectedInputs = [
      _selectedCsvPath,
      _selectedStrengthPath,
      _selectedStandardWorkbookPath
    ].where((e) => e != null && e.isNotEmpty).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        Text(
          'DATA OPERATIONS & AUDIT',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        const ClinicalBanner(
          text: 'Clinical Focus: Clean Imports & Traceable Exports',
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.85,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            MetricTile(
              title: 'Inputs Ready',
              valueText: '$selectedInputs',
              subtitleText: 'Selected import files',
              leadingIcon: Icons.attach_file_outlined,
            ),
            MetricTile(
              title: 'Exports',
              valueText: _paths.isEmpty ? 'Pending' : '${_paths.length} files',
              subtitleText: _weeklyWorkbookPath == null
                  ? 'Workbook not exported'
                  : 'Workbook ready',
              leadingIcon: Icons.download_done_outlined,
            ),
          ],
        ),
        const SizedBox(height: 14),
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
                    SizedBox(
                      width: 120,
                      child: PrimaryPillButton(
                        text: 'Pick CSV',
                        variant: PillButtonVariant.outlined,
                        onPressed: _pickCsvFile,
                      ),
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
                SizedBox(
                  width: double.infinity,
                  child: PrimaryPillButton(
                    text: 'Import Garmin CSV',
                    variant: PillButtonVariant.tonal,
                    onPressed: _importing ? null : _importGarminCsv,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryPillButton(
                    text: 'Open Manual Run Inputs',
                    variant: PillButtonVariant.outlined,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RunInputsScreen()),
                      );
                    },
                  ),
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
                    SizedBox(
                      width: 126,
                      child: PrimaryPillButton(
                        text: 'Pick XLSX',
                        variant: PillButtonVariant.outlined,
                        onPressed: _pickStandardWorkbookFile,
                      ),
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
                    SizedBox(
                      width: 132,
                      child: PrimaryPillButton(
                        text: 'Change Date',
                        variant: PillButtonVariant.outlined,
                        onPressed: _pickStandardSplitStartDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryPillButton(
                    text: 'Import Standard Workbook',
                    variant: PillButtonVariant.tonal,
                    onPressed:
                        _standardImporting ? null : _importStandardWorkbook,
                  ),
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
                if (_standardImportFailureMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .errorContainer
                          .withValues(alpha: 0.18),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last standard import failure',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(_standardImportFailureMessage!),
                        const SizedBox(height: 8),
                        if (_standardImportConflictReportPath != null)
                          SelectableText(
                            'Conflict report: $_standardImportConflictReportPath',
                          )
                        else
                          const Text(
                            'No conflict report was generated (import likely failed before conflict detection).',
                          ),
                      ],
                    ),
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
                    SizedBox(
                      width: 126,
                      child: PrimaryPillButton(
                        text: 'Pick XLSX',
                        variant: PillButtonVariant.outlined,
                        onPressed: _pickStrengthFile,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryPillButton(
                    text: 'Import Strength XLSX',
                    variant: PillButtonVariant.tonal,
                    onPressed:
                        _strengthImporting ? null : _importStrengthHistory,
                  ),
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
                    SizedBox(
                      width: 136,
                      child: PrimaryPillButton(
                        text: 'Choose Folder',
                        variant: PillButtonVariant.outlined,
                        onPressed: _pickExportDirectory,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryPillButton(
                    text: 'Export Standard Workbook',
                    variant: PillButtonVariant.tonal,
                    onPressed:
                        _weeklyExporting ? null : _exportStandardWorkbook,
                  ),
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
                SizedBox(
                  width: double.infinity,
                  child: PrimaryPillButton(
                    text: 'Export CSVs',
                    onPressed: _exporting ? null : _export,
                  ),
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
