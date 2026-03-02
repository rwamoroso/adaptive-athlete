import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/rules/recovery_gating.dart';
import '../../core/utils/app_providers.dart';
import '../../core/utils/date_utils.dart';
import '../training/exercise_substitution_service.dart';
import '../ui/clinical_widgets.dart';
import 'ppl_template_service.dart';
import 'weekly_planner_service.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  String _status = 'No weekly plan built yet.';

  String _primaryGoal = 'run_5mi_8min';
  String _experienceLevel = 'intermediate';
  int _daysPerWeek = 5;
  SplitType _preferredSplit = SplitType.ppl56d;
  final Set<String> _selectedEquipment = <String>{};
  final Set<String> _selectedContraindications = <String>{};

  DateTime _startDate = DateTime.now();
  SplitType _selectedSplit = SplitType.ppl56d;
  WeeklyPlanModifier _selectedModifier = WeeklyPlanModifier.followLongTerm;
  bool _propagateLongTerm = false;

  PlannerGenerationMode _generationMode = PlannerGenerationMode.manualAssist;
  bool _useCustomPromptText = false;

  final TextEditingController _goalTargetController = TextEditingController(
    text: '5 miles @ 8:00/mile',
  );
  final TextEditingController _scheduleConstraintsController =
      TextEditingController();
  final TextEditingController _additionalInstructionsController =
      TextEditingController();
  final TextEditingController _promptEditorController = TextEditingController();
  final TextEditingController _manualAiResponseController =
      TextEditingController();

  bool _profileSaving = false;
  bool _buildingPrompt = false;
  bool _oneTapGenerating = false;
  bool _manualApplying = false;
  String? _generatedPrompt;
  WeeklyPlanBuildRequest? _lastBuildRequest;

  // Legacy advanced tools
  String? _templatePath;
  String? _aiWeeklyPlanTextPath;
  String? _standardWorkbookPath;
  bool _applyProgression = false;
  bool _legacyGenerating = false;
  bool _legacyAiImporting = false;
  bool _legacyStandardImporting = false;

  String? _loadedScopeKey;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _selectedEquipment.addAll(settings.availableEquipment);
    _selectedContraindications.addAll(settings.movementContraindications);
  }

  @override
  void dispose() {
    _goalTargetController.dispose();
    _scheduleConstraintsController.dispose();
    _additionalInstructionsController.dispose();
    _promptEditorController.dispose();
    _manualAiResponseController.dispose();
    super.dispose();
  }

  String _scopeWorkspaceId() {
    final ctx = ref.read(activeWorkspaceContextProvider).valueOrNull;
    return ctx?.workspaceId ?? 'local_workspace';
  }

  String _scopeProfileId() {
    final ctx = ref.read(activeWorkspaceContextProvider).valueOrNull;
    return ctx?.profileId ?? 'local_profile';
  }

  Future<void> _loadPlanningProfileIfNeeded() async {
    final scopeKey = '${_scopeWorkspaceId()}|${_scopeProfileId()}';
    if (_loadedScopeKey == scopeKey) {
      return;
    }
    _loadedScopeKey = scopeKey;

    final service = ref.read(weeklyPlannerServiceProvider);
    final profile = await service.getPlanningProfile(
      workspaceId: _scopeWorkspaceId(),
      athleteProfileId: _scopeProfileId(),
    );
    if (!mounted || profile == null) {
      return;
    }

    setState(() {
      _primaryGoal = profile.primaryGoal;
      _goalTargetController.text = profile.goalTarget['text']?.toString() ?? '';
      _experienceLevel = profile.experienceLevel;
      _preferredSplit = profile.preferredSplit;
      _selectedSplit = profile.preferredSplit;
      _daysPerWeek = profile.daysPerWeek;
      _selectedEquipment
        ..clear()
        ..addAll(profile.availableEquipment);
      _selectedContraindications
        ..clear()
        ..addAll(profile.contraindications);
      _scheduleConstraintsController.text =
          profile.scheduleConstraints['notes']?.toString() ?? '';
    });
  }

  AthletePlanningProfile _buildPlanningProfileFromForm() {
    return AthletePlanningProfile(
      workspaceId: _scopeWorkspaceId(),
      athleteProfileId: _scopeProfileId(),
      primaryGoal: _primaryGoal,
      goalTarget: {'text': _goalTargetController.text.trim()},
      experienceLevel: _experienceLevel,
      preferredSplit: _preferredSplit,
      daysPerWeek: _daysPerWeek,
      availableEquipment: Set<String>.from(_selectedEquipment),
      contraindications: Set<String>.from(_selectedContraindications),
      scheduleConstraints: {
        'notes': _scheduleConstraintsController.text.trim(),
      },
    );
  }

  WeeklyPlanBuildRequest _buildPlanRequest({
    required PlannerGenerationMode mode,
  }) {
    final customPromptText =
        _useCustomPromptText ? _promptEditorController.text.trim() : null;

    return WeeklyPlanBuildRequest(
      workspaceId: _scopeWorkspaceId(),
      athleteProfileId: _scopeProfileId(),
      splitStartDate:
          DateTime(_startDate.year, _startDate.month, _startDate.day),
      splitType: _selectedSplit,
      modifier: _selectedModifier,
      mode: mode,
      propagateLongTermChanges: _propagateLongTerm,
      additionalInstructions: _additionalInstructionsController.text.trim(),
      overridePromptText: customPromptText == null || customPromptText.isEmpty
          ? null
          : customPromptText,
    );
  }

  Future<void> _saveIntakeProfile() async {
    setState(() => _profileSaving = true);
    try {
      await ref
          .read(weeklyPlannerServiceProvider)
          .upsertPlanningProfile(_buildPlanningProfileFromForm());
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'Athlete intake saved for this profile.';
      });
      _showMessage('Athlete intake saved.');
    } catch (e) {
      _showMessage('Failed to save intake: $e');
    } finally {
      if (mounted) {
        setState(() => _profileSaving = false);
      }
    }
  }

  Future<void> _buildPromptSnapshot() async {
    setState(() => _buildingPrompt = true);
    try {
      await ref
          .read(weeklyPlannerServiceProvider)
          .upsertPlanningProfile(_buildPlanningProfileFromForm());
      final request =
          _buildPlanRequest(mode: PlannerGenerationMode.manualAssist);
      final result =
          await ref.read(weeklyPlannerServiceProvider).generatePlan(request);

      if (!mounted) {
        return;
      }
      setState(() {
        _generatedPrompt = result.promptText;
        _lastBuildRequest = request;
        if (!_useCustomPromptText) {
          _promptEditorController.text = result.promptText;
        }
        _status = 'Prompt snapshot generated. Copy it or run one-tap AI.';
      });
      _showMessage('Prompt snapshot generated.');
    } catch (e) {
      _showMessage('Prompt build failed: $e');
    } finally {
      if (mounted) {
        setState(() => _buildingPrompt = false);
      }
    }
  }

  Future<void> _runOneTapAiBuild() async {
    setState(() => _oneTapGenerating = true);
    try {
      await ref
          .read(weeklyPlannerServiceProvider)
          .upsertPlanningProfile(_buildPlanningProfileFromForm());
      final request = _buildPlanRequest(mode: PlannerGenerationMode.oneTapAi);
      final result =
          await ref.read(weeklyPlannerServiceProvider).generatePlan(request);

      if (!mounted) {
        return;
      }
      setState(() {
        _generatedPrompt = result.promptText;
        _lastBuildRequest = request;
        if (result.generatedText != null && result.generatedText!.isNotEmpty) {
          _manualAiResponseController.text = result.generatedText!;
        }
        _status = result.importResult == null
            ? 'One-tap AI completed with no import result.'
            : 'One-tap AI build applied: ${result.importResult!.pretty()}';
      });
      _showMessage('One-tap AI build complete.');
    } catch (e) {
      final raw = e.toString();
      final normalized = raw.toLowerCase();
      if (normalized.contains('invalid jwt') || normalized.contains('401')) {
        _showMessage(
          'One-tap AI auth failed (Invalid JWT). Please sign out, sign back in, then try again.',
        );
      } else if (normalized.contains('no ai provider available') ||
          normalized.contains('provider is unavailable') ||
          normalized.contains('openai/provider generation failed')) {
        _showMessage('One-tap AI provider failed: $e');
      } else {
        _showMessage('One-tap AI build failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _oneTapGenerating = false);
      }
    }
  }

  Future<void> _applyManualAiResponse() async {
    final text = _manualAiResponseController.text.trim();
    if (text.isEmpty) {
      _showMessage('Paste AI weekly plan text before applying.');
      return;
    }

    setState(() => _manualApplying = true);
    try {
      await ref
          .read(weeklyPlannerServiceProvider)
          .upsertPlanningProfile(_buildPlanningProfileFromForm());
      final request = _lastBuildRequest ??
          _buildPlanRequest(mode: PlannerGenerationMode.manualAssist);
      final result = await ref
          .read(weeklyPlannerServiceProvider)
          .applyGeneratedPlanText(request: request, generatedText: text);

      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'Manual AI plan applied: ${result.pretty()}';
      });
      _showMessage('Manual AI weekly plan applied.');
    } catch (e) {
      _showMessage('Manual AI apply failed: $e');
    } finally {
      if (mounted) {
        setState(() => _manualApplying = false);
      }
    }
  }

  Future<void> _copyPromptToClipboard() async {
    final text = _promptEditorController.text.trim().isNotEmpty
        ? _promptEditorController.text.trim()
        : (_generatedPrompt ?? '');
    if (text.isEmpty) {
      _showMessage('No prompt generated yet.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    _showMessage('Prompt copied to clipboard.');
  }

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

  Future<void> _pickStandardWorkbookFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: false,
    );
    final path = result?.files.single.path;
    if (path != null) {
      setState(() => _standardWorkbookPath = path);
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

  Future<void> _generateFromTemplateLegacy() async {
    if (_templatePath == null) {
      _showMessage('Pick your training template XLSX first.');
      return;
    }
    final confirmed = await _confirmPlanCycleOverrideIfNeeded(
      splitStartDate: _startDate,
      actionLabel: 'Replace & Generate',
    );
    if (!confirmed) {
      _showMessage('Template generation cancelled.');
      return;
    }

    setState(() => _legacyGenerating = true);
    try {
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
        _showMessage('Template parse failed: ${parsed.errors.join(' | ')}');
        return;
      }

      final insertedSets = await db.replacePlanCycleFromTemplate(
        startDate: _startDate,
        days: parsed.days,
        applyProgression: _applyProgression,
        progressionAllowed: gate.progressionAllowed,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _status =
            'Legacy template generated ${parsed.days.length} days, $insertedSets sets.';
      });
      _showMessage('Legacy template plan generated.');
    } catch (e) {
      _showMessage('Legacy template generation failed: $e');
    } finally {
      if (mounted) {
        setState(() => _legacyGenerating = false);
      }
    }
  }

  Future<void> _importAiWeeklyPlanTextLegacy() async {
    if (_aiWeeklyPlanTextPath == null) {
      _showMessage('Pick an AI weekly plan text file (.txt/.md) first.');
      return;
    }
    final confirmed = await _confirmPlanCycleOverrideIfNeeded(
      splitStartDate: _startDate,
      actionLabel: 'Replace & Import',
    );
    if (!confirmed) {
      _showMessage('Legacy AI text import cancelled.');
      return;
    }

    setState(() => _legacyAiImporting = true);
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
        _status = 'Legacy AI text import complete: ${result.pretty()}';
      });
      _showMessage('Legacy AI text imported.');
    } catch (e) {
      _showMessage('Legacy AI text import failed: $e');
    } finally {
      if (mounted) {
        setState(() => _legacyAiImporting = false);
      }
    }
  }

  Future<void> _importStandardWorkbookLegacy() async {
    if (_standardWorkbookPath == null) {
      _showMessage('Pick a standard workbook XLSX first.');
      return;
    }
    final confirmed = await _confirmPlanCycleOverrideIfNeeded(
      splitStartDate: _startDate,
      actionLabel: 'Replace & Import',
    );
    if (!confirmed) {
      _showMessage('Standard workbook import cancelled.');
      return;
    }

    setState(() => _legacyStandardImporting = true);
    try {
      final result = await ref.read(appDbProvider).importStandardWorkbookXlsx(
            filePath: _standardWorkbookPath!,
            splitStartDate: _startDate,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'Legacy workbook import complete: ${result.pretty()}';
      });
      _showMessage('Standard workbook imported.');
    } catch (e) {
      _showMessage('Standard workbook import failed: $e');
    } finally {
      if (mounted) {
        setState(() => _legacyStandardImporting = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(activeWorkspaceContextProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadPlanningProfileIfNeeded();
      }
    });

    final plannerService = ref.watch(weeklyPlannerServiceProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        Text(
          'WEEKLY PLAN BUILDER',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        const ClinicalBanner(
          text:
              'One guided flow for intake, weekly setup, generation, and apply.',
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
              title: 'Scope',
              valueText: _scopeProfileId(),
              subtitleText: _scopeWorkspaceId(),
              leadingIcon: Icons.badge_outlined,
            ),
            MetricTile(
              title: 'Planner Backend',
              valueText: plannerService.isServerSideAiEnabled
                  ? 'Server AI enabled'
                  : 'Manual assist mode',
              subtitleText: plannerService.isServerSideAiEnabled
                  ? 'Edge function available'
                  : 'Sign in to enable one-tap AI',
              leadingIcon: Icons.auto_awesome_outlined,
            ),
          ],
        ),
        const SizedBox(height: 14),
        const SectionHeader(text: 'Step 1 — Athlete Intake'),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _primaryGoal,
                decoration: const InputDecoration(labelText: 'Primary Goal'),
                items: const [
                  DropdownMenuItem(
                    value: 'run_5mi_8min',
                    child: Text('Run 5 miles @ 8:00 pace'),
                  ),
                  DropdownMenuItem(
                    value: 'hypertrophy',
                    child: Text('Hypertrophy / Aesthetics'),
                  ),
                  DropdownMenuItem(
                    value: 'strength',
                    child: Text('Strength Performance'),
                  ),
                  DropdownMenuItem(
                    value: 'recomposition',
                    child: Text('Body Recomposition'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _primaryGoal = value);
                  }
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _goalTargetController,
                decoration: const InputDecoration(
                  labelText: 'Goal Target Details',
                  hintText: 'Example: 5 miles in 40:00 by July',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _experienceLevel,
                decoration:
                    const InputDecoration(labelText: 'Experience Level'),
                items: const [
                  DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                  DropdownMenuItem(
                      value: 'intermediate', child: Text('Intermediate')),
                  DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _experienceLevel = value);
                  }
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<SplitType>(
                value: _preferredSplit,
                decoration: const InputDecoration(labelText: 'Preferred Split'),
                items: SplitType.values
                    .map(
                      (split) => DropdownMenuItem(
                        value: split,
                        child: Text(split.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _preferredSplit = value;
                      _selectedSplit = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(child: Text('Training days / week')),
                  Text('$_daysPerWeek'),
                ],
              ),
              Slider(
                min: 3,
                max: 7,
                divisions: 4,
                value: _daysPerWeek.toDouble(),
                onChanged: (value) =>
                    setState(() => _daysPerWeek = value.round()),
              ),
              const SizedBox(height: 8),
              Text(
                'Available Equipment',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in ExerciseSubstitutionService.knownEquipment)
                    FilterChip(
                      label: Text(item),
                      selected: _selectedEquipment.contains(item),
                      onSelected: (_) {
                        setState(() {
                          if (!_selectedEquipment.add(item)) {
                            _selectedEquipment.remove(item);
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Movement Contraindications',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item
                      in ExerciseSubstitutionService.knownContraindications)
                    FilterChip(
                      label: Text(item),
                      selected: _selectedContraindications.contains(item),
                      onSelected: (_) {
                        setState(() {
                          if (!_selectedContraindications.add(item)) {
                            _selectedContraindications.remove(item);
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _scheduleConstraintsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Schedule Constraints',
                  hintText: 'Travel days, preferred rest days, time limits',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: PrimaryPillButton(
                  text: _profileSaving ? 'Saving...' : 'Save Athlete Intake',
                  variant: PillButtonVariant.tonal,
                  onPressed: _profileSaving ? null : _saveIntakeProfile,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionHeader(text: 'Step 2 — Week Setup'),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Week start: ${toYmd(_startDate)}')),
                  SizedBox(
                    width: 130,
                    child: PrimaryPillButton(
                      text: 'Change Date',
                      variant: PillButtonVariant.outlined,
                      onPressed: _pickStartDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<SplitType>(
                value: _selectedSplit,
                decoration:
                    const InputDecoration(labelText: 'Weekly Split Type'),
                items: SplitType.values
                    .map(
                      (split) => DropdownMenuItem(
                        value: split,
                        child: Text(split.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSplit = value);
                  }
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<WeeklyPlanModifier>(
                value: _selectedModifier,
                decoration: const InputDecoration(labelText: 'Weekly Modifier'),
                items: WeeklyPlanModifier.values
                    .map(
                      (modifier) => DropdownMenuItem(
                        value: modifier,
                        child: Text(modifier.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedModifier = value);
                  }
                },
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _propagateLongTerm,
                title: const Text('Also update long-term expectations'),
                subtitle: const Text(
                  'Off by default. If enabled, 10-week expectations may be updated.',
                ),
                onChanged: (value) =>
                    setState(() => _propagateLongTerm = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionHeader(text: 'Step 3 — Generation Mode + Prompt Controls'),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<PlannerGenerationMode>(
                segments: PlannerGenerationMode.values
                    .map(
                      (mode) => ButtonSegment<PlannerGenerationMode>(
                        value: mode,
                        label: Text(mode.label),
                      ),
                    )
                    .toList(),
                selected: {_generationMode},
                onSelectionChanged: (selection) {
                  setState(() => _generationMode = selection.first);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _additionalInstructionsController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Additional Planning Instructions',
                  hintText: 'Optional constraints or focus areas for this week',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _useCustomPromptText,
                title: const Text('Use custom prompt text for this run'),
                subtitle: const Text(
                  'Enable to edit raw prompt before generation/apply.',
                ),
                onChanged: (value) =>
                    setState(() => _useCustomPromptText = value),
              ),
              if (_useCustomPromptText) ...[
                const SizedBox(height: 6),
                TextField(
                  controller: _promptEditorController,
                  minLines: 8,
                  maxLines: 14,
                  decoration: const InputDecoration(
                    labelText: 'Raw Prompt Override',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: PrimaryPillButton(
                  text: _buildingPrompt
                      ? 'Building Prompt...'
                      : 'Build Prompt Snapshot',
                  variant: PillButtonVariant.outlined,
                  onPressed: _buildingPrompt ? null : _buildPromptSnapshot,
                ),
              ),
              if (_generatedPrompt != null) ...[
                const SizedBox(height: 8),
                ExpansionTile(
                  title: const Text('Prompt Preview'),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _generatedPrompt!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionHeader(text: 'Step 4 — Review + Apply'),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _copyPromptToClipboard,
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Copy Prompt'),
                  ),
                  if (_generationMode == PlannerGenerationMode.oneTapAi)
                    FilledButton.icon(
                      onPressed: _oneTapGenerating ? null : _runOneTapAiBuild,
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(
                        _oneTapGenerating
                            ? 'Generating...'
                            : 'Generate with One-tap AI',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _manualAiResponseController,
                minLines: 8,
                maxLines: 14,
                decoration: const InputDecoration(
                  labelText: 'AI Weekly Plan Response (WEEK_PLAN_V1 text)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: PrimaryPillButton(
                  text: _manualApplying
                      ? 'Applying...'
                      : 'Apply Pasted Weekly Plan Text',
                  variant: PillButtonVariant.tonal,
                  onPressed: _manualApplying ? null : _applyManualAiResponse,
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
              const SectionHeader(text: 'Planner Status'),
              const SizedBox(height: 8),
              Text(_status),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionHeader(text: 'Advanced Planning Tools'),
        const SizedBox(height: 8),
        GlassCard(
          child: ExpansionTile(
            title: const Text('Legacy XLSX/Text Imports & Template Generator'),
            subtitle: const Text(
              'Kept for compatibility. Preferred flow is the guided planner above.',
            ),
            childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
            children: [
              ListTile(
                title: const Text('Import Standard Workbook (XLSX)'),
                subtitle: Text(_standardWorkbookPath ?? 'No XLSX selected'),
                trailing: PrimaryPillButton(
                  text: 'Pick XLSX',
                  variant: PillButtonVariant.outlined,
                  onPressed: _pickStandardWorkbookFile,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: PrimaryPillButton(
                    text: _legacyStandardImporting
                        ? 'Importing...'
                        : 'Import Standard Workbook',
                    onPressed: _legacyStandardImporting
                        ? null
                        : _importStandardWorkbookLegacy,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Import AI Weekly Plan Text (.txt/.md)'),
                subtitle:
                    Text(_aiWeeklyPlanTextPath ?? 'No text file selected'),
                trailing: PrimaryPillButton(
                  text: 'Pick File',
                  variant: PillButtonVariant.outlined,
                  onPressed: _pickAiWeeklyPlanTextFile,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: PrimaryPillButton(
                    text:
                        _legacyAiImporting ? 'Importing...' : 'Import AI Text',
                    onPressed: _legacyAiImporting
                        ? null
                        : _importAiWeeklyPlanTextLegacy,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Generate from Template XLSX'),
                subtitle: Text(_templatePath ?? 'No template selected'),
                trailing: PrimaryPillButton(
                  text: 'Pick XLSX',
                  variant: PillButtonVariant.outlined,
                  onPressed: _pickTemplateFile,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Apply progression (+5 lb loaded sets)'),
                  subtitle: const Text(
                    'Legacy generator option (auto-blocked by recovery gate).',
                  ),
                  value: _applyProgression,
                  onChanged: (value) =>
                      setState(() => _applyProgression = value),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: PrimaryPillButton(
                    text: _legacyGenerating
                        ? 'Generating...'
                        : 'Generate from Template',
                    onPressed:
                        _legacyGenerating ? null : _generateFromTemplateLegacy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
