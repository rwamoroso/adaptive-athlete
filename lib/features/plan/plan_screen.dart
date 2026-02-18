import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/rules/recovery_gating.dart';
import '../../core/utils/app_providers.dart';
import '../../core/utils/date_utils.dart';
import 'ppl_template_service.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  String _status = 'No split plan generated yet.';
  String? _templatePath;
  DateTime _startDate = DateTime.now();
  bool _applyProgression = false;
  bool _generating = false;

  Future<void> _pickTemplateFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: false,
    );
    final path = result?.files.single.path;
    if (path != null) {
      setState(() => _templatePath = path);
    }
  }

  Future<void> _pickStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() => _startDate = selected);
    }
  }

  Future<void> _generatePlan() async {
    if (_templatePath == null) {
      setState(() {
        _status = 'Pick your training template XLSX first.';
      });
      return;
    }
    setState(() => _generating = true);

    final db = ref.read(appDbProvider);
    final startDateYmd = toYmd(_startDate);
    final sleep = await db.getSleepNightByDate(startDateYmd);
    final gate = RecoveryGating.evaluate(sleep?.totalSleepMin);

    await db.insertRuleTrigger(
      triggerDate: startDateYmd,
      ruleCode: 'RECOVERY_GATE',
      triggered: !gate.progressionAllowed,
      details: {
        'sleep_min': sleep?.totalSleepMin,
        'reasoning': gate.reasoning,
      },
    );

    final file = File(_templatePath!);
    final parsed = PplTemplateService.parseBytes(await file.readAsBytes());
    if (parsed.days.isEmpty) {
      setState(() {
        _generating = false;
        _status = 'Template parse failed: ${parsed.errors.join(' | ')}';
      });
      return;
    }

    var insertedSets = 0;
    insertedSets = await db.replacePlanCycleFromTemplate(
      startDate: _startDate,
      days: parsed.days,
      applyProgression: _applyProgression,
      progressionAllowed: gate.progressionAllowed,
    );

    setState(() {
      _generating = false;
      final progressionMsg = _applyProgression
          ? (gate.progressionAllowed
              ? 'progression applied'
              : 'progression blocked (${gate.reasoning})')
          : 'no progression requested';
      final warning = parsed.errors.isEmpty
          ? ''
          : ' Warnings: ${parsed.errors.join(' | ')}';
      _status = 'Generated ${parsed.days.length}-day PPL plan, '
          '$insertedSets prescribed sets in split, $progressionMsg.$warning';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Push / Pull / Legs Template',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _templatePath ?? 'No template selected',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _pickTemplateFile,
                child: const Text('Pick XLSX'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text('First Day of Split: ${toYmd(_startDate)}'),
              ),
              OutlinedButton(
                onPressed: _pickStartDate,
                child: const Text('Change Date'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Apply progression (+5 lb loaded sets)'),
            subtitle: const Text(
                'Blocked automatically when recovery gate fails (<6h sleep or unknown).'),
            value: _applyProgression,
            onChanged: (value) => setState(() => _applyProgression = value),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _generating ? null : _generatePlan,
            child: const Text('Generate Split Plan From Template'),
          ),
          const SizedBox(height: 12),
          Text(_status),
        ],
      ),
    );
  }
}
