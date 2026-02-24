import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/rules/recovery_gating.dart';
import '../../core/utils/app_providers.dart';
import '../../core/utils/date_utils.dart';
import '../ui/clinical_widgets.dart';
import 'ppl_template_service.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  String _status = 'No split plan generated yet.';
  String? _templatePath;
  String? _aiWeeklyPlanTextPath;
  DateTime _startDate = DateTime.now();
  bool _applyProgression = false;
  bool _generating = false;
  bool _aiImporting = false;

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

  Future<void> _pickAiWeeklyPlanTextFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['txt', 'md'],
      withData: false,
    );
    final path = result?.files.single.path;
    if (path != null) {
      setState(() => _aiWeeklyPlanTextPath = path);
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

  Future<void> _importAiWeeklyPlanText() async {
    if (_aiWeeklyPlanTextPath == null) {
      setState(() {
        _status = 'Pick an AI weekly plan text file (.txt/.md) first.';
      });
      return;
    }
    setState(() => _aiImporting = true);
    try {
      final file = File(_aiWeeklyPlanTextPath!);
      final text = await file.readAsString();
      final result = await ref.read(appDbProvider).importAiWeeklyPlanText(
            text: text,
            splitStartDate: _startDate,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'AI weekly plan import complete: '
            'days=${result.insertedPlanDays}, '
            'strength sets=${result.insertedStrengthSets}, '
            'run plans=${result.insertedRunPlans}, '
            'alternatives=${result.insertedAlternatives}, '
            '${result.replacedCycle ? 'replaced existing week' : 'new week inserted'}.';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'AI weekly plan import failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _aiImporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final templateStatus = _templatePath == null ? 'Not selected' : 'Selected';
    final progressionStatus = _applyProgression ? 'Enabled' : 'Disabled';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        Text(
          'ATHLETIC ADAPTATION PLANNING',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        const ClinicalBanner(
          text: 'Clinical Focus: Structured Load Progression',
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
              title: 'Template',
              valueText: templateStatus,
              subtitleText: _templatePath == null
                  ? 'Pick XLSX to continue'
                  : _templatePath!,
              leadingIcon: Icons.description_outlined,
            ),
            MetricTile(
              title: 'Progression',
              valueText: progressionStatus,
              subtitleText: 'Auto-blocked when recovery gate fails',
              leadingIcon: Icons.trending_up_outlined,
            ),
          ],
        ),
        const SizedBox(height: 14),
        const SectionHeader(text: 'Plan Builder'),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Push / Pull / Legs Template',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _templatePath ?? 'No template selected',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryPillButton(
                            text: 'Pick XLSX',
                            variant: PillButtonVariant.outlined,
                            onPressed: _pickTemplateFile,
                          ),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          _templatePath ?? 'No template selected',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 130,
                        child: PrimaryPillButton(
                          text: 'Pick XLSX',
                          variant: PillButtonVariant.outlined,
                          onPressed: _pickTemplateFile,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('First Day of Split: ${toYmd(_startDate)}'),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryPillButton(
                            text: 'Change Date',
                            variant: PillButtonVariant.outlined,
                            onPressed: _pickStartDate,
                          ),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: Text('First Day of Split: ${toYmd(_startDate)}'),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 130,
                        child: PrimaryPillButton(
                          text: 'Change Date',
                          variant: PillButtonVariant.outlined,
                          onPressed: _pickStartDate,
                        ),
                      ),
                    ],
                  );
                },
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
              SizedBox(
                width: double.infinity,
                child: PrimaryPillButton(
                  text: 'Generate Split Plan From Template',
                  onPressed: _generating ? null : _generatePlan,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Weekly Plan Text (WEEK_PLAN_V1)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Import AI-generated weekly plan text including ranked exercise alternatives. Use the prompt template in Settings to generate the correct format.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _aiWeeklyPlanTextPath ?? 'No AI plan text selected',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryPillButton(
                            text: 'Pick .txt / .md',
                            variant: PillButtonVariant.outlined,
                            onPressed: _pickAiWeeklyPlanTextFile,
                          ),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          _aiWeeklyPlanTextPath ?? 'No AI plan text selected',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 140,
                        child: PrimaryPillButton(
                          text: 'Pick .txt / .md',
                          variant: PillButtonVariant.outlined,
                          onPressed: _pickAiWeeklyPlanTextFile,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: PrimaryPillButton(
                  text: 'Import AI Weekly Plan Text',
                  onPressed: _aiImporting ? null : _importAiWeeklyPlanText,
                ),
              ),
              if (_aiImporting) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(minHeight: 2),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(text: 'Generation Status'),
              const SizedBox(height: 8),
              Text(_status),
            ],
          ),
        ),
      ],
    );
  }
}
