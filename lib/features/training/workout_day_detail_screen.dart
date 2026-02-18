import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_providers.dart';
import '../../db/app_db.dart';

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
    required String exerciseCanonical,
    required PlannedStrengthSetView prescribed,
    required bool hadExistingActual,
    required String currentExercise,
    required String? nextExercise,
    required bool advanceCard,
  }) async {
    final key = _setKey(exerciseCanonical, prescribed.setIndex);
    final edited = _editedByKey[key];
    if (edited == null) {
      return;
    }

    setState(() => _savingKeys.add(key));
    try {
      await ref.read(appDbProvider).upsertActualStrengthSetForDate(
            dateYmd: widget.date,
            exerciseCanonical: exerciseCanonical,
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
    required String exerciseCanonical,
    required List<PlannedStrengthSetView> prescribedSets,
  }) async {
    if (prescribedSets.isEmpty) {
      return;
    }
    setState(() => _savingExercises.add(exerciseCanonical));
    try {
      for (final set in prescribedSets) {
        await ref.read(appDbProvider).upsertActualStrengthSetForDate(
              dateYmd: widget.date,
              exerciseCanonical: exerciseCanonical,
              setIndex: set.setIndex,
              weight: 0,
              reps: 0,
              rir: 0,
              source: 'manual_skip',
            );
        final key = _setKey(exerciseCanonical, set.setIndex);
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
          content: Text('Skipped $exerciseCanonical. Logged all sets as 0.'),
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
        setState(() => _savingExercises.remove(exerciseCanonical));
      }
    }
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
                        : 'Split Day ${detail.planDayNumber} | Session Type: ${_sessionTypeLabel(detail.planSessionType)}',
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
                  (run) => Card(
                    child: ListTile(
                      title: Text(run.session.title ??
                          run.session.activityType ??
                          'Run'),
                      subtitle: Text(
                        'source=${run.session.source} | duration=${run.session.durationS ?? 'unknown'}s | '
                        'distance=${run.session.distanceM ?? 'unknown'}m | avgHR=${run.session.avgHr ?? 'unknown'} | '
                        'maxHR=${run.session.maxHr ?? 'unknown'}'
                        '${run.overrodeManual ? ' | overrode manual' : ''}',
                      ),
                    ),
                  ),
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
                      title: Text(group.exercise),
                      subtitle: Text(
                        'Prescribed: ${prescribedSets.length} | Actual: ${actualSets.length}',
                      ),
                      childrenPadding: const EdgeInsets.all(12),
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Adjust Prescribed and Confirm as Actual',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            FilledButton.tonal(
                              onPressed:
                                  skippingExercise || prescribedSets.isEmpty
                                      ? null
                                      : () => _skipExercise(
                                            exerciseCanonical: group.exercise,
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
                                                exerciseCanonical:
                                                    group.exercise,
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
                                'Set ${s.setIndex}: ${s.weight ?? 'unknown'}x${s.reps ?? 'unknown'}r${s.rir ?? 'unknown'} ${s.unit}',
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
