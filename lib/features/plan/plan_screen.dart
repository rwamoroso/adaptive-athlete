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
import 'biometrics_profile.dart';
import 'biometrics_profile_screen.dart';
import 'plan_builder_walkthrough_screen.dart';
import 'ppl_template_service.dart';
import 'weekly_planner_service.dart';

enum _PlannerWorkspaceTab { planning, advanced }

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _ShortTermGoalDraft {
  const _ShortTermGoalDraft({
    required this.goalText,
    required this.timelineWeeks,
  });

  final String goalText;
  final String timelineWeeks;
}

class _PlanSchedulePreviewDay {
  const _PlanSchedulePreviewDay({
    required this.dayLabel,
    required this.runTitle,
    required this.strengthTitle,
  });

  final String dayLabel;
  final String? runTitle;
  final String? strengthTitle;
}

class _ShortTermGoalScreen extends StatefulWidget {
  const _ShortTermGoalScreen({
    required this.initialGoalText,
    required this.initialTimelineWeeks,
  });

  final String initialGoalText;
  final String initialTimelineWeeks;

  @override
  State<_ShortTermGoalScreen> createState() => _ShortTermGoalScreenState();
}

class _ShortTermGoalScreenState extends State<_ShortTermGoalScreen> {
  late final TextEditingController _goalController;
  late final TextEditingController _weeksController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController(text: widget.initialGoalText);
    _weeksController = TextEditingController(text: widget.initialTimelineWeeks);
  }

  @override
  void dispose() {
    _goalController.dispose();
    _weeksController.dispose();
    super.dispose();
  }

  void _save() {
    final goalText = _goalController.text.trim();
    final timelineWeeks = _weeksController.text.trim();
    if (goalText.isNotEmpty && timelineWeeks.isEmpty) {
      setState(() {
        _errorText =
            'Timeline weeks is required when short-term goal text is provided.';
      });
      return;
    }
    if (goalText.isEmpty && timelineWeeks.isNotEmpty) {
      setState(() {
        _errorText =
            'Short-term goal text is required when timeline weeks is provided.';
      });
      return;
    }
    if (timelineWeeks.isNotEmpty) {
      final parsed = int.tryParse(timelineWeeks);
      if (parsed == null || parsed < 1 || parsed > 52) {
        setState(() {
          _errorText =
              'Timeline weeks must be a whole number between 1 and 52.';
        });
        return;
      }
    }
    Navigator.of(context).pop(
      _ShortTermGoalDraft(
        goalText: goalText,
        timelineWeeks: timelineWeeks,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Short-Term Goal')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        children: [
          const GlassCard(
            child: Text(
              'Set a short-term target so AI can tune your weekly plan toward a near-term outcome.',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _goalController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Short-Term Goal (optional)',
              hintText:
                  'Example: Abs showing for beach weekend, or train for a 10K.',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _weeksController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Timeline (weeks)',
              hintText: 'Example: 6',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'If short-term goal is entered, timeline is required (1-52).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PrimaryPillButton(
                  text: 'Cancel',
                  variant: PillButtonVariant.outlined,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryPillButton(text: 'Save Goal', onPressed: _save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  String _status = 'No weekly plan built yet.';

  static const String _runGoal = 'run_goal';
  static const String _strengthGoal = 'strength';
  static const String _hypertrophyGoal = 'hypertrophy';
  static const String _cardioGoal = 'cardio_improvement';

  String _primaryGoal = _runGoal;
  String _experienceLevel = 'intermediate';
  int _daysPerWeek = 5;
  final Set<int> _selectedTrainingWeekdays = <int>{
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  };
  SplitType _preferredSplit = SplitType.runOnly;
  final Set<String> _selectedEquipment = <String>{};
  final Set<String> _selectedContraindications = <String>{};
  Map<String, dynamic> _biometrics = <String, dynamic>{};

  DateTime _startDate = DateTime.now();
  SplitType _selectedSplit = SplitType.runOnly;
  WeeklyPlanModifier _selectedModifier = WeeklyPlanModifier.followLongTerm;
  bool _propagateLongTerm = false;

  PlannerGenerationMode _generationMode = PlannerGenerationMode.manualAssist;
  bool _useCustomPromptText = false;

  final TextEditingController _goalTargetController = TextEditingController(
    text: '5 miles',
  );
  final TextEditingController _runGoalDistanceController =
      TextEditingController(text: '5');
  final TextEditingController _runGoalPaceController = TextEditingController();
  final TextEditingController _shortTermGoalController =
      TextEditingController();
  final TextEditingController _shortTermGoalWeeksController =
      TextEditingController();
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
  _PlannerWorkspaceTab _workspaceTab = _PlannerWorkspaceTab.planning;
  String? _generatedPrompt;

  // Legacy advanced tools
  String? _templatePath;
  String? _aiWeeklyPlanTextPath;
  String? _standardWorkbookPath;
  bool _applyProgression = false;
  bool _legacyGenerating = false;
  bool _legacyAiImporting = false;
  bool _legacyStandardImporting = false;

  late Future<List<_PlanSchedulePreviewDay>> _schedulePreviewFuture;
  String? _loadedScopeKey;
  int? _walkthroughLastStepIndex;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _selectedEquipment.addAll(settings.availableEquipment);
    _selectedContraindications.addAll(settings.movementContraindications);
    _manualAiResponseController.text = ref.read(aiWeeklyPlanResponseProvider);
    _schedulePreviewFuture = _loadSchedulePreview();
  }

  @override
  void dispose() {
    _goalTargetController.dispose();
    _runGoalDistanceController.dispose();
    _runGoalPaceController.dispose();
    _shortTermGoalController.dispose();
    _shortTermGoalWeeksController.dispose();
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

  bool get _isRunGoalSelected {
    final normalized = _normalizePrimaryGoal(_primaryGoal);
    return normalized == _runGoal;
  }

  String _normalizePrimaryGoal(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'run_5mi_8min':
      case _runGoal:
        return _runGoal;
      case _strengthGoal:
        return _strengthGoal;
      case _hypertrophyGoal:
        return _hypertrophyGoal;
      case 'cardio':
      case _cardioGoal:
        return _cardioGoal;
      default:
        return _runGoal;
    }
  }

  String _defaultGoalTargetText(String goal) {
    switch (_normalizePrimaryGoal(goal)) {
      case _strengthGoal:
        return 'Improve overall strength with progressive overload.';
      case _hypertrophyGoal:
        return 'Build lean muscle size with consistent volume.';
      case _cardioGoal:
        return 'Improve aerobic capacity and endurance.';
      case _runGoal:
        return '5 miles';
      default:
        return '';
    }
  }

  String _nonRunGoalLabel() {
    switch (_normalizePrimaryGoal(_primaryGoal)) {
      case _strengthGoal:
        return 'Strength Goal Details';
      case _hypertrophyGoal:
        return 'Hypertrophy Goal Details';
      case _cardioGoal:
        return 'Cardio Improvement Details';
      default:
        return 'Goal Details';
    }
  }

  String _nonRunGoalHint() {
    switch (_normalizePrimaryGoal(_primaryGoal)) {
      case _strengthGoal:
        return 'Example: Add 40 lb to back squat in 12 weeks';
      case _hypertrophyGoal:
        return 'Example: Add 1.5 in to chest/arms over 16 weeks';
      case _cardioGoal:
        return 'Example: Improve aerobic base and lower easy-run heart rate';
      default:
        return 'Describe your goal target';
    }
  }

  void _onPrimaryGoalChanged(String rawGoal) {
    final normalized = _normalizePrimaryGoal(rawGoal);
    if (normalized == _primaryGoal) {
      return;
    }
    _primaryGoal = normalized;
    if (normalized != _runGoal) {
      _goalTargetController.text = _defaultGoalTargetText(normalized);
    }
  }

  InputDecoration _dropdownDecoration(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
    );
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Day';
    }
  }

  String _compactDayLabelFromYmd({
    required int dayNumber,
    required String? ymd,
  }) {
    final raw = (ymd ?? '').trim();
    if (raw.isEmpty) {
      return 'Day $dayNumber';
    }
    try {
      final date = parseYmd(raw);
      final weekday = _weekdayLabel(date.weekday);
      final shortWeekday =
          weekday.length > 3 ? weekday.substring(0, 3) : weekday;
      return '$shortWeekday ${date.month}/${date.day}';
    } catch (_) {
      return 'Day $dayNumber';
    }
  }

  String _titleCaseWords(String raw) {
    final words = raw
        .split(RegExp(r'[_\-\s]+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) {
      return '';
    }
    return words
        .map(
          (part) =>
              '${part.substring(0, 1).toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String? _buildRunTitle({
    required String? runType,
    required String? durationText,
    required String? notes,
  }) {
    final type = (runType ?? '').trim();
    final duration = (durationText ?? '').trim();
    if (type.isNotEmpty && duration.isNotEmpty) {
      return '$type • $duration';
    }
    if (type.isNotEmpty) {
      return type;
    }
    if (duration.isNotEmpty) {
      return duration;
    }
    final noteText = (notes ?? '').trim();
    if (noteText.isNotEmpty) {
      return noteText;
    }
    return null;
  }

  String? _buildStrengthTitle({
    required String? sessionType,
    required String? sheetName,
    required String? liftFocus,
    required bool hasStrengthSets,
  }) {
    final normalized = (sessionType ?? '').trim().toLowerCase();
    if (normalized.isNotEmpty && normalized != 'rest' && normalized != 'run') {
      final title = _titleCaseWords(normalized);
      if (title.isNotEmpty) {
        return '$title Focus';
      }
    }
    final lift = (liftFocus ?? '').trim();
    if (lift.isNotEmpty) {
      return lift;
    }
    if (hasStrengthSets) {
      final sheet = _titleCaseWords((sheetName ?? '').trim());
      if (sheet.isNotEmpty && sheet.toLowerCase() != 'rest') {
        return sheet;
      }
      return 'Strength Session';
    }
    return null;
  }

  Future<List<_PlanSchedulePreviewDay>> _loadSchedulePreview() async {
    final db = ref.read(appDbProvider);
    final anchor = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final cycle = await db.getActivePlanCycleForDate(toYmd(anchor));
    if (cycle == null) {
      return const <_PlanSchedulePreviewDay>[];
    }
    final days = <_PlanSchedulePreviewDay>[];
    for (var dayNumber = 1; dayNumber <= 7; dayNumber++) {
      final detail = await db.getPlanDayDetail(
        planCycleId: cycle.id,
        dayNumber: dayNumber,
      );
      if (detail == null) {
        continue;
      }
      final run = detail.prescribedRun;
      days.add(
        _PlanSchedulePreviewDay(
          dayLabel: _compactDayLabelFromYmd(
            dayNumber: dayNumber,
            ymd: detail.day.estimatedDate,
          ),
          runTitle: _buildRunTitle(
            runType: run?.runType,
            durationText: run?.durationText,
            notes: run?.notes,
          ),
          strengthTitle: _buildStrengthTitle(
            sessionType: detail.day.sessionType,
            sheetName: detail.day.sheetName,
            liftFocus: run?.liftFocus,
            hasStrengthSets: detail.strengthSets.isNotEmpty,
          ),
        ),
      );
    }
    return days;
  }

  void _refreshSchedulePreview() {
    if (!mounted) {
      return;
    }
    setState(() {
      _schedulePreviewFuture = _loadSchedulePreview();
    });
  }

  Widget _buildSchedulePreviewCard(BuildContext context) {
    return GlassCard(
      child: FutureBuilder<List<_PlanSchedulePreviewDay>>(
        future: _schedulePreviewFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Text(
              'Could not load weekly schedule preview.',
              style: Theme.of(context).textTheme.bodyMedium,
            );
          }
          final days = snapshot.data ?? const <_PlanSchedulePreviewDay>[];
          if (days.isEmpty) {
            return Text(
              'No active weekly plan found for the selected start date.',
              style: Theme.of(context).textTheme.bodyMedium,
            );
          }
          return Column(
            children: [
              for (var i = 0; i < days.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 88,
                        child: Text(
                          days[i].dayLabel,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (days[i].runTitle != null)
                              Text(
                                'Run: ${days[i].runTitle}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            if (days[i].strengthTitle != null)
                              Text(
                                'Strength: ${days[i].strengthTitle}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            if (days[i].runTitle == null &&
                                days[i].strengthTitle == null)
                              Text(
                                'Rest / Recovery',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (i != days.length - 1) const Divider(height: 1),
              ],
            ],
          );
        },
      ),
    );
  }

  List<int> _selectedWeekdaysSorted() {
    final sorted = _selectedTrainingWeekdays.toList()..sort();
    return sorted;
  }

  String _selectedWeekdaySummary() {
    final selected = _selectedWeekdaysSorted();
    if (selected.isEmpty) {
      return 'No weekdays selected.';
    }
    return selected.map(_weekdayLabel).join(', ');
  }

  ({int min, int max})? _splitTrainingDayRequirement(SplitType split) {
    switch (split) {
      case SplitType.runOnly:
        return (min: 4, max: 7);
      case SplitType.fullBody3d:
        return (min: 3, max: 3);
      case SplitType.upperLower4d:
      case SplitType.phul:
        return (min: 4, max: 4);
      case SplitType.ppl56d:
        return (min: 5, max: 6);
      case SplitType.hybridRunLift:
        return (min: 5, max: 7);
      case SplitType.arnold:
        return (min: 6, max: 6);
      case SplitType.broSplit:
        return (min: 5, max: 5);
      case SplitType.customHybrid:
        return (min: 4, max: 7);
    }
  }

  String _splitRequirementText(SplitType split) {
    final requirement = _splitTrainingDayRequirement(split);
    if (requirement == null) {
      return 'This split has no fixed day requirement.';
    }
    if (requirement.min == requirement.max) {
      return 'Split requirement: ${requirement.min} training day${requirement.min == 1 ? '' : 's'}.';
    }
    return 'Split requirement: ${requirement.min}-${requirement.max} training days.';
  }

  bool _selectedWeekdaysMeetSplitRequirement() {
    final requirement = _splitTrainingDayRequirement(_selectedSplit);
    if (requirement == null) {
      return true;
    }
    final count = _selectedTrainingWeekdays.length;
    return count >= requirement.min && count <= requirement.max;
  }

  Set<int> _weekdaysFromScheduleConstraints(Map<String, dynamic> constraints) {
    final raw = constraints['preferred_training_weekdays'];
    if (raw is! List) {
      return const <int>{};
    }
    final parsed = <int>{};
    for (final item in raw) {
      if (item is int && item >= DateTime.monday && item <= DateTime.sunday) {
        parsed.add(item);
        continue;
      }
      final text = item.toString().trim().toLowerCase();
      final mapped = switch (text) {
        '1' || 'monday' => DateTime.monday,
        '2' || 'tuesday' => DateTime.tuesday,
        '3' || 'wednesday' => DateTime.wednesday,
        '4' || 'thursday' => DateTime.thursday,
        '5' || 'friday' => DateTime.friday,
        '6' || 'saturday' => DateTime.saturday,
        '7' || 'sunday' => DateTime.sunday,
        _ => null,
      };
      if (mapped != null) {
        parsed.add(mapped);
      }
    }
    return parsed;
  }

  void _hydrateGoalTargetInputs(Map<String, dynamic> goalTarget) {
    final legacyText = goalTarget['text']?.toString().trim() ?? '';
    if (_isRunGoalSelected) {
      _goalTargetController.text = legacyText;
    } else {
      _goalTargetController.text = legacyText.isEmpty
          ? _defaultGoalTargetText(_primaryGoal)
          : legacyText;
    }

    final distanceRaw = goalTarget['distance_miles']?.toString().trim() ?? '';
    if (distanceRaw.isNotEmpty) {
      _runGoalDistanceController.text = distanceRaw;
    } else {
      final match =
          RegExp(r'(\d+(?:\.\d+)?)\s*(?:mile|miles)\b', caseSensitive: false)
              .firstMatch(legacyText);
      _runGoalDistanceController.text = match?.group(1) ?? '5';
    }

    final paceRaw = goalTarget['target_pace']?.toString().trim() ?? '';
    if (paceRaw.isNotEmpty) {
      _runGoalPaceController.text = paceRaw;
    } else {
      final paceMatch = RegExp(r'@\s*(.+)$').firstMatch(legacyText);
      _runGoalPaceController.text = paceMatch?.group(1)?.trim() ?? '';
    }

    final shortTermRaw = goalTarget['short_term_goal'];
    if (shortTermRaw is Map) {
      final shortTerm = Map<String, dynamic>.from(
        shortTermRaw.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
      _shortTermGoalController.text =
          shortTerm['text']?.toString().trim() ?? '';
      _shortTermGoalWeeksController.text =
          shortTerm['timeline_weeks']?.toString().trim() ?? '';
      return;
    }
    _shortTermGoalController.clear();
    _shortTermGoalWeeksController.clear();
  }

  String _formatMiles(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  Map<String, dynamic> _goalTargetFromForm() {
    final shortTermGoalText = _shortTermGoalController.text.trim();
    final shortTermWeeksRaw = _shortTermGoalWeeksController.text.trim();
    if (shortTermGoalText.isNotEmpty && shortTermWeeksRaw.isEmpty) {
      throw StateError(
        'Timeline weeks is required when short-term goal text is provided.',
      );
    }
    if (shortTermGoalText.isEmpty && shortTermWeeksRaw.isNotEmpty) {
      throw StateError(
        'Short-term goal text is required when timeline weeks is provided.',
      );
    }

    Map<String, dynamic>? shortTermGoal;
    if (shortTermGoalText.isNotEmpty) {
      final timelineWeeks = int.tryParse(shortTermWeeksRaw);
      if (timelineWeeks == null || timelineWeeks < 1 || timelineWeeks > 52) {
        throw StateError(
          'Timeline weeks must be a whole number between 1 and 52.',
        );
      }
      shortTermGoal = {
        'text': shortTermGoalText,
        'timeline_weeks': timelineWeeks,
      };
    }

    if (_isRunGoalSelected) {
      final distanceRaw = _runGoalDistanceController.text.trim();
      if (distanceRaw.isEmpty) {
        throw StateError('Run goal distance is required.');
      }
      final distanceMiles = double.tryParse(distanceRaw);
      if (distanceMiles == null || distanceMiles <= 0) {
        throw StateError('Run goal distance must be a positive number.');
      }
      final pace = _runGoalPaceController.text.trim();
      final distanceLabel = '${_formatMiles(distanceMiles)} miles';
      final summaryText =
          pace.isEmpty ? distanceLabel : '$distanceLabel @ $pace';
      _goalTargetController.text = summaryText;
      final goalTarget = <String, dynamic>{
        'distance_miles': distanceMiles,
        'target_pace': pace.isEmpty ? null : pace,
        'text': summaryText,
      };
      // Keep this payload in goal_target_json so the prompt context carries it.
      if (shortTermGoal != null) {
        goalTarget['short_term_goal'] = shortTermGoal;
      }
      return goalTarget;
    }
    final text = _goalTargetController.text.trim();
    final goalTarget = <String, dynamic>{
      'text': text.isEmpty ? _defaultGoalTargetText(_primaryGoal) : text,
    };
    if (shortTermGoal != null) {
      goalTarget['short_term_goal'] = shortTermGoal;
    }
    return goalTarget;
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
      _primaryGoal = _normalizePrimaryGoal(profile.primaryGoal);
      _hydrateGoalTargetInputs(profile.goalTarget);
      _experienceLevel = profile.experienceLevel;
      _preferredSplit = profile.preferredSplit;
      _selectedSplit = profile.preferredSplit;
      _daysPerWeek = profile.daysPerWeek;
      final savedWeekdays =
          _weekdaysFromScheduleConstraints(profile.scheduleConstraints);
      if (savedWeekdays.isNotEmpty) {
        _selectedTrainingWeekdays
          ..clear()
          ..addAll(savedWeekdays);
      }
      _selectedEquipment
        ..clear()
        ..addAll(profile.availableEquipment);
      _selectedContraindications
        ..clear()
        ..addAll(profile.contraindications);
      _scheduleConstraintsController.text =
          profile.scheduleConstraints['notes']?.toString() ?? '';
      _biometrics = Map<String, dynamic>.from(profile.biometrics);
    });
  }

  AthletePlanningProfile _buildPlanningProfileFromForm() {
    return AthletePlanningProfile(
      workspaceId: _scopeWorkspaceId(),
      athleteProfileId: _scopeProfileId(),
      primaryGoal: _primaryGoal,
      goalTarget: _goalTargetFromForm(),
      experienceLevel: _experienceLevel,
      preferredSplit: _preferredSplit,
      daysPerWeek: _daysPerWeek,
      availableEquipment: Set<String>.from(_selectedEquipment),
      contraindications: Set<String>.from(_selectedContraindications),
      scheduleConstraints: {
        'notes': _scheduleConstraintsController.text.trim(),
        'preferred_training_weekdays': _selectedWeekdaysSorted(),
      },
      biometrics: BiometricsCalculator.normalizeInputMap(_biometrics) ??
          const <String, dynamic>{},
    );
  }

  WeeklyPlanBuildRequest _buildPlanRequest({
    required PlannerGenerationMode mode,
  }) {
    final customPromptText =
        _useCustomPromptText ? _promptEditorController.text.trim() : null;
    final userNotes = _additionalInstructionsController.text.trim();
    final weekdayNotes =
        'Preferred training weekdays: ${_selectedWeekdaySummary()}';
    final splitRequirementNotes = _splitRequirementText(_selectedSplit);
    final combinedNotes = <String>[
      if (userNotes.isNotEmpty) userNotes,
      weekdayNotes,
      splitRequirementNotes,
      if (!_selectedWeekdaysMeetSplitRequirement())
        'Selected weekdays do not match this split requirement. Keep requested weekdays as much as possible and adjust with recovery-first logic.',
    ].join('\n');

    return WeeklyPlanBuildRequest(
      workspaceId: _scopeWorkspaceId(),
      athleteProfileId: _scopeProfileId(),
      splitStartDate:
          DateTime(_startDate.year, _startDate.month, _startDate.day),
      splitType: _selectedSplit,
      modifier: _selectedModifier,
      mode: mode,
      propagateLongTermChanges: _propagateLongTerm,
      additionalInstructions: combinedNotes,
      overridePromptText: customPromptText == null || customPromptText.isEmpty
          ? null
          : customPromptText,
    );
  }

  Future<bool> _saveIntakeProfileInternal() async {
    setState(() => _profileSaving = true);
    try {
      await ref
          .read(weeklyPlannerServiceProvider)
          .upsertPlanningProfile(_buildPlanningProfileFromForm());
      if (!mounted) {
        return false;
      }
      setState(() {
        _status = 'Athlete intake saved for this profile.';
      });
      _showMessage('Athlete intake saved.');
      return true;
    } catch (e) {
      _showMessage('Failed to save intake: $e');
      return false;
    } finally {
      if (mounted) {
        setState(() => _profileSaving = false);
      }
    }
  }

  Future<void> _saveIntakeProfile() async {
    await _saveIntakeProfileInternal();
  }

  Future<String?> _buildPromptSnapshotInternal() async {
    setState(() => _buildingPrompt = true);
    try {
      _warnIfBiometricsMissing();
      await ref
          .read(weeklyPlannerServiceProvider)
          .upsertPlanningProfile(_buildPlanningProfileFromForm());
      final request =
          _buildPlanRequest(mode: PlannerGenerationMode.manualAssist);
      final result =
          await ref.read(weeklyPlannerServiceProvider).generatePlan(request);

      if (!mounted) {
        return null;
      }
      setState(() {
        _generatedPrompt = result.promptText;
        if (!_useCustomPromptText) {
          _promptEditorController.text = result.promptText;
        }
        _status = 'Prompt snapshot generated. Copy it or run one-tap AI.';
      });
      _showMessage('Prompt snapshot generated.');
      return result.promptText;
    } catch (e) {
      _showMessage('Prompt build failed: $e');
      return null;
    } finally {
      if (mounted) {
        setState(() => _buildingPrompt = false);
      }
    }
  }

  Future<void> _buildPromptSnapshot() async {
    await _buildPromptSnapshotInternal();
  }

  Future<void> _runOneTapAiBuild() async {
    setState(() => _oneTapGenerating = true);
    try {
      _warnIfBiometricsMissing();
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
        if (result.generatedText != null && result.generatedText!.isNotEmpty) {
          _manualAiResponseController.text = result.generatedText!;
          ref.read(aiWeeklyPlanResponseProvider.notifier).state =
              result.generatedText!;
        }
        _status = result.importResult == null
            ? 'One-tap AI completed with no import result.'
            : 'One-tap AI build applied: ${result.importResult!.pretty()}';
      });
      _refreshSchedulePreview();
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

  void _syncManualAiResponseText(String text) {
    if (_manualAiResponseController.text != text) {
      _manualAiResponseController.text = text;
    }
    ref.read(aiWeeklyPlanResponseProvider.notifier).state = text;
  }

  Future<bool> _applyManualAiResponseInternal(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) {
      _showMessage('Paste AI weekly plan text before applying.');
      return false;
    }

    if (_manualAiResponseController.text != rawText) {
      _manualAiResponseController.text = rawText;
    }
    ref.read(aiWeeklyPlanResponseProvider.notifier).state = rawText;

    setState(() => _manualApplying = true);
    try {
      await ref
          .read(weeklyPlannerServiceProvider)
          .upsertPlanningProfile(_buildPlanningProfileFromForm());
      final request =
          _buildPlanRequest(mode: PlannerGenerationMode.manualAssist);
      final result = await ref
          .read(weeklyPlannerServiceProvider)
          .applyGeneratedPlanText(request: request, generatedText: text);

      if (!mounted) {
        return false;
      }
      ref.read(aiWeeklyPlanResponseProvider.notifier).state = text;
      setState(() {
        _status = 'Manual AI plan applied: ${result.pretty()}';
      });
      _refreshSchedulePreview();
      _showMessage('Manual AI weekly plan applied.');
      return true;
    } catch (e) {
      _showMessage('Manual AI apply failed: $e');
      return false;
    } finally {
      if (mounted) {
        setState(() => _manualApplying = false);
      }
    }
  }

  Future<void> _applyManualAiResponse() async {
    await _applyManualAiResponseInternal(_manualAiResponseController.text);
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
      setState(() {
        _startDate = selected;
        _schedulePreviewFuture = _loadSchedulePreview();
      });
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
      _refreshSchedulePreview();
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
      _refreshSchedulePreview();
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
      _refreshSchedulePreview();
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

  Map<String, dynamic>? _biometricsPromptPayload() {
    return BiometricsCalculator.computePromptPayloadFromMap(
      rawInput: _biometrics,
      daysPerWeek: _daysPerWeek,
    );
  }

  String _biometricsSummaryText() {
    final payload = _biometricsPromptPayload();
    if (payload == null) {
      return 'Biometrics not configured';
    }
    final bodyFat = payload['body_fat_percent'];
    final bmi = payload['bmi'];
    final tdee = payload['estimated_tdee_kcal'];
    return 'Configured • BF $bodyFat% • BMI $bmi • TDEE ~$tdee kcal';
  }

  Future<void> _openBiometricsEditor() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => BiometricsProfileScreen(
          initialBiometrics: _biometrics,
          daysPerWeek: _daysPerWeek,
        ),
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    setState(() {
      _biometrics = result;
    });
    _showMessage('Biometrics saved in plan intake.');
  }

  void _warnIfBiometricsMissing() {
    if (_biometricsPromptPayload() != null) {
      return;
    }
    _showMessage(
      'Biometrics are not configured yet. Continuing without BIOMETRICS_V1 context.',
    );
  }

  PlanBuilderWalkthroughDraft _walkthroughDraftFromForm() {
    final distance = _runGoalDistanceController.text.trim();
    final pace = _runGoalPaceController.text.trim();
    return PlanBuilderWalkthroughDraft(
      primaryGoal: _normalizePrimaryGoal(_primaryGoal),
      runTargetEnabled: distance.isNotEmpty || pace.isNotEmpty,
      runDistanceMiles: distance,
      runPace: pace,
      experienceLevel: _experienceLevel,
      shortTermGoalText: _shortTermGoalController.text.trim(),
      shortTermGoalWeeks: _shortTermGoalWeeksController.text.trim(),
      weekStartDate:
          DateTime(_startDate.year, _startDate.month, _startDate.day),
      splitType: _selectedSplit,
      trainingWeekdays: _selectedTrainingWeekdays,
      availableEquipment: _selectedEquipment,
      contraindications: _selectedContraindications,
      scheduleConstraints: _scheduleConstraintsController.text.trim(),
      weeklyModifier: _selectedModifier,
      propagateLongTerm: _propagateLongTerm,
      additionalInstructions: _additionalInstructionsController.text.trim(),
      useCustomPromptText: _useCustomPromptText,
      customPromptText: _promptEditorController.text,
      biometrics: _biometrics,
    );
  }

  void _applyWalkthroughDraft(PlanBuilderWalkthroughDraft draft) {
    final normalizedDraftStartDate = DateTime(
      draft.weekStartDate.year,
      draft.weekStartDate.month,
      draft.weekStartDate.day,
    );
    final startDateChanged =
        toYmd(_startDate) != toYmd(normalizedDraftStartDate);
    setState(() {
      _onPrimaryGoalChanged(draft.primaryGoal);
      if (_normalizePrimaryGoal(draft.primaryGoal) == _runGoal) {
        final distance = draft.runDistanceMiles.trim();
        if (distance.isNotEmpty) {
          _runGoalDistanceController.text = distance;
        } else if (_runGoalDistanceController.text.trim().isEmpty) {
          _runGoalDistanceController.text = '5';
        }
        _runGoalPaceController.text = draft.runPace.trim();
      }

      _experienceLevel = draft.experienceLevel;
      _shortTermGoalController.text = draft.shortTermGoalText;
      _shortTermGoalWeeksController.text = draft.shortTermGoalWeeks;
      _startDate = normalizedDraftStartDate;
      _preferredSplit = draft.splitType;
      _selectedSplit = draft.splitType;
      _daysPerWeek = draft.trainingWeekdays.length.clamp(3, 7);
      _selectedTrainingWeekdays
        ..clear()
        ..addAll(draft.trainingWeekdays);
      _selectedEquipment
        ..clear()
        ..addAll(draft.availableEquipment);
      _selectedContraindications
        ..clear()
        ..addAll(draft.contraindications);
      _scheduleConstraintsController.text = draft.scheduleConstraints;
      _selectedModifier = draft.weeklyModifier;
      _propagateLongTerm = draft.propagateLongTerm;
      _additionalInstructionsController.text = draft.additionalInstructions;
      _useCustomPromptText = draft.useCustomPromptText;
      _promptEditorController.text = draft.customPromptText;
      _biometrics = Map<String, dynamic>.from(draft.biometrics);
      if (startDateChanged) {
        _schedulePreviewFuture = _loadSchedulePreview();
      }
    });
  }

  Future<void> _openPlanBuilderWalkthrough() async {
    var initialStep = 0;
    final lastStep = _walkthroughLastStepIndex;
    if (lastStep != null && lastStep > 0) {
      final resumeChoice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Resume Walkthrough?'),
          content: const Text(
            'Continue where you left off, or start over from the intro screen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('start_over'),
              child: const Text('Start Over'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('resume'),
              child: const Text('Resume'),
            ),
          ],
        ),
      );

      if (!mounted) {
        return;
      }
      if (resumeChoice == null) {
        return;
      }
      if (resumeChoice == 'resume') {
        initialStep = lastStep;
      } else {
        _walkthroughLastStepIndex = 0;
      }
    }

    if (!mounted) {
      return;
    }
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PlanBuilderWalkthroughScreen(
          initialDraft: _walkthroughDraftFromForm(),
          initialStep: initialStep,
          initialManualResponseText: _manualAiResponseController.text,
          onDraftChanged: _applyWalkthroughDraft,
          onManualResponseChanged: _syncManualAiResponseText,
          onStepChanged: (step) {
            _walkthroughLastStepIndex = step;
          },
          onCompleted: () {
            _walkthroughLastStepIndex = null;
          },
          onSaveIntakeRequested: _saveIntakeProfileInternal,
          onBuildPromptRequested: _buildPromptSnapshotInternal,
          onApplyManualResponseRequested: _applyManualAiResponseInternal,
        ),
      ),
    );

    if (!mounted) {
      return;
    }
    if (completed == true) {
      _walkthroughLastStepIndex = null;
    }
  }

  Future<void> _openShortTermGoalEditor() async {
    final result = await Navigator.of(context).push<_ShortTermGoalDraft>(
      MaterialPageRoute(
        builder: (_) => _ShortTermGoalScreen(
          initialGoalText: _shortTermGoalController.text,
          initialTimelineWeeks: _shortTermGoalWeeksController.text,
        ),
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    setState(() {
      _shortTermGoalController.text = result.goalText;
      _shortTermGoalWeeksController.text = result.timelineWeeks;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(activeWorkspaceContextProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadPlanningProfileIfNeeded();
      }
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        Text(
          'PROGRESSIVE OVERLOAD PLAN',
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
        const SectionHeader(text: 'Weekly Run + Strength Schedule'),
        const SizedBox(height: 8),
        _buildSchedulePreviewCard(context),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: PrimaryPillButton(
            text: 'Adaptation Philosophy',
            icon: Icons.auto_awesome,
            variant: PillButtonVariant.filled,
            onPressed: _openPlanBuilderWalkthrough,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: PrimaryPillButton(
            text: 'Short-Term Goal',
            icon: Icons.flag_outlined,
            variant: PillButtonVariant.tonal,
            onPressed: _openShortTermGoalEditor,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: PrimaryPillButton(
            text: 'Biometric Profile',
            icon: Icons.monitor_weight_outlined,
            variant: PillButtonVariant.tonal,
            onPressed: _openBiometricsEditor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _biometricsSummaryText(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        const SectionHeader(text: 'Step 1 — Athletic Goal Setting'),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _primaryGoal,
                dropdownColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                decoration: _dropdownDecoration(context, 'Primary Goal'),
                items: const [
                  DropdownMenuItem(
                    value: _runGoal,
                    child: Text('Run Goal'),
                  ),
                  DropdownMenuItem(
                    value: _strengthGoal,
                    child: Text('Strength Goal (Strength)'),
                  ),
                  DropdownMenuItem(
                    value: _hypertrophyGoal,
                    child: Text('Strength Goal (Hypertrophy)'),
                  ),
                  DropdownMenuItem(
                    value: _cardioGoal,
                    child: Text('Cardio Improvement'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _onPrimaryGoalChanged(value));
                  }
                },
              ),
              const SizedBox(height: 8),
              if (_isRunGoalSelected)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _runGoalDistanceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Distance (miles) *',
                          hintText: 'Example: 5',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _runGoalPaceController,
                        decoration: const InputDecoration(
                          labelText: 'Target Pace (optional)',
                          hintText: 'Example: 9:15-9:10/mi',
                        ),
                      ),
                    ),
                  ],
                )
              else
                TextField(
                  controller: _goalTargetController,
                  decoration: InputDecoration(
                    labelText: _nonRunGoalLabel(),
                    hintText: _nonRunGoalHint(),
                  ),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: _shortTermGoalController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Short-Term Goal (optional)',
                  hintText:
                      'Example: Abs showing for beach weekend, or train for a 10K.',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _shortTermGoalWeeksController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Timeline (weeks)',
                  hintText: 'Example: 6',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'If short-term goal is entered, timeline is required (1-52).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _experienceLevel,
                dropdownColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                decoration: _dropdownDecoration(context, 'Experience Level'),
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
                initialValue: _preferredSplit,
                dropdownColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                decoration: _dropdownDecoration(context, 'Preferred Split'),
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
                initialValue: _selectedSplit,
                dropdownColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                decoration: _dropdownDecoration(context, 'Weekly Split Type'),
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
              Text(
                _splitRequirementText(_selectedSplit),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _selectedWeekdaysMeetSplitRequirement()
                          ? null
                          : Colors.orange.shade300,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Workout Weekdays',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                _selectedWeekdaySummary(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              for (final weekday in const <int>[
                DateTime.monday,
                DateTime.tuesday,
                DateTime.wednesday,
                DateTime.thursday,
                DateTime.friday,
                DateTime.saturday,
                DateTime.sunday,
              ])
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _selectedTrainingWeekdays.contains(weekday),
                  title: Text(_weekdayLabel(weekday)),
                  onChanged: (selected) {
                    if (selected == null) {
                      return;
                    }
                    setState(() {
                      if (selected) {
                        _selectedTrainingWeekdays.add(weekday);
                      } else {
                        _selectedTrainingWeekdays.remove(weekday);
                      }
                    });
                  },
                ),
              const SizedBox(height: 8),
              DropdownButtonFormField<WeeklyPlanModifier>(
                initialValue: _selectedModifier,
                dropdownColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                decoration: _dropdownDecoration(context, 'Weekly Modifier'),
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
        const SectionHeader(text: 'Step 3 — Planning Workspace'),
        const SizedBox(height: 8),
        GlassCard(
          child: SegmentedButton<_PlannerWorkspaceTab>(
            segments: const [
              ButtonSegment<_PlannerWorkspaceTab>(
                value: _PlannerWorkspaceTab.planning,
                label: Text('Planning'),
                icon: Icon(Icons.tune),
              ),
              ButtonSegment<_PlannerWorkspaceTab>(
                value: _PlannerWorkspaceTab.advanced,
                label: Text('Advanced'),
                icon: Icon(Icons.build_outlined),
              ),
            ],
            selected: {_workspaceTab},
            onSelectionChanged: (selection) {
              setState(() => _workspaceTab = selection.first);
            },
          ),
        ),
        const SizedBox(height: 8),
        if (_workspaceTab == _PlannerWorkspaceTab.planning) ...[
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
                    hintText:
                        'Optional constraints or focus areas for this week',
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
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
                const SizedBox(height: 8),
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
                  onChanged: (value) {
                    ref.read(aiWeeklyPlanResponseProvider.notifier).state =
                        value;
                    setState(() {});
                  },
                  decoration: const InputDecoration(
                    labelText: 'Paste Weekly AI Plan Response Here.',
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
        ] else ...[
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(text: 'Advanced Planning Tools'),
                const SizedBox(height: 8),
                const Text(
                  'Use legacy import/generation workflows from local files.',
                ),
                const SizedBox(height: 12),
                Text(
                  'Template Workbook (XLSX)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _templatePath ?? 'No file selected',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    PrimaryPillButton(
                      text: 'Pick File',
                      variant: PillButtonVariant.outlined,
                      onPressed: _pickTemplateFile,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _applyProgression,
                  title: const Text('Apply progression adjustments'),
                  onChanged: (value) =>
                      setState(() => _applyProgression = value),
                ),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryPillButton(
                    text: _legacyGenerating
                        ? 'Generating...'
                        : 'Generate From Template',
                    onPressed:
                        _legacyGenerating ? null : _generateFromTemplateLegacy,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'AI Weekly Plan Text (.txt/.md)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _aiWeeklyPlanTextPath ?? 'No file selected',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    PrimaryPillButton(
                      text: 'Pick File',
                      variant: PillButtonVariant.outlined,
                      onPressed: _pickAiWeeklyPlanTextFile,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryPillButton(
                    text: _legacyAiImporting
                        ? 'Importing...'
                        : 'Import AI Weekly Plan Text',
                    variant: PillButtonVariant.tonal,
                    onPressed: _legacyAiImporting
                        ? null
                        : _importAiWeeklyPlanTextLegacy,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Standard Workbook (XLSX)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _standardWorkbookPath ?? 'No file selected',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    PrimaryPillButton(
                      text: 'Pick File',
                      variant: PillButtonVariant.outlined,
                      onPressed: _pickStandardWorkbookFile,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryPillButton(
                    text: _legacyStandardImporting
                        ? 'Importing...'
                        : 'Import Standard Workbook',
                    variant: PillButtonVariant.tonal,
                    onPressed: _legacyStandardImporting
                        ? null
                        : _importStandardWorkbookLegacy,
                  ),
                ),
              ],
            ),
          ),
        ],
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
      ],
    );
  }
}
