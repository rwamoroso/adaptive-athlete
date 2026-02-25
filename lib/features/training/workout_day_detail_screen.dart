import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_providers.dart';
import '../../db/app_db.dart';
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
  late Future<WorkoutDayDetail> _detailFuture;
  final ScrollController _scrollController = ScrollController();
  final Map<String, _EditableSetState> _editedByKey =
      <String, _EditableSetState>{};
  final Set<String> _savingKeys = <String>{};
  final Set<String> _savingExercises = <String>{};
  final Map<String, bool> _expandedByExercise = <String, bool>{};
  final Map<String, GlobalKey> _cardKeysByExercise = <String, GlobalKey>{};
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

  String? _goalTitle(WorkoutDayDetail detail) {
    final liftFocus = detail.prescribedRun?.liftFocus?.trim();
    if (liftFocus != null && liftFocus.isNotEmpty) {
      return liftFocus;
    }
    final dayLabel = detail.prescribedRun?.dayLabel?.trim();
    if (dayLabel != null && dayLabel.isNotEmpty) {
      return dayLabel;
    }
    return null;
  }

  String _setKey(String exercise, int setIndex) => '$exercise::$setIndex';

  void _ensureEditableRows(WorkoutDayDetail detail) {
    for (final group in detail.groups) {
      for (final set in group.prescribed) {
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

  Future<void> _confirmActualSet({
    required String performedExerciseCanonical,
    required String prescribedExerciseCanonical,
    String? substitutionId,
    required PlannedStrengthSetView prescribed,
    required bool hadExistingActual,
    required String currentExercise,
    required String? nextExercise,
    required bool advanceCard,
  }) async {
    final key = _setKey(prescribedExerciseCanonical, prescribed.setIndex);
    final edited = _editedByKey[key];
    if (edited == null) {
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Workout Day Detail ${widget.date}')),
      body: FutureBuilder<WorkoutDayDetail>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Workout detail failed to load.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(snapshot.error.toString()),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _refreshDetail,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
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

          return ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Text('Split', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    detail.planDayNumber == null
                        ? 'No split day linked.'
                        : 'Split Day ${detail.planDayNumber} | ${_goalTitle(detail) ?? _sessionTypeLabel(detail.planSessionType)}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Runs', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    detail.prescribedRun?.runType == null
                        ? 'No prescribed run linked.'
                        : 'Prescribed Run: ${detail.prescribedRun?.runType} | '
                            'Duration: ${detail.prescribedRun?.durationText ?? 'unknown'} | '
                            'Pace: ${detail.prescribedRun?.targetPace ?? 'unknown'}',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (detail.runSessions.isEmpty)
                const Card(
                    child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No runs for this date.'),
                ))
              else
                ...detail.runSessions.map(
                  (run) {
                    final segmentLabels =
                        _manualSegmentLabelsByIdx(run.session.rawMetricsJson);
                    return Card(
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
                                style: TextStyle(fontWeight: FontWeight.bold),
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
              Text('Exercises', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (detail.groups.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No prescribed or actual sets.'),
                  ),
                )
              else
                ...detail.groups.asMap().entries.map((entry) {
                  final index = entry.key;
                  final group = entry.value;
                  final prescribedSets = [...group.prescribed]
                    ..sort((a, b) => a.setIndex.compareTo(b.setIndex));
                  final actualSets = [...group.actual]
                    ..sort((a, b) => a.setIndex.compareTo(b.setIndex));
                  final skippingExercise =
                      _savingExercises.contains(group.exercise);
                  final performedExercise =
                      group.substitution?.substituteExerciseCanonical ??
                          group.exercise;
                  final nextExercise = index < detail.groups.length - 1
                      ? detail.groups[index + 1].exercise
                      : null;

                  return Card(
                    key: _cardKeyForExercise(group.exercise),
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
                        group.substitution == null
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
                                  .withOpacity(0.35),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                            group.substitution == null
                                ? 'Adjust Prescribed and Confirm as Actual'
                                : 'Adjusted for substitute; confirm as actual',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.tonal(
                              onPressed: prescribedSets.isEmpty
                                  ? null
                                  : () => _openSubstitutionPicker(
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
                              onPressed: skippingExercise ||
                                      prescribedSets.isEmpty
                                  ? null
                                  : () => _skipExercise(
                                        performedExerciseCanonical:
                                            performedExercise,
                                        prescribedExerciseCanonical:
                                            group.exercise,
                                        substitutionId: group.substitution?.id,
                                        prescribedSets: prescribedSets,
                                      ),
                              child: const Text('Skip Exercise (log 0)'),
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
                        if (prescribedSets.isEmpty)
                          const Align(
                            alignment: Alignment.centerLeft,
                            child:
                                Text('No prescribed sets for this exercise.'),
                          )
                        else
                          ...prescribedSets.asMap().entries.map((setEntry) {
                            final set = setEntry.value;
                            final isLastSet =
                                setEntry.key == prescribedSets.length - 1;
                            final key = _setKey(group.exercise, set.setIndex);
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
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    value: edited.reps?.toString() ?? 'unset',
                                    onMinus: () => _adjustReps(key, -1),
                                    onPlus: () => _adjustReps(key, 1),
                                  ),
                                  _AdjustRow(
                                    label: 'RIR',
                                    value: edited.rir?.toString() ?? 'unset',
                                    onMinus: () => _adjustRir(key, -1),
                                    onPlus: () => _adjustRir(key, 1),
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: FilledButton.tonal(
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
                                                currentExercise: group.exercise,
                                                nextExercise: isLastSet
                                                    ? nextExercise
                                                    : null,
                                                advanceCard: isLastSet,
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
              Text('Audit', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
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
              ),
            ],
          );
        },
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
    final filtered = widget.suggestions
        .where((c) => _query.trim().isEmpty
            ? true
            : c.exerciseCanonical.toLowerCase().contains(_query.toLowerCase()))
        .toList();
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

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Substitute ${widget.prescribedExercise}',
              style: Theme.of(context).textTheme.titleLarge,
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
            SizedBox(
              height: 320,
              child: filtered.isEmpty
                  ? const Center(child: Text('No suggestions found.'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final c = filtered[index];
                        return RadioListTile<String>(
                          value: c.exerciseCanonical,
                          groupValue: _selectedExercise,
                          onChanged: (v) => setState(() {
                            _selectedExercise = v;
                            _warningAcknowledged = false;
                          }),
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
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _reasonCode,
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
              onChanged: (v) => setState(() => _reasonCode = v ?? 'preference'),
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
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _warningAcknowledged || !selectedIsWeak,
                onChanged: selectedIsWeak
                    ? (v) => setState(() => _warningAcknowledged = v ?? false)
                    : null,
                title:
                    const Text('Acknowledge warning (required for weak match)'),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (widget.currentSubstitute != null)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(
                      const _SubstitutionSelectionResult(clear: true),
                    ),
                    child: const Text('Clear Current'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _selectedExercise == null
                      ? null
                      : () {
                          final selected = widget.suggestions.firstWhere(
                            (c) => c.exerciseCanonical == _selectedExercise,
                          );
                          Navigator.of(context).pop(
                            _SubstitutionSelectionResult(
                              substituteExerciseCanonical: _selectedExercise,
                              reasonCode: _reasonCode,
                              reasonNotes: _reasonNotesController.text.trim(),
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
