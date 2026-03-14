import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/parsing/exercise_normalizer.dart';
import '../../core/utils/app_providers.dart';
import '../../db/app_db.dart';
import '../ui/clinical_theme.dart';
import '../ui/clinical_widgets.dart';
import 'exercise_substitution_service.dart';

Map<int, String> _manualSegmentLabelsByIdx(String? rawMetricsJson) {
  if (rawMetricsJson == null || rawMetricsJson.trim().isEmpty) {
    return const <int, String>{};
  }
  try {
    final decoded = jsonDecode(rawMetricsJson);
    if (decoded is! Map) {
      return const <int, String>{};
    }
    final rawSegments = decoded['manual_segments'];
    if (rawSegments is! List) {
      return const <int, String>{};
    }

    final labels = <int, String>{};
    for (final segment in rawSegments) {
      if (segment is! Map) {
        continue;
      }
      final idx = int.tryParse('${segment['idx'] ?? ''}');
      if (idx == null) {
        continue;
      }
      final kind = '${segment['kind'] ?? ''}'.trim().toLowerCase();
      if (kind == 'rest') {
        labels[idx] = 'Rest';
      } else if (kind == 'interval') {
        labels[idx] = 'Interval';
      }
    }
    return labels;
  } catch (_) {
    return const <int, String>{};
  }
}

class WorkoutDayDetailScreen extends ConsumerStatefulWidget {
  const WorkoutDayDetailScreen({super.key, required this.date});

  final String date;

  @override
  ConsumerState<WorkoutDayDetailScreen> createState() =>
      _WorkoutDayDetailScreenState();
}

class _WorkoutDayDetailScreenState
    extends ConsumerState<WorkoutDayDetailScreen> {
  static const int _defaultRestSeconds = 90;

  late Future<WorkoutDayDetail> _detailFuture;
  final ScrollController _scrollController = ScrollController();
  final Map<String, _EditableSetState> _editedByKey =
      <String, _EditableSetState>{};
  final Set<String> _savingKeys = <String>{};
  final Set<String> _savingExercises = <String>{};
  final Map<String, bool> _expandedByExercise = <String, bool>{};
  final Map<String, GlobalKey> _cardKeysByExercise = <String, GlobalKey>{};
  bool _addingExercise = false;
  String? _pendingScrollExercise;
  int _tilesEpoch = 0;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  @override
  void didUpdateWidget(covariant WorkoutDayDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _editedByKey.clear();
      _savingKeys.clear();
      _expandedByExercise.clear();
      _pendingScrollExercise = null;
      _tilesEpoch = 0;
      _detailFuture = _loadDetail();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<WorkoutDayDetail> _loadDetail() {
    return ref.read(appDbProvider).getWorkoutDayDetail(widget.date);
  }

  void _refreshDetail() {
    setState(() {
      _tilesEpoch++;
      _detailFuture = _loadDetail();
    });
  }

  GlobalKey _cardKeyForExercise(String exercise) {
    return _cardKeysByExercise.putIfAbsent(exercise, () => GlobalKey());
  }

  void _scrollCardNearTop(String exercise) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final targetKey = _cardKeysByExercise[exercise];
      final targetContext = targetKey?.currentContext;
      if (targetContext == null) {
        return;
      }
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: 0.06,
      );
    });
  }

  String _sessionTypeLabel(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized.contains('push')) {
      return 'Push';
    }
    if (normalized.contains('pull')) {
      return 'Pull';
    }
    if (normalized.contains('leg')) {
      return 'Legs';
    }
    if (normalized.contains('rest')) {
      return 'Rest';
    }
    return 'Unknown';
  }

  String _setKey(String exercise, int setIndex) => '$exercise::$setIndex';

  bool _needsSetIndexNormalization(List<PlannedStrengthSetView> sets) {
    final seen = <int>{};
    for (final set in sets) {
      if (set.setIndex <= 0) {
        return true;
      }
      if (!seen.add(set.setIndex)) {
        return true;
      }
    }
    return false;
  }

  List<PlannedStrengthSetView> _effectivePrescribedSets(
      List<PlannedStrengthSetView> rawSets) {
    final sorted = [...rawSets]
      ..sort((a, b) => a.setIndex.compareTo(b.setIndex));
    if (!_needsSetIndexNormalization(sorted)) {
      return sorted;
    }
    var next = 1;
    return sorted
        .map(
          (s) => PlannedStrengthSetView(
            setIndex: next++,
            weight: s.weight,
            reps: s.reps,
            rir: s.rir,
            unit: s.unit,
          ),
        )
        .toList();
  }

  List<PlannedStrengthSetView> _editableSetsForGroup(ExerciseSetGroup group) {
    final prescribed = _effectivePrescribedSets(group.prescribed);
    if (prescribed.isNotEmpty) {
      return prescribed;
    }
    final actualSorted = [...group.actual]
      ..sort((a, b) => a.setIndex.compareTo(b.setIndex));
    if (actualSorted.isEmpty) {
      return const <PlannedStrengthSetView>[
        PlannedStrengthSetView(
          setIndex: 1,
          weight: 0,
          reps: 0,
          rir: 0,
          unit: 'lb',
        ),
      ];
    }
    return actualSorted
        .map(
          (set) => PlannedStrengthSetView(
            setIndex: set.setIndex,
            weight: set.weight ?? 0,
            reps: set.reps ?? 0,
            rir: set.rir ?? 0,
            unit: set.unit,
          ),
        )
        .toList();
  }

  void _ensureEditableRows(WorkoutDayDetail detail) {
    for (final group in detail.groups) {
      final sets = _editableSetsForGroup(group);
      for (final set in sets) {
        final key = _setKey(group.exercise, set.setIndex);
        _editedByKey.putIfAbsent(key, () {
          final unit = set.unit.toLowerCase();
          final bwLike = unit == 'bw' || unit == 'unknown';
          return _EditableSetState(
            weight: set.weight ?? (bwLike ? 0.0 : null),
            reps: set.reps,
            rir: set.rir,
          );
        });
      }
    }
  }

  Future<void> _addCustomExercise({
    required String exerciseCanonical,
    required int initialSetCount,
  }) async {
    setState(() => _addingExercise = true);
    try {
      final db = ref.read(appDbProvider);
      for (var setIndex = 1; setIndex <= initialSetCount; setIndex++) {
        await db.upsertActualStrengthSetForDate(
          dateYmd: widget.date,
          exerciseCanonical: exerciseCanonical,
          prescribedExerciseCanonical: exerciseCanonical,
          setIndex: setIndex,
          weight: 0,
          reps: 0,
          rir: 0,
          source: 'manual_custom_exercise',
        );
      }
      if (!mounted) {
        return;
      }
      _expandedByExercise[exerciseCanonical] = true;
      _pendingScrollExercise = exerciseCanonical;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added $exerciseCanonical with $initialSetCount set${initialSetCount == 1 ? '' : 's'}.',
          ),
        ),
      );
      _refreshDetail();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add exercise: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _addingExercise = false);
      }
    }
  }

  Future<void> _promptAddExercise(WorkoutDayDetail detail) async {
    final nameController = TextEditingController();
    final setsController = TextEditingController(text: '1');

    final draft = await showDialog<_AddExerciseDraft>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                hintText: 'Example: Kneeling Leg Curl',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: setsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Initial Set Count',
                hintText: '1-10',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              _AddExerciseDraft(
                exerciseName: nameController.text,
                initialSetCountRaw: setsController.text,
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (draft == null) {
      return;
    }
    final rawName = draft.exerciseName.trim();
    if (rawName.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise name is required.')),
      );
      return;
    }

    final initialSetCount = int.tryParse(draft.initialSetCountRaw.trim());
    if (initialSetCount == null ||
        initialSetCount < 1 ||
        initialSetCount > 10) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Initial set count must be between 1 and 10.')),
      );
      return;
    }

    final exerciseCanonical = ExerciseNormalizer.normalize(rawName);
    final exists = detail.groups.any((g) => g.exercise == exerciseCanonical);
    if (exists) {
      _expandedByExercise[exerciseCanonical] = true;
      _pendingScrollExercise = exerciseCanonical;
      _refreshDetail();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('$exerciseCanonical is already on this workout day.')),
      );
      return;
    }

    await _addCustomExercise(
      exerciseCanonical: exerciseCanonical,
      initialSetCount: initialSetCount,
    );
  }

  void _adjustWeight(String key, double delta) {
    final current = _editedByKey[key];
    if (current == null) {
      return;
    }
    final base = current.weight ?? 0.0;
    final next = (base + delta).clamp(0, 2000).toDouble();
    setState(() {
      _editedByKey[key] = current.copyWith(weight: next);
    });
  }

  void _adjustReps(String key, int delta) {
    final current = _editedByKey[key];
    if (current == null) {
      return;
    }
    final base = current.reps ?? 0;
    final next = (base + delta).clamp(0, 100);
    setState(() {
      _editedByKey[key] = current.copyWith(reps: next);
    });
  }

  void _adjustRir(String key, int delta) {
    final current = _editedByKey[key];
    if (current == null) {
      return;
    }
    final base = current.rir ?? 0;
    final next = (base + delta).clamp(0, 10);
    setState(() {
      _editedByKey[key] = current.copyWith(rir: next);
    });
  }

  String _formatWeight(double? value) {
    if (value == null) {
      return 'unset';
    }
    return value.toStringAsFixed(1);
  }

  int _resolveRestSecondsForSet({
    required ExerciseSetGroup group,
    required PlannedStrengthSetView set,
  }) {
    // TODO: Replace with AI-prescribed per-set rest when plan data stores it.
    return _defaultRestSeconds;
  }

  void _startRestCountdown(int seconds) {
    ref.read(restCountdownProvider.notifier).start(seconds);
  }

  void _dismissRestCountdown() {
    ref.read(restCountdownProvider.notifier).dismiss();
  }

  String _formatCountdown(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmActualSet({
    required String performedExerciseCanonical,
    required String prescribedExerciseCanonical,
    String? substitutionId,
    required PlannedStrengthSetView prescribed,
    required bool hadExistingActual,
    required String currentExercise,
    required String? nextExercise,
    required bool advanceCard,
    required int restSeconds,
  }) async {
    final key = _setKey(prescribedExerciseCanonical, prescribed.setIndex);
    final fallbackWeight = prescribed.weight ?? 0.0;
    final edited = _editedByKey[key] ??
        _EditableSetState(
          weight: fallbackWeight,
          reps: prescribed.reps,
          rir: prescribed.rir,
        );
    _editedByKey[key] = edited;

    setState(() => _savingKeys.add(key));
    try {
      await ref.read(appDbProvider).upsertActualStrengthSetForDate(
            dateYmd: widget.date,
            exerciseCanonical: performedExerciseCanonical,
            prescribedExerciseCanonical: prescribedExerciseCanonical,
            substitutionId: substitutionId,
            setIndex: prescribed.setIndex,
            weight: edited.weight,
            reps: edited.reps,
            rir: edited.rir,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hadExistingActual ? 'Actual set updated.' : 'Actual set logged.',
          ),
        ),
      );
      _startRestCountdown(restSeconds);
      final targetExercise = (advanceCard && nextExercise != null)
          ? nextExercise
          : currentExercise;
      if (advanceCard) {
        setState(() {
          _expandedByExercise[currentExercise] = false;
          if (nextExercise != null) {
            _expandedByExercise[nextExercise] = true;
          }
        });
      }
      _pendingScrollExercise = targetExercise;
      _refreshDetail();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log set: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _savingKeys.remove(key));
      }
    }
  }

  Future<void> _skipExercise({
    required String performedExerciseCanonical,
    required String prescribedExerciseCanonical,
    String? substitutionId,
    required List<PlannedStrengthSetView> prescribedSets,
  }) async {
    if (prescribedSets.isEmpty) {
      return;
    }
    setState(() => _savingExercises.add(prescribedExerciseCanonical));
    try {
      for (final set in prescribedSets) {
        await ref.read(appDbProvider).upsertActualStrengthSetForDate(
              dateYmd: widget.date,
              exerciseCanonical: performedExerciseCanonical,
              prescribedExerciseCanonical: prescribedExerciseCanonical,
              substitutionId: substitutionId,
              setIndex: set.setIndex,
              weight: 0,
              reps: 0,
              rir: 0,
              source: 'manual_skip',
            );
        final key = _setKey(prescribedExerciseCanonical, set.setIndex);
        final existing = _editedByKey[key];
        if (existing != null) {
          _editedByKey[key] = existing.copyWith(weight: 0, reps: 0, rir: 0);
        }
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Skipped $prescribedExerciseCanonical. Logged all sets as 0.',
          ),
        ),
      );
      _refreshDetail();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to skip exercise: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _savingExercises.remove(prescribedExerciseCanonical));
      }
    }
  }

  Future<void> _applyConvertedTargets(
    String prescribedExerciseCanonical,
    List<ConvertedSetTarget> converted,
  ) async {
    setState(() {
      for (final target in converted) {
        final key = _setKey(prescribedExerciseCanonical, target.setIndex);
        final current = _editedByKey[key];
        if (current == null) {
          continue;
        }
        _editedByKey[key] = current.copyWith(
          weight: target.suggestedWeight,
          setWeightToNull: target.suggestedWeight == null,
          reps: target.suggestedReps,
          rir: target.suggestedRir,
        );
      }
    });
  }

  Future<void> _clearSubstitutionForGroup(ExerciseSetGroup group) async {
    await ref.read(exerciseSubstitutionServiceProvider).clearSubstitution(
          dateYmd: widget.date,
          prescribedExerciseCanonical: group.exercise,
        );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cleared substitution for ${group.exercise}.')),
    );
    _refreshDetail();
  }

  Future<void> _openSubstitutionPicker({
    required WorkoutDayDetail detail,
    required ExerciseSetGroup group,
    required List<PlannedStrengthSetView> prescribedSets,
  }) async {
    final service = ref.read(exerciseSubstitutionServiceProvider);
    final settings = ref.read(settingsProvider);
    final suggestions = await service.suggestAlternatives(
      prescribedExerciseCanonical: group.exercise,
      prescribedSets: prescribedSets,
      planDayId: detail.planDayId,
      availableEquipment: settings.availableEquipment,
      contraindications: settings.movementContraindications,
    );
    if (!mounted) {
      return;
    }

    final result = await showModalBottomSheet<_SubstitutionSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) => _SubstitutionPickerSheet(
        prescribedExercise: group.exercise,
        currentSubstitute: group.substitution?.substituteExerciseCanonical,
        suggestions: suggestions,
      ),
    );
    if (result == null) {
      return;
    }
    if (result.clear) {
      await _clearSubstitutionForGroup(group);
      return;
    }

    final validation = await service.validateSelection(
      prescribedExerciseCanonical: group.exercise,
      substituteExerciseCanonical: result.substituteExerciseCanonical!,
      prescribedSets: prescribedSets,
      availableEquipment: settings.availableEquipment,
      contraindications: settings.movementContraindications,
      isCurated: result.isCurated,
    );
    final weak = validation.tier == SubstitutionTier.weak;
    if (weak && !result.warningAcknowledged) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Weak matches require warning acknowledgment.'),
        ),
      );
      return;
    }

    final converted = await service.convertPrescription(
      prescribedExerciseCanonical: group.exercise,
      substituteExerciseCanonical: result.substituteExerciseCanonical!,
      prescribedSets: prescribedSets,
    );
    await service.applySubstitution(
      dateYmd: widget.date,
      prescribedExerciseCanonical: group.exercise,
      substituteExerciseCanonical: result.substituteExerciseCanonical!,
      reasonCode: result.reasonCode,
      reasonNotes: result.reasonNotes,
      validation: validation,
      warningAcknowledged: result.warningAcknowledged,
    );
    await _applyConvertedTargets(group.exercise, converted);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Applied substitution: ${group.exercise} -> ${result.substituteExerciseCanonical}',
        ),
      ),
    );
    _refreshDetail();
  }

  Widget _buildRestCountdownOverlay(
    BuildContext context,
    RestCountdownState countdown,
  ) {
    final progress = countdown.totalSeconds == 0
        ? 0.0
        : countdown.remainingSeconds / countdown.totalSeconds;
    final done = countdown.remainingSeconds == 0;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Dismissible(
                key: ValueKey<String>(
                    'rest-countdown-${countdown.dismissibleEpoch}'),
                direction: DismissDirection.horizontal,
                onDismissed: (_) => _dismissRestCountdown(),
                child: GlassCard(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  tintColor: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.82),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rest',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatCountdown(countdown.remainingSeconds),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        done ? 'Rest complete' : 'Swipe to dismiss',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final restCountdown = ref.watch(restCountdownProvider);
    return Theme(
      data: buildClinicalTheme(),
      child: Scaffold(
        appBar: AppBar(title: Text('Workout Day Detail ${widget.date}')),
        body: Stack(
          children: [
            const Positioned.fill(child: _WorkoutDetailPageBackground()),
            FutureBuilder<WorkoutDayDetail>(
              future: _detailFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final detail = snapshot.data;
                if (detail == null) {
                  return const Center(child: Text('No detail found.'));
                }

                _ensureEditableRows(detail);
                final pendingScroll = _pendingScrollExercise;
                if (pendingScroll != null) {
                  _pendingScrollExercise = null;
                  _scrollCardNearTop(pendingScroll);
                }
                final splitHeaderTitle =
                    (detail.prescribedRun?.liftFocus ?? '').trim().isEmpty
                        ? 'Split'
                        : detail.prescribedRun!.liftFocus!.trim();
                final runHeaderTitle =
                    (detail.prescribedRun?.runType ?? '').trim().isEmpty
                        ? 'Runs'
                        : detail.prescribedRun!.runType!.trim();

                return ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  children: [
                    Text(
                      'WORKOUT DETAIL',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                letterSpacing: 1,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.date,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    SectionHeader(text: splitHeaderTitle),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Text(
                        detail.planDayNumber == null
                            ? 'No split day linked.'
                            : 'Split Day ${detail.planDayNumber} | Session Type: ${_sessionTypeLabel(detail.planSessionType)}',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SectionHeader(text: runHeaderTitle),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Text(
                        detail.prescribedRun?.runType == null
                            ? 'No prescribed run linked.'
                            : 'Prescribed Run: ${detail.prescribedRun?.runType} | '
                                'Duration: ${detail.prescribedRun?.durationText ?? 'unknown'} | '
                                'Pace: ${detail.prescribedRun?.targetPace ?? 'unknown'}',
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (detail.runSessions.isEmpty)
                      const GlassCard(child: Text('No runs for this date.'))
                    else
                      ...detail.runSessions.map(
                        (run) {
                          final segmentLabels = _manualSegmentLabelsByIdx(
                              run.session.rawMetricsJson);
                          return GlassCard(
                            child: ListTile(
                              title: Text(run.session.title ??
                                  run.session.activityType ??
                                  'Run'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'source=${run.session.source} | duration=${run.session.durationS ?? 'unknown'}s | '
                                    'distance=${run.session.distanceM ?? 'unknown'}m | avgHR=${run.session.avgHr ?? 'unknown'} | '
                                    'maxHR=${run.session.maxHr ?? 'unknown'}'
                                    '${run.overrodeManual ? ' | overrode manual' : ''}',
                                  ),
                                  if (run.segments.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Segments',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    ...run.segments.map(
                                      (segment) => Text(
                                        '${segmentLabels[segment.idx] ?? 'Segment'} ${segment.idx}: '
                                        '${segment.durationS ?? 'unknown'}s | '
                                        '${segment.distanceM ?? 'unknown'}m',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    SectionHeader(
                      text: 'Exercises',
                      trailing: FilledButton.tonal(
                        onPressed: _addingExercise
                            ? null
                            : () => _promptAddExercise(detail),
                        child: Text(
                            _addingExercise ? 'Adding...' : 'Add Exercise'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (detail.groups.isEmpty)
                      const GlassCard(
                          child: Text('No prescribed or actual sets.'))
                    else
                      ...detail.groups.asMap().entries.map((entry) {
                        final index = entry.key;
                        final group = entry.value;
                        final prescribedSets =
                            _effectivePrescribedSets(group.prescribed);
                        final editableSets = _editableSetsForGroup(group);
                        final normalizedSetIndexes =
                            _needsSetIndexNormalization(group.prescribed);
                        final actualSets = [...group.actual]
                          ..sort((a, b) => a.setIndex.compareTo(b.setIndex));
                        final isCustomExercise = group.prescribed.isEmpty;
                        final skippingExercise =
                            _savingExercises.contains(group.exercise);
                        final performedExercise =
                            group.substitution?.substituteExerciseCanonical ??
                                group.exercise;
                        final nextExercise = index < detail.groups.length - 1
                            ? detail.groups[index + 1].exercise
                            : null;

                        return GlassCard(
                          key: _cardKeyForExercise(group.exercise),
                          padding: EdgeInsets.zero,
                          child: ExpansionTile(
                            key: ValueKey<String>(
                              'exercise-${group.exercise}-$_tilesEpoch',
                            ),
                            initiallyExpanded:
                                _expandedByExercise[group.exercise] ?? false,
                            maintainState: true,
                            onExpansionChanged: (expanded) {
                              _expandedByExercise[group.exercise] = expanded;
                            },
                            title: Text(group.displayExercise),
                            subtitle: Text(
                              isCustomExercise
                                  ? 'Custom exercise | Sets: ${editableSets.length} | Actual: ${actualSets.length}'
                                  : group.substitution == null
                                      ? 'Prescribed: ${prescribedSets.length} | Actual: ${actualSets.length}'
                                      : 'Planned: ${group.exercise} | Actual: ${actualSets.length}',
                            ),
                            childrenPadding: const EdgeInsets.all(12),
                            children: [
                              if (group.substitution != null) ...[
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .tertiaryContainer
                                        .withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Substitution active: ${group.exercise} -> ${group.substitution!.substituteExerciseCanonical}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Reason: ${group.substitution!.reasonCode}'
                                        '${group.substitution!.matchScore == null ? '' : ' | Match ${(group.substitution!.matchScore!).round()}/100'}',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  isCustomExercise
                                      ? 'Adjust and Update Actual'
                                      : group.substitution == null
                                          ? 'Adjust Prescribed and Confirm as Actual'
                                          : 'Adjusted for substitute; confirm as actual',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (prescribedSets.isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    FilledButton.tonal(
                                      onPressed: () => _openSubstitutionPicker(
                                        detail: detail,
                                        group: group,
                                        prescribedSets: prescribedSets,
                                      ),
                                      child: const Text('Substitute Exercise'),
                                    ),
                                    if (group.substitution != null)
                                      OutlinedButton(
                                        onPressed: () =>
                                            _clearSubstitutionForGroup(group),
                                        child: const Text('Clear'),
                                      ),
                                    FilledButton.tonal(
                                      onPressed: skippingExercise
                                          ? null
                                          : () => _skipExercise(
                                                performedExerciseCanonical:
                                                    performedExercise,
                                                prescribedExerciseCanonical:
                                                    group.exercise,
                                                substitutionId:
                                                    group.substitution?.id,
                                                prescribedSets: prescribedSets,
                                              ),
                                      child:
                                          const Text('Skip Exercise (log 0)'),
                                    ),
                                  ],
                                ),
                              if (skippingExercise) ...[
                                const SizedBox(height: 6),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('Logging all sets as 0...'),
                                ),
                              ],
                              const SizedBox(height: 8),
                              if (!isCustomExercise &&
                                  normalizedSetIndexes) ...[
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Set indexes were normalized for this exercise.',
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              ...editableSets.asMap().entries.map((setEntry) {
                                final set = setEntry.value;
                                final isLastSet =
                                    setEntry.key == editableSets.length - 1;
                                final key =
                                    _setKey(group.exercise, set.setIndex);
                                final edited = _editedByKey[key]!;
                                final hasExistingActual = actualSets
                                    .any((a) => a.setIndex == set.setIndex);
                                final saving = _savingKeys.contains(key);

                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Set ${set.setIndex}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 8),
                                          if (hasExistingActual)
                                            const Chip(
                                              label: Text(
                                                  'Will overwrite existing actual'),
                                            ),
                                        ],
                                      ),
                                      _AdjustRow(
                                        label: 'Weight (lb)',
                                        value: _formatWeight(edited.weight),
                                        onMinus: () => _adjustWeight(key, -2.5),
                                        onPlus: () => _adjustWeight(key, 2.5),
                                      ),
                                      _AdjustRow(
                                        label: 'Reps',
                                        value:
                                            edited.reps?.toString() ?? 'unset',
                                        onMinus: () => _adjustReps(key, -1),
                                        onPlus: () => _adjustReps(key, 1),
                                      ),
                                      _AdjustRow(
                                        label: 'RIR',
                                        value:
                                            edited.rir?.toString() ?? 'unset',
                                        onMinus: () => _adjustRir(key, -1),
                                        onPlus: () => _adjustRir(key, 1),
                                      ),
                                      const SizedBox(height: 4),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: FilledButton.tonal(
                                          key: ValueKey<String>(
                                            'confirm-actual-${group.exercise}-${set.setIndex}',
                                          ),
                                          onPressed: saving
                                              ? null
                                              : () => _confirmActualSet(
                                                    performedExerciseCanonical:
                                                        performedExercise,
                                                    prescribedExerciseCanonical:
                                                        group.exercise,
                                                    substitutionId:
                                                        group.substitution?.id,
                                                    prescribed: set,
                                                    hadExistingActual:
                                                        hasExistingActual,
                                                    currentExercise:
                                                        group.exercise,
                                                    nextExercise: isLastSet
                                                        ? nextExercise
                                                        : null,
                                                    advanceCard: isLastSet,
                                                    restSeconds:
                                                        _resolveRestSecondsForSet(
                                                      group: group,
                                                      set: set,
                                                    ),
                                                  ),
                                          child: Text(
                                            hasExistingActual
                                                ? 'Update Actual'
                                                : 'Confirm as Actual',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Actual',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (actualSets.isEmpty)
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('none'),
                                )
                              else
                                ...actualSets.map(
                                  (s) => Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Set ${s.setIndex}: ${s.weight ?? 'unknown'}x${s.reps ?? 'unknown'}r${s.rir ?? 'unknown'} ${s.unit}'
                                      '${s.exerciseCanonical != group.exercise ? ' (${s.exerciseCanonical})' : ''}',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 16),
                    const SectionHeader(text: 'Audit'),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rule Triggers',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (detail.ruleTriggers.isEmpty)
                            const Text('none')
                          else
                            ...detail.ruleTriggers.map(
                              (r) => Text(
                                '${r.triggerDate} | ${r.ruleCode} | triggered=${r.triggered} | ${r.detailsJson}',
                              ),
                            ),
                          const SizedBox(height: 12),
                          const Text(
                            'Run Override Audit',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (detail.runOverrideAudits.isEmpty)
                            const Text('none')
                          else
                            ...detail.runOverrideAudits.map(
                              (a) => Text(
                                '${a.runKey} | ${a.oldSource} -> ${a.newSource} | ${a.reason}',
                              ),
                            ),
                          const SizedBox(height: 12),
                          const Text(
                            'AI Audit Entries',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (detail.aiAudits.isEmpty)
                            const Text('none')
                          else
                            ...detail.aiAudits.map(
                              (a) => Text(
                                const JsonEncoder.withIndent('  ').convert(
                                  jsonDecode(a.responseJson)
                                      as Map<String, dynamic>,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            if (restCountdown.visible)
              _buildRestCountdownOverlay(context, restCountdown),
          ],
        ),
      ),
    );
  }
}

class _SubstitutionSelectionResult {
  const _SubstitutionSelectionResult({
    this.substituteExerciseCanonical,
    this.reasonCode = 'preference',
    this.reasonNotes,
    this.warningAcknowledged = false,
    this.isCurated = false,
    this.clear = false,
  });

  final String? substituteExerciseCanonical;
  final String reasonCode;
  final String? reasonNotes;
  final bool warningAcknowledged;
  final bool isCurated;
  final bool clear;
}

class _AddExerciseDraft {
  const _AddExerciseDraft({
    required this.exerciseName,
    required this.initialSetCountRaw,
  });

  final String exerciseName;
  final String initialSetCountRaw;
}

class _WorkoutDetailPageBackground extends StatelessWidget {
  const _WorkoutDetailPageBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.1, -0.92),
            radius: 1.35,
            colors: [
              Colors.white.withValues(alpha: 0.05),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.24),
            ],
            stops: const [0, 0.58, 1],
          ),
        ),
      ),
    );
  }
}

class _SubstitutionPickerSheet extends StatefulWidget {
  const _SubstitutionPickerSheet({
    required this.prescribedExercise,
    required this.currentSubstitute,
    required this.suggestions,
  });

  final String prescribedExercise;
  final String? currentSubstitute;
  final List<SubstitutionCandidate> suggestions;

  @override
  State<_SubstitutionPickerSheet> createState() =>
      _SubstitutionPickerSheetState();
}

class _SubstitutionPickerSheetState extends State<_SubstitutionPickerSheet> {
  String _query = '';
  String? _selectedExercise;
  String _reasonCode = 'preference';
  bool _warningAcknowledged = false;
  final TextEditingController _reasonNotesController = TextEditingController();

  @override
  void dispose() {
    _reasonNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sheetTheme = buildClinicalTheme();
    final queryRaw = _query.trim().toLowerCase();
    final normalizedQuery = queryRaw.isEmpty
        ? ''
        : ExerciseNormalizer.normalize(queryRaw).toLowerCase();
    final filtered = widget.suggestions.where((c) {
      if (queryRaw.isEmpty) {
        return true;
      }
      final name = c.exerciseCanonical.toLowerCase();
      return name.contains(queryRaw) || name.contains(normalizedQuery);
    }).toList();
    SubstitutionCandidate? selectedCandidate;
    final selectedKey = _selectedExercise;
    if (selectedKey != null) {
      for (final c in widget.suggestions) {
        if (c.exerciseCanonical == selectedKey) {
          selectedCandidate = c;
          break;
        }
      }
    }
    selectedCandidate ??= filtered.isEmpty ? null : filtered.first;
    final selectedIsWeak = selectedCandidate?.tier == SubstitutionTier.weak;

    return Theme(
      data: sheetTheme,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 8,
            bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: GlassCard(
            radius: 22,
            padding: const EdgeInsets.all(14),
            tintColor: sheetTheme.colorScheme.surface.withValues(alpha: 0.72),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Substitute ${widget.prescribedExercise}',
                  style: sheetTheme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    labelText: 'Search alternatives',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          sheetTheme.colorScheme.outline.withValues(alpha: 0.9),
                    ),
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                  child: SizedBox(
                    height: 320,
                    child: filtered.isEmpty
                        ? const Center(child: Text('No suggestions found.'))
                        : RadioGroup<String>(
                            groupValue: _selectedExercise,
                            onChanged: (value) => setState(() {
                              _selectedExercise = value;
                              _warningAcknowledged = false;
                            }),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final c = filtered[index];
                                return RadioListTile<String>(
                                  value: c.exerciseCanonical,
                                  title: Text(c.exerciseCanonical),
                                  subtitle: Text(
                                    '${_tierLabel(c.tier)} • ${c.score.round()}/100'
                                    '${c.isCurated ? ' • curated' : ''}'
                                    '${c.warnings.isEmpty ? '' : '\n${c.warnings.join('; ')}'}',
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _reasonCode,
                  items: const [
                    DropdownMenuItem(
                        value: 'equipment_unavailable',
                        child: Text('Equipment unavailable')),
                    DropdownMenuItem(value: 'pain', child: Text('Pain')),
                    DropdownMenuItem(
                        value: 'machine_busy', child: Text('Machine busy')),
                    DropdownMenuItem(
                        value: 'preference', child: Text('Preference')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) =>
                      setState(() => _reasonCode = v ?? 'preference'),
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reasonNotesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                ),
                if (selectedCandidate != null) ...[
                  const SizedBox(height: 8),
                  if (selectedCandidate.warnings.isNotEmpty)
                    Text(
                      'Warnings: ${selectedCandidate.warnings.join(' | ')}',
                      style: TextStyle(color: sheetTheme.colorScheme.error),
                    ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _warningAcknowledged || !selectedIsWeak,
                    onChanged: selectedIsWeak
                        ? (v) =>
                            setState(() => _warningAcknowledged = v ?? false)
                        : null,
                    title: const Text(
                      'Acknowledge warning (required for weak match)',
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    if (widget.currentSubstitute != null)
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(
                          const _SubstitutionSelectionResult(clear: true),
                        ),
                        child: const Text('Clear Current'),
                      ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: _selectedExercise == null
                          ? null
                          : () {
                              final selected = widget.suggestions.firstWhere(
                                (c) => c.exerciseCanonical == _selectedExercise,
                              );
                              Navigator.of(context).pop(
                                _SubstitutionSelectionResult(
                                  substituteExerciseCanonical:
                                      _selectedExercise,
                                  reasonCode: _reasonCode,
                                  reasonNotes:
                                      _reasonNotesController.text.trim(),
                                  warningAcknowledged:
                                      _warningAcknowledged || !selectedIsWeak,
                                  isCurated: selected.isCurated,
                                ),
                              );
                            },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _tierLabel(SubstitutionTier tier) {
    switch (tier) {
      case SubstitutionTier.strong:
        return 'Strong';
      case SubstitutionTier.acceptable:
        return 'Acceptable';
      case SubstitutionTier.weak:
        return 'Weak';
    }
  }
}

class _EditableSetState {
  const _EditableSetState({
    required this.weight,
    required this.reps,
    required this.rir,
  });

  final double? weight;
  final int? reps;
  final int? rir;

  _EditableSetState copyWith({
    double? weight,
    bool setWeightToNull = false,
    int? reps,
    int? rir,
  }) {
    return _EditableSetState(
      weight: setWeightToNull ? null : (weight ?? this.weight),
      reps: reps ?? this.reps,
      rir: rir ?? this.rir,
    );
  }
}

class _AdjustRow extends StatelessWidget {
  const _AdjustRow({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text('$label: $value')),
        IconButton(
          onPressed: onMinus,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        IconButton(
          onPressed: onPlus,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
