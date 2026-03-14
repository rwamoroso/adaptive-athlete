import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/date_utils.dart';
import 'biometrics_profile.dart';
import 'biometrics_profile_screen.dart';
import '../training/exercise_substitution_service.dart';
import '../ui/clinical_theme.dart';
import '../ui/clinical_widgets.dart';
import 'weekly_planner_service.dart';

class PlanBuilderWalkthroughDraft {
  PlanBuilderWalkthroughDraft({
    required this.primaryGoal,
    required this.runTargetEnabled,
    required this.runDistanceMiles,
    required this.runPace,
    required this.experienceLevel,
    required this.shortTermGoalText,
    required this.shortTermGoalWeeks,
    required DateTime weekStartDate,
    required this.splitType,
    required Set<int> trainingWeekdays,
    required Set<String> availableEquipment,
    required Set<String> contraindications,
    required this.scheduleConstraints,
    required this.weeklyModifier,
    required this.propagateLongTerm,
    required this.additionalInstructions,
    required this.useCustomPromptText,
    required this.customPromptText,
    required Map<String, dynamic> biometrics,
  })  : weekStartDate = DateTime(
          weekStartDate.year,
          weekStartDate.month,
          weekStartDate.day,
        ),
        trainingWeekdays = Set<int>.unmodifiable(trainingWeekdays),
        availableEquipment = Set<String>.unmodifiable(availableEquipment),
        contraindications = Set<String>.unmodifiable(contraindications),
        biometrics = Map<String, dynamic>.unmodifiable(biometrics);

  static const String runGoal = 'run_goal';
  static const String strengthGoal = 'strength';
  static const String hypertrophyGoal = 'hypertrophy';
  static const String cardioGoal = 'cardio_improvement';

  final String primaryGoal;
  final bool runTargetEnabled;
  final String runDistanceMiles;
  final String runPace;
  final String experienceLevel;
  final String shortTermGoalText;
  final String shortTermGoalWeeks;
  final DateTime weekStartDate;
  final SplitType splitType;
  final Set<int> trainingWeekdays;
  final Set<String> availableEquipment;
  final Set<String> contraindications;
  final String scheduleConstraints;
  final WeeklyPlanModifier weeklyModifier;
  final bool propagateLongTerm;
  final String additionalInstructions;
  final bool useCustomPromptText;
  final String customPromptText;
  final Map<String, dynamic> biometrics;

  bool get isRunGoal => primaryGoal == runGoal;

  PlanBuilderWalkthroughDraft copyWith({
    String? primaryGoal,
    bool? runTargetEnabled,
    String? runDistanceMiles,
    String? runPace,
    String? experienceLevel,
    String? shortTermGoalText,
    String? shortTermGoalWeeks,
    DateTime? weekStartDate,
    SplitType? splitType,
    Set<int>? trainingWeekdays,
    Set<String>? availableEquipment,
    Set<String>? contraindications,
    String? scheduleConstraints,
    WeeklyPlanModifier? weeklyModifier,
    bool? propagateLongTerm,
    String? additionalInstructions,
    bool? useCustomPromptText,
    String? customPromptText,
    Map<String, dynamic>? biometrics,
  }) {
    return PlanBuilderWalkthroughDraft(
      primaryGoal: primaryGoal ?? this.primaryGoal,
      runTargetEnabled: runTargetEnabled ?? this.runTargetEnabled,
      runDistanceMiles: runDistanceMiles ?? this.runDistanceMiles,
      runPace: runPace ?? this.runPace,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      shortTermGoalText: shortTermGoalText ?? this.shortTermGoalText,
      shortTermGoalWeeks: shortTermGoalWeeks ?? this.shortTermGoalWeeks,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      splitType: splitType ?? this.splitType,
      trainingWeekdays: trainingWeekdays ?? this.trainingWeekdays,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      contraindications: contraindications ?? this.contraindications,
      scheduleConstraints: scheduleConstraints ?? this.scheduleConstraints,
      weeklyModifier: weeklyModifier ?? this.weeklyModifier,
      propagateLongTerm: propagateLongTerm ?? this.propagateLongTerm,
      additionalInstructions:
          additionalInstructions ?? this.additionalInstructions,
      useCustomPromptText: useCustomPromptText ?? this.useCustomPromptText,
      customPromptText: customPromptText ?? this.customPromptText,
      biometrics: biometrics ?? this.biometrics,
    );
  }
}

enum _PromptWorkspaceView {
  response,
  fullPrompt,
}

class PlanBuilderWalkthroughScreen extends StatefulWidget {
  const PlanBuilderWalkthroughScreen({
    super.key,
    required this.initialDraft,
    required this.initialStep,
    required this.initialManualResponseText,
    required this.onDraftChanged,
    required this.onManualResponseChanged,
    required this.onStepChanged,
    required this.onCompleted,
    required this.onSaveIntakeRequested,
    required this.onBuildPromptRequested,
    required this.onApplyManualResponseRequested,
  });

  final PlanBuilderWalkthroughDraft initialDraft;
  final int initialStep;
  final String initialManualResponseText;
  final ValueChanged<PlanBuilderWalkthroughDraft> onDraftChanged;
  final ValueChanged<String> onManualResponseChanged;
  final ValueChanged<int> onStepChanged;
  final VoidCallback onCompleted;
  final Future<bool> Function() onSaveIntakeRequested;
  final Future<String?> Function() onBuildPromptRequested;
  final Future<bool> Function(String responseText)
      onApplyManualResponseRequested;

  @override
  State<PlanBuilderWalkthroughScreen> createState() =>
      _PlanBuilderWalkthroughScreenState();
}

class _PlanBuilderWalkthroughScreenState
    extends State<PlanBuilderWalkthroughScreen> {
  static const String _defaultPromptWorkspaceStatus =
      'Save your intake, build the prompt snapshot, and copy it into your AI workflow.';
  static const int _introStep = 0;
  static const int _goalStep = 1;
  static const int _experienceStep = 2;
  static const int _splitStep = 3;
  static const int _weeklySetupStep = 4;
  static const int _biometricsStep = 5;
  static const int _promptWorkspaceStep = 6;
  static const int _lastStep = _promptWorkspaceStep;

  late int _step;
  late PlanBuilderWalkthroughDraft _draft;
  late final TextEditingController _runDistanceController;
  late final TextEditingController _runPaceController;
  late final TextEditingController _shortTermGoalController;
  late final TextEditingController _shortTermGoalWeeksController;
  late final TextEditingController _scheduleConstraintsController;
  late final TextEditingController _additionalInstructionsController;
  late final TextEditingController _customPromptController;
  late final TextEditingController _manualAiResponseController;
  bool _savingIntake = false;
  bool _buildingPrompt = false;
  bool _manualApplying = false;
  String? _generatedPrompt;
  String _promptWorkspaceStatus = _defaultPromptWorkspaceStatus;
  _PromptWorkspaceView _promptWorkspaceView = _PromptWorkspaceView.response;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep.clamp(0, _lastStep);
    _draft = widget.initialDraft;
    _runDistanceController =
        TextEditingController(text: _draft.runDistanceMiles);
    _runPaceController = TextEditingController(text: _draft.runPace);
    _shortTermGoalController =
        TextEditingController(text: _draft.shortTermGoalText);
    _shortTermGoalWeeksController =
        TextEditingController(text: _draft.shortTermGoalWeeks);
    _scheduleConstraintsController =
        TextEditingController(text: _draft.scheduleConstraints);
    _additionalInstructionsController =
        TextEditingController(text: _draft.additionalInstructions);
    _customPromptController =
        TextEditingController(text: _draft.customPromptText);
    _manualAiResponseController =
        TextEditingController(text: widget.initialManualResponseText);
  }

  @override
  void dispose() {
    _runDistanceController.dispose();
    _runPaceController.dispose();
    _shortTermGoalController.dispose();
    _shortTermGoalWeeksController.dispose();
    _scheduleConstraintsController.dispose();
    _additionalInstructionsController.dispose();
    _customPromptController.dispose();
    _manualAiResponseController.dispose();
    super.dispose();
  }

  void _setStep(int step) {
    final clamped = step.clamp(0, _lastStep);
    if (_step == clamped) {
      return;
    }
    setState(() => _step = clamped);
    widget.onStepChanged(_step);
  }

  void _updateDraft(PlanBuilderWalkthroughDraft nextDraft) {
    setState(() {
      _draft = nextDraft;
      _generatedPrompt = null;
      _promptWorkspaceStatus = _defaultPromptWorkspaceStatus;
    });
    widget.onDraftChanged(nextDraft);
  }

  bool get _hasRunTarget =>
      _draft.runDistanceMiles.trim().isNotEmpty ||
      _draft.runPace.trim().isNotEmpty;

  void _updateRunGoalDraft({
    String? distanceMiles,
    String? pace,
  }) {
    final nextDistance = distanceMiles ?? _draft.runDistanceMiles;
    final nextPace = pace ?? _draft.runPace;
    _updateDraft(
      _draft.copyWith(
        runDistanceMiles: nextDistance,
        runPace: nextPace,
        runTargetEnabled:
            nextDistance.trim().isNotEmpty || nextPace.trim().isNotEmpty,
      ),
    );
  }

  String _runGoalSummaryText() {
    final distance = _draft.runDistanceMiles.trim();
    final pace = _draft.runPace.trim();
    if (distance.isEmpty && pace.isEmpty) {
      return 'Run goal';
    }
    if (distance.isEmpty) {
      return 'Run goal @ $pace';
    }
    final distanceLabel = '$distance miles';
    return pace.isEmpty ? distanceLabel : '$distanceLabel @ $pace';
  }

  void _goBack() {
    if (_step == _introStep) {
      Navigator.of(context).pop(false);
      return;
    }
    _setStep(_step - 1);
  }

  void _goNext() {
    if (_step == _lastStep) {
      _complete();
      return;
    }
    _setStep(_step + 1);
  }

  void _returnToPlan() {
    final completed = _step == _lastStep;
    if (completed) {
      widget.onCompleted();
    }
    Navigator.of(context).pop(completed);
  }

  void _complete() {
    widget.onCompleted();
    Navigator.of(context).pop(true);
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  ({int min, int max}) _splitTrainingDayRequirement(SplitType split) {
    return switch (split) {
      SplitType.runOnly => (min: 4, max: 7),
      SplitType.fullBody3d => (min: 3, max: 3),
      SplitType.upperLower4d => (min: 4, max: 4),
      SplitType.phul => (min: 4, max: 4),
      SplitType.ppl56d => (min: 5, max: 6),
      SplitType.hybridRunLift => (min: 5, max: 7),
      SplitType.arnold => (min: 6, max: 6),
      SplitType.broSplit => (min: 5, max: 5),
      SplitType.customHybrid => (min: 4, max: 7),
    };
  }

  String _splitRequirementText(SplitType split) {
    final requirement = _splitTrainingDayRequirement(split);
    if (requirement.min == requirement.max) {
      return 'Recommended: ${requirement.min} training day${requirement.min == 1 ? '' : 's'} per week.';
    }
    return 'Recommended: ${requirement.min}-${requirement.max} training days per week.';
  }

  String _splitRequiredDaysText(SplitType split) {
    final requirement = _splitTrainingDayRequirement(split);
    if (requirement.min == requirement.max) {
      return 'Split requirement: ${requirement.min} training day${requirement.min == 1 ? '' : 's'}.';
    }
    return 'Split requirement: ${requirement.min}-${requirement.max} training days.';
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

  bool _selectedWeekdaysMeetSplitRequirement() {
    final requirement = _splitTrainingDayRequirement(_draft.splitType);
    final count = _draft.trainingWeekdays.length;
    return count >= requirement.min && count <= requirement.max;
  }

  String _selectedWeekdaySummary() {
    if (_draft.trainingWeekdays.isEmpty) {
      return 'No weekdays selected.';
    }
    final selected = _draft.trainingWeekdays.toList()..sort();
    return selected.map(_weekdayLabel).join(', ');
  }

  InputDecoration _walkthroughDropdownDecoration(
    BuildContext context,
    String label,
  ) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
    );
  }

  Widget _buildIntroStep(BuildContext context) {
    final theme = Theme.of(context);
    final introBodyStyle = theme.textTheme.bodyMedium?.copyWith(
          height: 1.45,
          color: Colors.white,
        ) ??
        const TextStyle(
          height: 1.45,
          color: Colors.white,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROGRESSIVE OVERLOAD PLAN',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.all(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/icon.png',
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.28),
                          Colors.black.withValues(alpha: 0.62),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Text(
                    'Build Your Adaptive Edge',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: DefaultTextStyle(
            style: introBodyStyle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text:
                            'Progress doesn’t come from random hard workouts. It comes from ',
                      ),
                      TextSpan(
                        text: 'planned stress applied at the right time',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const TextSpan(
                        text:
                            '. That’s the science behind GAS — General Adaptation Syndrome — and it’s the backbone of how this app builds your training.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your body adapts to stress in three phases.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  const TextSpan(
                    children: [
                      TextSpan(
                        text: 'First is alarm. ',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text:
                            'You introduce a challenge your body isn’t fully prepared for yet: a heavier lift, an extra rep, a faster pace, a longer run. Muscles are stressed. The nervous system works harder. This isn’t damage — it’s a signal.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Next is resistance. ',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text:
                            'With proper recovery, your body doesn’t just return to baseline — it adapts above it. Muscles grow stronger, tendons become more resilient, aerobic capacity improves, and effort feels more controlled. This is where real progress happens.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    children: const [
                      TextSpan(
                        text: 'The final phase is exhaustion, ',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text:
                            'and smart training avoids living there. Too much stress without enough recovery leads to plateaus, fatigue, and injury. More is not better. ',
                      ),
                      TextSpan(
                        text: 'Better is better.',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'That’s why progressive overload must be intentional. Progress doesn’t always mean adding weight. It can mean more reps, better technique, improved pacing, or doing the same work with less effort. Sometimes the smartest move is holding steady so your body can fully adapt.',
                ),
                const SizedBox(height: 10),
                const Text(
                  'The planning session you’re about to go through is where this precision happens.',
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    children: const [
                      TextSpan(
                        text:
                            'By capturing your goals, experience, recovery capacity, and available equipment, the app builds a ',
                      ),
                      TextSpan(
                        text:
                            'progressive overload strategy tailored to your biology',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text:
                            '. Every session fits into a larger plan designed to apply just enough stress to trigger adaptation — without pushing you into exhaustion.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This isn’t guesswork. It’s structured adaptation.',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Train with the process your body already understands.\n'
                  'Let stress work for you.\n'
                  'Turn effort into lasting progress.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(text: 'Step 1 — Primary Goal'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey<String>('goal_${_draft.primaryGoal}'),
          initialValue: _draft.primaryGoal,
          dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          decoration: _walkthroughDropdownDecoration(context, 'Primary Goal'),
          items: const [
            DropdownMenuItem(
              value: PlanBuilderWalkthroughDraft.runGoal,
              child: Text('Run Goal'),
            ),
            DropdownMenuItem(
              value: PlanBuilderWalkthroughDraft.strengthGoal,
              child: Text('Strength Goal (Strength)'),
            ),
            DropdownMenuItem(
              value: PlanBuilderWalkthroughDraft.hypertrophyGoal,
              child: Text('Strength Goal (Hypertrophy)'),
            ),
            DropdownMenuItem(
              value: PlanBuilderWalkthroughDraft.cardioGoal,
              child: Text('Cardio Improvement'),
            ),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            _updateDraft(_draft.copyWith(primaryGoal: value));
          },
        ),
        const SizedBox(height: 8),
        const GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🏃‍♂️ Run Goal',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Best for athletes who want to run a specific distance or pace faster and more efficiently. '
                'Training prioritizes aerobic capacity, pacing control, fatigue resistance, and running economy '
                'while maintaining supportive strength work.',
              ),
              SizedBox(height: 10),
              Text(
                '🏋️ Strength Goal',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Best for athletes focused on increasing maximal strength and force production. '
                'Training emphasizes progressive loading, compound lifts, neural adaptation, and recovery '
                'to drive measurable strength gains.',
              ),
              SizedBox(height: 10),
              Text(
                '💪 Hypertrophy Goal',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Best for athletes whose primary goal is muscle size and physique development. '
                'Training focuses on volume, time under tension, targeted muscle fatigue, and sustainable '
                'progression for visible growth.',
              ),
              SizedBox(height: 10),
              Text(
                '❤️ Cardio Improvement',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Best for athletes who want better endurance, heart health, and work capacity without a specific '
                'race or pace target. Training improves aerobic efficiency, stamina, and overall conditioning.',
              ),
            ],
          ),
        ),
        if (_draft.isRunGoal) ...[
          const SizedBox(height: 10),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Run Target',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tell us exactly what you are training toward so the prompt can anchor the plan to a real outcome.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _runDistanceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Distance (miles) *',
                          hintText: 'Example: 5',
                        ),
                        onChanged: (value) =>
                            _updateRunGoalDraft(distanceMiles: value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _runPaceController,
                        decoration: const InputDecoration(
                          labelText: 'Target Pace (optional)',
                          hintText: 'Example: 8:00/mi',
                        ),
                        onChanged: (value) => _updateRunGoalDraft(pace: value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _hasRunTarget
                      ? 'Current target: ${_runGoalSummaryText()}'
                      : 'Example target: 5 miles @ 8:00/mi.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Short-Term Goal',
                style: Theme.of(context).textTheme.titleSmall,
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
                onChanged: (value) =>
                    _updateDraft(_draft.copyWith(shortTermGoalText: value)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _shortTermGoalWeeksController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Timeline (weeks)',
                  hintText: 'Example: 6',
                ),
                onChanged: (value) =>
                    _updateDraft(_draft.copyWith(shortTermGoalWeeks: value)),
              ),
              const SizedBox(height: 4),
              Text(
                'If short-term goal is entered, timeline is required (1-52).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(text: 'Step 2 — Experience Level'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey<String>('experience_${_draft.experienceLevel}'),
          initialValue: _draft.experienceLevel,
          dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          decoration:
              _walkthroughDropdownDecoration(context, 'Experience Level'),
          items: const [
            DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
            DropdownMenuItem(
                value: 'intermediate', child: Text('Intermediate')),
            DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            _updateDraft(_draft.copyWith(experienceLevel: value));
          },
        ),
        const SizedBox(height: 8),
        const GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🌱 Beginner',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Best for athletes who are new to structured training or returning after a long break. Workouts emphasize learning proper technique, building foundational strength, and developing consistent habits while allowing generous recovery between sessions.',
              ),
              SizedBox(height: 10),
              Text(
                '⚙️ Intermediate',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Best for athletes with consistent training experience who are ready for more structured progression. Training increases in volume and intensity, with more targeted programming designed to steadily improve strength, endurance, and performance.',
              ),
              SizedBox(height: 10),
              Text(
                '🚀 Advanced',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Best for highly experienced athletes who have already built a strong training base. Workouts use higher volume, specialized programming, and more precise progression strategies to continue driving performance and adaptation.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSplitStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(text: 'Step 3 - Split Selection'),
        const SizedBox(height: 8),
        DropdownButtonFormField<SplitType>(
          key: ValueKey<SplitType>(_draft.splitType),
          initialValue: _draft.splitType,
          dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          decoration:
              _walkthroughDropdownDecoration(context, 'Weekly Split Type'),
          items: SplitType.values
              .map(
                (split) => DropdownMenuItem<SplitType>(
                  value: split,
                  child: Text(split.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            _updateDraft(_draft.copyWith(splitType: value));
          },
        ),
        const SizedBox(height: 8),
        GlassCard(
          child: Text(_splitRequirementText(_draft.splitType)),
        ),
        const SizedBox(height: 8),
        const GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🏃 Run Only',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Best for athletes focused entirely on running performance or endurance development. Training emphasizes aerobic capacity, pacing control, interval work, and long-run progression with minimal or optional strength work.',
              ),
              SizedBox(height: 10),
              Text(
                '🏋️ Full Body (3d)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Best for beginners or athletes who want efficient strength training with fewer gym days. Each workout trains the entire body, allowing frequent stimulation of all major muscle groups while providing ample recovery between sessions.',
              ),
              SizedBox(height: 10),
              Text(
                '🔄 Upper / Lower (4d)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Best for balanced strength and muscle development with moderate training frequency. Upper body and lower body sessions alternate across the week, allowing higher volume per muscle group while maintaining recovery.',
              ),
              SizedBox(height: 10),
              Text(
                '⚙️ Push / Pull / Legs (5–6d)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Best for experienced lifters who want high training frequency and targeted muscle development. Workouts are divided by movement pattern—pushing muscles, pulling muscles, and lower body—allowing more volume and specialization.',
              ),
              SizedBox(height: 10),
              Text(
                '⚡ PHUL (Power Hypertrophy Upper Lower)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Best for athletes who want both strength and muscle growth. The week combines heavier “power” sessions with higher-volume hypertrophy sessions to stimulate multiple adaptation pathways.',
              ),
              SizedBox(height: 10),
              Text(
                '🦾 Arnold Split',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Best for advanced hypertrophy training with high weekly volume. Popularized by Arnold Schwarzenegger, this split pairs chest/back, shoulders/arms, and legs across six sessions to maximize muscle stimulus and frequency.',
              ),
              SizedBox(height: 10),
              Text(
                '💪 Bro Split',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Best for lifters who prefer high volume on one muscle group per day. Each session focuses intensely on a single body part (chest day, back day, leg day, etc.), allowing maximal local fatigue and recovery before the next session.',
              ),
              SizedBox(height: 10),
              Text(
                '🏃‍♂️🏋️ Hybrid Run + Lift',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Best for athletes who want to develop endurance and strength simultaneously. Running sessions are strategically paired with strength workouts so both systems improve without interfering with recovery.',
              ),
              SizedBox(height: 10),
              Text(
                '🧠 Custom Hybrid',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Best for athletes with unique schedules or specialized goals. The AI builds a flexible mix of running, strength, and recovery sessions tailored to your availability, equipment, and performance priorities.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySetupStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(text: 'Step 4 - Weekly Setup'),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _splitRequiredDaysText(_draft.splitType),
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
                  value: _draft.trainingWeekdays.contains(weekday),
                  title: Text(_weekdayLabel(weekday)),
                  onChanged: (selected) {
                    if (selected == null) {
                      return;
                    }
                    final nextWeekdays = <int>{..._draft.trainingWeekdays};
                    if (selected) {
                      nextWeekdays.add(weekday);
                    } else {
                      nextWeekdays.remove(weekday);
                    }
                    _updateDraft(
                      _draft.copyWith(trainingWeekdays: nextWeekdays),
                    );
                  },
                ),
              const SizedBox(height: 8),
              DropdownButtonFormField<WeeklyPlanModifier>(
                key: ValueKey<WeeklyPlanModifier>(_draft.weeklyModifier),
                initialValue: _draft.weeklyModifier,
                dropdownColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                decoration:
                    _walkthroughDropdownDecoration(context, 'Weekly Modifier'),
                items: WeeklyPlanModifier.values
                    .map(
                      (modifier) => DropdownMenuItem<WeeklyPlanModifier>(
                        value: modifier,
                        child: Text(modifier.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  _updateDraft(_draft.copyWith(weeklyModifier: value));
                },
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _draft.propagateLongTerm,
                title: const Text('Also update long-term expectations'),
                subtitle: const Text(
                  'Off by default. If enabled, 10-week expectations may be updated.',
                ),
                onChanged: (value) {
                  _updateDraft(_draft.copyWith(propagateLongTerm: value));
                },
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
                      selected: _draft.availableEquipment.contains(item),
                      onSelected: (_) => _toggleEquipment(item),
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
                      selected: _draft.contraindications.contains(item),
                      onSelected: (_) => _toggleContraindication(item),
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
                onChanged: (value) =>
                    _updateDraft(_draft.copyWith(scheduleConstraints: value)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _biometricsSummaryText() {
    final payload = BiometricsCalculator.computePromptPayloadFromMap(
      rawInput: _draft.biometrics,
      daysPerWeek: _draft.trainingWeekdays.length,
    );
    if (payload == null) {
      return 'Biometrics not configured yet.';
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
          initialBiometrics: _draft.biometrics,
          daysPerWeek: _draft.trainingWeekdays.length,
        ),
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    _updateDraft(_draft.copyWith(biometrics: result));
  }

  Future<void> _saveIntakeProfile() async {
    setState(() => _savingIntake = true);
    try {
      final saved = await widget.onSaveIntakeRequested();
      if (!mounted || !saved) {
        return;
      }
      setState(() {
        _promptWorkspaceStatus = 'Athlete intake saved for this profile.';
      });
    } finally {
      if (mounted) {
        setState(() => _savingIntake = false);
      }
    }
  }

  Future<void> _buildPromptSnapshot() async {
    setState(() => _buildingPrompt = true);
    try {
      final prompt = await widget.onBuildPromptRequested();
      if (!mounted || prompt == null || prompt.trim().isEmpty) {
        return;
      }
      setState(() {
        _generatedPrompt = prompt;
        _promptWorkspaceStatus =
            'Prompt snapshot generated. Copy it to the clipboard or return to plan.';
      });
    } finally {
      if (mounted) {
        setState(() => _buildingPrompt = false);
      }
    }
  }

  Future<void> _copyPromptToClipboard() async {
    final text = (_generatedPrompt ?? '').trim();
    if (text.isEmpty) {
      _showMessage('Build a prompt snapshot first.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    setState(() {
      _promptWorkspaceStatus = 'Prompt copied to clipboard.';
    });
    _showMessage('Prompt copied to clipboard.');
  }

  Future<void> _applyManualAiResponse() async {
    final text = _manualAiResponseController.text.trim();
    if (text.isEmpty) {
      _showMessage('Paste AI weekly plan text before applying.');
      return;
    }
    setState(() => _manualApplying = true);
    try {
      final applied = await widget.onApplyManualResponseRequested(text);
      if (!mounted) {
        return;
      }
      setState(() {
        _promptWorkspaceStatus = applied
            ? 'Manual AI weekly plan applied.'
            : 'Manual AI response was not applied.';
      });
      if (applied) {
        _showMessage('Manual AI weekly plan applied.');
      }
    } finally {
      if (mounted) {
        setState(() => _manualApplying = false);
      }
    }
  }

  DateTime get _weekEndDate =>
      _draft.weekStartDate.add(const Duration(days: 6));

  Future<void> _pickWeekStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _draft.weekStartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null) {
      return;
    }
    _updateDraft(_draft.copyWith(weekStartDate: selected));
  }

  void _toggleEquipment(String item) {
    final next = <String>{..._draft.availableEquipment};
    if (!next.add(item)) {
      next.remove(item);
    }
    _updateDraft(_draft.copyWith(availableEquipment: next));
  }

  void _toggleContraindication(String item) {
    final next = <String>{..._draft.contraindications};
    if (!next.add(item)) {
      next.remove(item);
    }
    _updateDraft(_draft.copyWith(contraindications: next));
  }

  Widget _buildBiometricsStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(text: 'Step 5 - Biometrics'),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add biometrics so AI can calibrate body-composition context and energy estimates for weekly + long-term planning.',
              ),
              const SizedBox(height: 8),
              Text(
                _biometricsSummaryText(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: PrimaryPillButton(
                  text: 'Open Biometric Profile',
                  icon: Icons.monitor_weight_outlined,
                  variant: PillButtonVariant.tonal,
                  onPressed: _openBiometricsEditor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromptWorkspaceStep(BuildContext context) {
    final theme = Theme.of(context);
    final biometricsReady = BiometricsCalculator.computePromptPayloadFromMap(
          rawInput: _draft.biometrics,
          daysPerWeek: _draft.trainingWeekdays.length,
        ) !=
        null;
    final goalSummary =
        _draft.isRunGoal ? _runGoalSummaryText() : _draft.primaryGoal;
    final shortTermSummary = _draft.shortTermGoalText.trim().isEmpty
        ? 'Not set'
        : _draft.shortTermGoalWeeks.trim().isEmpty
            ? _draft.shortTermGoalText.trim()
            : '${_draft.shortTermGoalText.trim()} (${_draft.shortTermGoalWeeks.trim()} weeks)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(text: 'Step 6 - Prompt Workspace'),
        const SizedBox(height: 8),
        const ClinicalBanner(
          text:
              'Lock in your intake, generate the weekly prompt snapshot, and copy it directly into your external AI workflow.',
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Walkthrough Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                      label:
                          Text('Week Start: ${toYmd(_draft.weekStartDate)}')),
                  Chip(label: Text('Week End: ${toYmd(_weekEndDate)}')),
                  Chip(label: Text('Goal: $goalSummary')),
                  Chip(label: Text('Short-term: $shortTermSummary')),
                  Chip(label: Text('Split: ${_draft.splitType.label}')),
                  Chip(
                    label: Text(
                      'Days: ${_draft.trainingWeekdays.length} selected',
                    ),
                  ),
                  Chip(
                    label: Text(
                      _draft.propagateLongTerm
                          ? '10-week: Update'
                          : '10-week: Keep current',
                    ),
                  ),
                  Chip(label: Text('Modifier: ${_draft.weeklyModifier.label}')),
                  Chip(
                    label: Text(
                      biometricsReady
                          ? 'Biometrics: Ready'
                          : 'Biometrics: Missing',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _promptWorkspaceStatus,
                style: theme.textTheme.bodySmall,
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
                'Week Window',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Week start: ${toYmd(_draft.weekStartDate)}\nWeek end: ${toYmd(_weekEndDate)}',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 150,
                    child: PrimaryPillButton(
                      text: 'Change Date',
                      variant: PillButtonVariant.outlined,
                      icon: Icons.calendar_today_outlined,
                      onPressed: _pickWeekStartDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _draft.propagateLongTerm,
                title: const Text('Also update long-term expectations'),
                subtitle: const Text(
                  'Enable this if you want the weekly AI output to also update 10-week expectations.',
                ),
                onChanged: (value) {
                  _updateDraft(_draft.copyWith(propagateLongTerm: value));
                },
              ),
              Text(
                'Building or copying the prompt does not update the 10-week plan by itself. Long-range changes happen when AI output is generated and applied with this setting enabled.',
                style: theme.textTheme.bodySmall,
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
                onChanged: (value) => _updateDraft(
                  _draft.copyWith(additionalInstructions: value),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _draft.useCustomPromptText,
                title: const Text('Use custom prompt text for this run'),
                subtitle: const Text(
                  'Enable to edit the raw prompt before building or copying.',
                ),
                onChanged: (value) {
                  _updateDraft(_draft.copyWith(useCustomPromptText: value));
                },
              ),
              if (_draft.useCustomPromptText) ...[
                const SizedBox(height: 6),
                TextField(
                  controller: _customPromptController,
                  minLines: 8,
                  maxLines: 14,
                  decoration: const InputDecoration(
                    labelText: 'Raw Prompt Override',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  onChanged: (value) =>
                      _updateDraft(_draft.copyWith(customPromptText: value)),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Use the same save/build flow from the main plan workspace.',
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: PrimaryPillButton(
                  text: _savingIntake ? 'Saving...' : 'Save Athlete Intake',
                  variant: PillButtonVariant.tonal,
                  icon: Icons.save_outlined,
                  onPressed: _savingIntake ? null : _saveIntakeProfile,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: PrimaryPillButton(
                  text: _buildingPrompt
                      ? 'Building Prompt...'
                      : 'Build Prompt Snapshot',
                  variant: PillButtonVariant.outlined,
                  icon: Icons.auto_awesome_outlined,
                  onPressed: _buildingPrompt ? null : _buildPromptSnapshot,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: PrimaryPillButton(
                  text: 'Copy Prompt',
                  variant: PillButtonVariant.outlined,
                  icon: Icons.copy_all_outlined,
                  onPressed:
                      _generatedPrompt == null ? null : _copyPromptToClipboard,
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
              SegmentedButton<_PromptWorkspaceView>(
                segments: const [
                  ButtonSegment<_PromptWorkspaceView>(
                    value: _PromptWorkspaceView.response,
                    label: Text('Response'),
                    icon: Icon(Icons.assignment_return_outlined),
                  ),
                  ButtonSegment<_PromptWorkspaceView>(
                    value: _PromptWorkspaceView.fullPrompt,
                    label: Text('Full Prompt'),
                    icon: Icon(Icons.description_outlined),
                  ),
                ],
                selected: {_promptWorkspaceView},
                onSelectionChanged: (selection) {
                  setState(() => _promptWorkspaceView = selection.first);
                },
              ),
              const SizedBox(height: 8),
              if (_promptWorkspaceView == _PromptWorkspaceView.response) ...[
                Text(
                  'Paste Weekly AI Plan Response Here.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _generatedPrompt == null
                      ? 'Build and copy the prompt, then paste the AI response back here.'
                      : 'Prompt ready. Paste the AI response here when it comes back.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _manualAiResponseController,
                  minLines: 8,
                  maxLines: 14,
                  decoration: const InputDecoration(
                    labelText: 'Paste Weekly AI Plan Response Here.',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                  onChanged: widget.onManualResponseChanged,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryPillButton(
                    text: _manualApplying
                        ? 'Applying...'
                        : 'Apply Pasted Weekly Plan Text',
                    variant: PillButtonVariant.tonal,
                    icon: Icons.playlist_add_check_circle_outlined,
                    onPressed: _manualApplying ? null : _applyManualAiResponse,
                  ),
                ),
              ] else ...[
                Text(
                  'Full Prompt',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _generatedPrompt == null
                      ? 'Build a prompt snapshot to preview the exact text before you return to the main plan screen.'
                      : 'Review or copy the full prompt text here.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 160),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: _generatedPrompt == null
                      ? Text(
                          'Build a prompt snapshot to preview the exact text before you return to the main plan screen.',
                          style: theme.textTheme.bodyMedium,
                        )
                      : SelectableText(
                          _generatedPrompt!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            height: 1.35,
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (_step) {
      case _introStep:
        return _buildIntroStep(context);
      case _goalStep:
        return _buildGoalStep(context);
      case _experienceStep:
        return _buildExperienceStep(context);
      case _splitStep:
        return _buildSplitStep(context);
      case _weeklySetupStep:
        return _buildWeeklySetupStep(context);
      case _biometricsStep:
        return _buildBiometricsStep(context);
      case _promptWorkspaceStep:
        return _buildPromptWorkspaceStep(context);
      default:
        return _buildIntroStep(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _step == _lastStep;
    final nextLabel = switch (_step) {
      _introStep => 'Start',
      _promptWorkspaceStep => 'Return To Plan',
      _ => 'Next',
    };

    return Theme(
      data: buildClinicalTheme(),
      child: Builder(
        builder: (themedContext) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Progressive Overload Walkthrough (${_step + 1}/7)'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              ),
              actions: [
                TextButton(
                  onPressed: _returnToPlan,
                  child: const Text('Return To Plan'),
                ),
              ],
            ),
            body: Stack(
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          ClinicalPalette.bgTop,
                          ClinicalPalette.bgMid,
                          ClinicalPalette.bgBottom,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.1, -0.95),
                        radius: 1.45,
                        colors: [
                          Colors.white.withValues(alpha: 0.06),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.30),
                        ],
                        stops: const [0, 0.55, 1],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    children: [
                      _buildCurrentStep(themedContext),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: PrimaryPillButton(
                      text: 'Back',
                      variant: PillButtonVariant.outlined,
                      onPressed: _goBack,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryPillButton(
                      text: nextLabel,
                      onPressed: isLastStep ? _complete : _goNext,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
