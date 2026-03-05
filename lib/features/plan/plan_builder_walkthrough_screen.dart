import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui/clinical_theme.dart';
import '../ui/clinical_widgets.dart';
import 'weekly_planner_service.dart';

class PlanBuilderWalkthroughDraft {
  const PlanBuilderWalkthroughDraft({
    required this.primaryGoal,
    required this.runTargetEnabled,
    required this.runDistanceMiles,
    required this.runPace,
    required this.experienceLevel,
    required this.splitType,
  });

  static const String runGoal = 'run_goal';
  static const String strengthGoal = 'strength';
  static const String hypertrophyGoal = 'hypertrophy';
  static const String cardioGoal = 'cardio_improvement';

  final String primaryGoal;
  final bool runTargetEnabled;
  final String runDistanceMiles;
  final String runPace;
  final String experienceLevel;
  final SplitType splitType;

  bool get isRunGoal => primaryGoal == runGoal;

  PlanBuilderWalkthroughDraft copyWith({
    String? primaryGoal,
    bool? runTargetEnabled,
    String? runDistanceMiles,
    String? runPace,
    String? experienceLevel,
    SplitType? splitType,
  }) {
    return PlanBuilderWalkthroughDraft(
      primaryGoal: primaryGoal ?? this.primaryGoal,
      runTargetEnabled: runTargetEnabled ?? this.runTargetEnabled,
      runDistanceMiles: runDistanceMiles ?? this.runDistanceMiles,
      runPace: runPace ?? this.runPace,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      splitType: splitType ?? this.splitType,
    );
  }
}

class PlanBuilderWalkthroughScreen extends StatefulWidget {
  const PlanBuilderWalkthroughScreen({
    super.key,
    required this.initialDraft,
    required this.initialStep,
    required this.onDraftChanged,
    required this.onStepChanged,
    required this.onCompleted,
  });

  final PlanBuilderWalkthroughDraft initialDraft;
  final int initialStep;
  final ValueChanged<PlanBuilderWalkthroughDraft> onDraftChanged;
  final ValueChanged<int> onStepChanged;
  final VoidCallback onCompleted;

  @override
  State<PlanBuilderWalkthroughScreen> createState() =>
      _PlanBuilderWalkthroughScreenState();
}

class _PlanBuilderWalkthroughScreenState
    extends State<PlanBuilderWalkthroughScreen> {
  static const int _introStep = 0;
  static const int _goalStep = 1;
  static const int _experienceStep = 2;
  static const int _splitStep = 3;
  static const int _lastStep = _splitStep;

  late int _step;
  late PlanBuilderWalkthroughDraft _draft;
  late final TextEditingController _runDistanceController;
  late final TextEditingController _runPaceController;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep.clamp(0, _lastStep);
    _draft = widget.initialDraft;
    _runDistanceController =
        TextEditingController(text: _draft.runDistanceMiles);
    _runPaceController = TextEditingController(text: _draft.runPace);
  }

  @override
  void dispose() {
    _runDistanceController.dispose();
    _runPaceController.dispose();
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
    setState(() => _draft = nextDraft);
    widget.onDraftChanged(nextDraft);
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

  String _splitRequirementText(SplitType split) {
    final requirement = switch (split) {
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
    if (requirement.min == requirement.max) {
      return 'Recommended: ${requirement.min} training day${requirement.min == 1 ? '' : 's'} per week.';
    }
    return 'Recommended: ${requirement.min}-${requirement.max} training days per week.';
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
                            '. That’s the science behind GAS — General Adaptation Syndrome — and it’s the  of how this app builds your training.',
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
          const Text('Do you have a running distance or pace target?'),
          const SizedBox(height: 6),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(value: true, label: Text('Yes')),
              ButtonSegment<bool>(value: false, label: Text('Not yet')),
            ],
            selected: {_draft.runTargetEnabled},
            onSelectionChanged: (selection) {
              _updateDraft(_draft.copyWith(runTargetEnabled: selection.first));
            },
          ),
          if (_draft.runTargetEnabled) ...[
            const SizedBox(height: 8),
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
                      labelText: 'Distance (miles)',
                      hintText: 'Example: 5',
                    ),
                    onChanged: (value) =>
                        _updateDraft(_draft.copyWith(runDistanceMiles: value)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _runPaceController,
                    decoration: const InputDecoration(
                      labelText: 'Target Pace',
                      hintText: 'Example: 9:15-9:10/mi',
                    ),
                    onChanged: (value) =>
                        _updateDraft(_draft.copyWith(runPace: value)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildExperienceStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(text: 'Step 2 — Experience Level'),
        const SizedBox(height: 8),
        const GlassCard(
          child: Text(
            'Beginner: New to structured training or inconsistent recently.\n'
            'Intermediate: Training consistently with good movement basics.\n'
            'Advanced: Long consistent history and strong recovery habits.',
          ),
        ),
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
      ],
    );
  }

  Widget _buildSplitStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(text: 'Step 3 — Split Selection'),
        const SizedBox(height: 8),
        const GlassCard(
          child: Text(
            'Split selection controls how training stress is distributed through the week, and helps balance progression with recovery.',
          ),
        ),
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
          child: Text(
            'Run Only: cardio-focused blocks.\n'
            'Full Body / Upper-Lower / PHUL: great for structured progression and recovery.\n'
            'PPL / Arnold / Bro Split: higher-volume lifting frequency.\n'
            'Hybrid Run+Lift / Custom Hybrid: combine quality running with strength work.',
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
      default:
        return _buildIntroStep(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _step == _lastStep;
    final nextLabel = switch (_step) {
      _introStep => 'Start',
      _splitStep => 'Return To Plan',
      _ => 'Next',
    };

    return Theme(
      data: buildClinicalTheme(),
      child: Builder(
        builder: (themedContext) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Progressive Overload Walkthrough (${_step + 1}/4)'),
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
