import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/parsing/exercise_normalizer.dart';
import '../../db/app_db.dart';

class ExerciseIntentProfile {
  const ExerciseIntentProfile({
    required this.exerciseCanonical,
    required this.displayName,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.movementPatterns,
    required this.equipment,
    required this.loadingStyle,
    required this.stabilityDemand,
    required this.jointStressFlags,
    this.defaultRepMin,
    this.defaultRepMax,
    this.defaultRirMin,
    this.defaultRirMax,
    this.progressionGroupId,
  });

  final String exerciseCanonical;
  final String displayName;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> movementPatterns;
  final List<String> equipment;
  final String loadingStyle;
  final String stabilityDemand;
  final List<String> jointStressFlags;
  final int? defaultRepMin;
  final int? defaultRepMax;
  final int? defaultRirMin;
  final int? defaultRirMax;
  final String? progressionGroupId;
}

enum SubstitutionTier { strong, acceptable, weak }

class SubstitutionCandidate {
  const SubstitutionCandidate({
    required this.exerciseCanonical,
    required this.score,
    required this.tier,
    required this.isCurated,
    required this.warnings,
    required this.explanation,
    required this.profile,
  });

  final String exerciseCanonical;
  final double score;
  final SubstitutionTier tier;
  final bool isCurated;
  final List<String> warnings;
  final Map<String, dynamic> explanation;
  final ExerciseIntentProfile profile;
}

class SubstitutionValidation {
  const SubstitutionValidation({
    required this.tier,
    required this.score,
    required this.warnings,
    required this.explanationJson,
  });

  final SubstitutionTier tier;
  final double score;
  final List<String> warnings;
  final String explanationJson;
}

class ConvertedSetTarget {
  const ConvertedSetTarget({
    required this.setIndex,
    required this.suggestedWeight,
    required this.suggestedReps,
    required this.suggestedRir,
    required this.confidence,
    required this.rationale,
  });

  final int setIndex;
  final double? suggestedWeight;
  final int? suggestedReps;
  final int? suggestedRir;
  final String confidence;
  final String rationale;
}

class ExerciseSubstitutionService {
  ExerciseSubstitutionService({required this.db});

  final AppDb db;

  static const List<String> knownEquipment = <String>[
    'barbell',
    'dumbbell',
    'cable',
    'machine',
    'bodyweight',
    'bands',
  ];

  static const List<String> knownContraindications = <String>[
    'overhead_pressing',
    'deep_knee_flexion',
    'spinal_loading',
    'wrist_extension',
    'elbow_flexion_irritation',
  ];

  static final Map<String, ExerciseIntentProfile> _profiles = {
    for (final p in _seedProfiles)
      ExerciseNormalizer.normalize(p.exerciseCanonical): p,
  };

  ExerciseIntentProfile? getProfile(String exerciseCanonical) {
    return _profiles[ExerciseNormalizer.normalize(exerciseCanonical)];
  }

  List<ExerciseIntentProfile> allProfiles() {
    final values = _profiles.values.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return values;
  }

  Future<List<SubstitutionCandidate>> suggestAlternatives({
    required String prescribedExerciseCanonical,
    required List<PlannedStrengthSetView> prescribedSets,
    required String? planDayId,
    required Set<String> availableEquipment,
    required Set<String> contraindications,
    int limit = 12,
  }) async {
    final prescribed = ExerciseNormalizer.normalize(prescribedExerciseCanonical);
    final source = getProfile(prescribed);
    if (source == null) {
      return const <SubstitutionCandidate>[];
    }

    final curated = await db.getPlanExerciseAlternativesForPlanDay(
      planDayId: planDayId,
      prescribedExerciseCanonical: prescribed,
    );
    final curatedSet = curated.map((e) => e.exerciseCanonical).toSet();

    final candidates = <String>{};
    for (final profile in _profiles.values) {
      if (profile.exerciseCanonical == prescribed) {
        continue;
      }
      final sharesPattern = profile.movementPatterns
          .any(source.movementPatterns.toSet().contains);
      final sharesMuscle =
          profile.primaryMuscles.any(source.primaryMuscles.toSet().contains);
      if (sharesPattern || sharesMuscle || curatedSet.contains(profile.exerciseCanonical)) {
        candidates.add(profile.exerciseCanonical);
      }
    }

    final scored = <SubstitutionCandidate>[];
    for (final candidateExercise in candidates) {
      final target = _profiles[candidateExercise]!;
      final isCurated = curatedSet.contains(candidateExercise);
      final result = _scoreCandidate(
        source: source,
        target: target,
        prescribedSets: prescribedSets,
        availableEquipment: availableEquipment,
        contraindications: contraindications,
        isCurated: isCurated,
      );
      scored.add(result);
    }

    scored.sort((a, b) {
      final curatedCmp = (b.isCurated ? 1 : 0) - (a.isCurated ? 1 : 0);
      if (curatedCmp != 0) {
        return curatedCmp;
      }
      return b.score.compareTo(a.score);
    });
    return scored.take(limit).toList();
  }

  Future<SubstitutionValidation> validateSelection({
    required String prescribedExerciseCanonical,
    required String substituteExerciseCanonical,
    required List<PlannedStrengthSetView> prescribedSets,
    required Set<String> availableEquipment,
    required Set<String> contraindications,
    bool isCurated = false,
  }) async {
    final source = getProfile(prescribedExerciseCanonical);
    final target = getProfile(substituteExerciseCanonical);
    if (source == null || target == null) {
      const warnings = <String>['Missing exercise taxonomy profile'];
      return SubstitutionValidation(
        tier: SubstitutionTier.weak,
        score: 0,
        warnings: warnings,
        explanationJson: jsonEncode({'warnings': warnings}),
      );
    }
    final candidate = _scoreCandidate(
      source: source,
      target: target,
      prescribedSets: prescribedSets,
      availableEquipment: availableEquipment,
      contraindications: contraindications,
      isCurated: isCurated,
    );
    return SubstitutionValidation(
      tier: candidate.tier,
      score: candidate.score,
      warnings: candidate.warnings,
      explanationJson: jsonEncode(candidate.explanation),
    );
  }

  Future<List<ConvertedSetTarget>> convertPrescription({
    required String prescribedExerciseCanonical,
    required String substituteExerciseCanonical,
    required List<PlannedStrengthSetView> prescribedSets,
  }) async {
    final source = getProfile(prescribedExerciseCanonical);
    final target = getProfile(substituteExerciseCanonical);
    final historyRows = await (db.select(db.actualStrengthSets)
          ..where((t) =>
              t.exerciseCanonical.equals(
                ExerciseNormalizer.normalize(substituteExerciseCanonical),
              ))
          ..orderBy([
            (t) => OrderingTerm(expression: t.performedAt, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ])
          ..limit(20))
        .get();

    final recentWeights = historyRows
        .where((r) => (r.weight ?? 0) > 0)
        .map((r) => r.weight!)
        .toList();
    final avgRecentWeight = recentWeights.isEmpty
        ? null
        : recentWeights.reduce((a, b) => a + b) / recentWeights.length;
    final sameProgression = source != null &&
        target != null &&
        source.progressionGroupId != null &&
        source.progressionGroupId == target.progressionGroupId;

    return prescribedSets.map((set) {
      var reps = set.reps;
      final rir = set.rir;
      final warnings = <String>[];
      if (target != null &&
          reps != null &&
          target.defaultRepMin != null &&
          target.defaultRepMax != null) {
        final clamped = reps.clamp(target.defaultRepMin!, target.defaultRepMax!);
        if (clamped != reps) {
          warnings.add(
            'Reps adjusted to fit ${target.displayName} target range (${target.defaultRepMin}-${target.defaultRepMax})',
          );
          reps = clamped;
        }
      }

      double? suggestedWeight;
      String confidence = 'low';
      final rationale = <String>[];
      if (avgRecentWeight != null) {
        suggestedWeight = _roundToIncrement(avgRecentWeight, 2.5);
        confidence = 'high';
        rationale.add('Based on recent $substituteExerciseCanonical history');
      } else if (sameProgression && set.weight != null && set.weight! > 0) {
        suggestedWeight = _roundToIncrement(set.weight! * 0.9, 2.5);
        confidence = 'medium';
        rationale.add('Estimated from same progression group');
      } else if (set.weight != null && set.weight! > 0) {
        suggestedWeight = _roundToIncrement(set.weight! * 0.8, 2.5);
        confidence = 'low';
        rationale.add('Generic downgrade estimate; confirm manually');
      } else {
        rationale.add('No history; enter load manually');
      }
      rationale.addAll(warnings);
      return ConvertedSetTarget(
        setIndex: set.setIndex,
        suggestedWeight: suggestedWeight,
        suggestedReps: reps,
        suggestedRir: rir,
        confidence: confidence,
        rationale: rationale.join('. '),
      );
    }).toList();
  }

  Future<void> applySubstitution({
    required String dateYmd,
    required String prescribedExerciseCanonical,
    required String substituteExerciseCanonical,
    required String reasonCode,
    String? reasonNotes,
    required SubstitutionValidation validation,
    required bool warningAcknowledged,
  }) {
    return db.upsertExerciseSubstitutionForDate(
      dateYmd: dateYmd,
      prescribedExerciseCanonical: prescribedExerciseCanonical,
      substituteExerciseCanonical: substituteExerciseCanonical,
      reasonCode: reasonCode,
      reasonNotes: reasonNotes,
      matchScore: validation.score,
      matchExplanationJson: validation.explanationJson,
      warningAcknowledged: warningAcknowledged,
    );
  }

  Future<void> clearSubstitution({
    required String dateYmd,
    required String prescribedExerciseCanonical,
  }) {
    return db.clearExerciseSubstitutionForDate(
      dateYmd: dateYmd,
      prescribedExerciseCanonical: prescribedExerciseCanonical,
    );
  }

  SubstitutionCandidate _scoreCandidate({
    required ExerciseIntentProfile source,
    required ExerciseIntentProfile target,
    required List<PlannedStrengthSetView> prescribedSets,
    required Set<String> availableEquipment,
    required Set<String> contraindications,
    required bool isCurated,
  }) {
    var score = 0.0;
    final warnings = <String>[];
    final breakdown = <String, dynamic>{};

    final sourcePatterns = source.movementPatterns.toSet();
    final targetPatterns = target.movementPatterns.toSet();
    final patternOverlap = sourcePatterns.intersection(targetPatterns);
    final patternScore =
        sourcePatterns.isEmpty ? 0.0 : (patternOverlap.length / sourcePatterns.length) * 35.0;
    score += patternScore;
    breakdown['movement_pattern'] = {
      'score': patternScore,
      'shared': patternOverlap.toList(),
    };
    if (patternOverlap.isEmpty) {
      warnings.add('No shared movement pattern');
    }

    final sourceMuscles = source.primaryMuscles.toSet();
    final targetMuscles = target.primaryMuscles.toSet();
    final muscleOverlap = sourceMuscles.intersection(targetMuscles);
    final muscleScore =
        sourceMuscles.isEmpty ? 0.0 : (muscleOverlap.length / sourceMuscles.length) * 25.0;
    score += muscleScore;
    breakdown['primary_muscles'] = {
      'score': muscleScore,
      'shared': muscleOverlap.toList(),
    };

    final loadingScore = source.loadingStyle == target.loadingStyle ? 15.0 : 0.0;
    score += loadingScore;
    breakdown['loading_style'] = {
      'score': loadingScore,
      'source': source.loadingStyle,
      'target': target.loadingStyle,
    };

    final prescribedReps = prescribedSets.where((s) => s.reps != null).map((s) => s.reps!).toList();
    var repScore = 10.0;
    if (prescribedReps.isNotEmpty && target.defaultRepMin != null && target.defaultRepMax != null) {
      final outside = prescribedReps.where((r) => r < target.defaultRepMin! || r > target.defaultRepMax!).length;
      if (outside > 0) {
        repScore = 10.0 * (1 - outside / prescribedReps.length);
        score -= 15.0;
        warnings.add('Rep target partially outside preferred range');
      }
    }
    score += repScore;
    breakdown['rep_range'] = {'score': repScore};

    final stabilityScore = source.stabilityDemand == target.stabilityDemand ? 5.0 : 2.0;
    score += stabilityScore;
    breakdown['stability'] = {'score': stabilityScore};

    final equipmentOkay =
        target.equipment.any((e) => availableEquipment.contains(e));
    final equipmentScore = equipmentOkay ? 5.0 : 0.0;
    score += equipmentScore;
    breakdown['equipment'] = {
      'score': equipmentScore,
      'required_any': target.equipment,
      'available': availableEquipment.toList(),
    };
    if (!equipmentOkay) {
      warnings.add('Required equipment not available');
    }

    final progressionMatch = source.progressionGroupId != null &&
        source.progressionGroupId == target.progressionGroupId;
    final progressionScore = progressionMatch ? 5.0 : 0.0;
    score += progressionScore;
    breakdown['progression_group'] = {'score': progressionScore};

    final conflicts =
        target.jointStressFlags.where(contraindications.contains).toList();
    if (conflicts.isNotEmpty) {
      score -= 40.0;
      warnings.add('Contraindication conflict: ${conflicts.join(', ')}');
      breakdown['contraindications'] = {'conflicts': conflicts, 'penalty': 40};
    } else {
      breakdown['contraindications'] = {'conflicts': const <String>[]};
    }

    score = score.clamp(0, 100).toDouble();
    final tier = score >= 80
        ? SubstitutionTier.strong
        : score >= 60
            ? SubstitutionTier.acceptable
            : SubstitutionTier.weak;
    breakdown['final'] = {
      'score': score,
      'tier': tier.name,
      'is_curated': isCurated,
    };

    return SubstitutionCandidate(
      exerciseCanonical: target.exerciseCanonical,
      score: score,
      tier: tier,
      isCurated: isCurated,
      warnings: warnings,
      explanation: breakdown,
      profile: target,
    );
  }

  static double _roundToIncrement(double value, double increment) {
    final factor = value / increment;
    return (factor.round() * increment).toDouble();
  }

  static const List<ExerciseIntentProfile> _seedProfiles = <ExerciseIntentProfile>[
    ExerciseIntentProfile(
      exerciseCanonical: 'Bench Press',
      displayName: 'Bench Press',
      primaryMuscles: ['chest', 'triceps'],
      secondaryMuscles: ['front_delts'],
      movementPatterns: ['horizontal_push'],
      equipment: ['barbell', 'bench'],
      loadingStyle: 'bilateral_load',
      stabilityDemand: 'medium',
      jointStressFlags: ['wrist_extension'],
      defaultRepMin: 4,
      defaultRepMax: 10,
      defaultRirMin: 1,
      defaultRirMax: 4,
      progressionGroupId: 'horizontal_press',
    ),
    ExerciseIntentProfile(
      exerciseCanonical: 'Dumbbell Bench Press',
      displayName: 'Dumbbell Bench Press',
      primaryMuscles: ['chest', 'triceps'],
      secondaryMuscles: ['front_delts'],
      movementPatterns: ['horizontal_push'],
      equipment: ['dumbbell', 'bench'],
      loadingStyle: 'bilateral_load',
      stabilityDemand: 'high',
      jointStressFlags: ['wrist_extension'],
      defaultRepMin: 6,
      defaultRepMax: 15,
      progressionGroupId: 'horizontal_press',
    ),
    ExerciseIntentProfile(
      exerciseCanonical: 'Push Up',
      displayName: 'Push Up',
      primaryMuscles: ['chest', 'triceps'],
      secondaryMuscles: ['front_delts', 'core'],
      movementPatterns: ['horizontal_push'],
      equipment: ['bodyweight'],
      loadingStyle: 'bodyweight',
      stabilityDemand: 'medium',
      jointStressFlags: ['wrist_extension'],
      defaultRepMin: 8,
      defaultRepMax: 25,
      progressionGroupId: 'horizontal_press',
    ),
    ExerciseIntentProfile(
      exerciseCanonical: 'Overhead Press',
      displayName: 'Overhead Press',
      primaryMuscles: ['shoulders', 'triceps'],
      secondaryMuscles: ['upper_chest'],
      movementPatterns: ['vertical_push'],
      equipment: ['barbell'],
      loadingStyle: 'bilateral_load',
      stabilityDemand: 'medium',
      jointStressFlags: ['overhead_pressing', 'spinal_loading'],
      defaultRepMin: 4,
      defaultRepMax: 10,
      progressionGroupId: 'vertical_press',
    ),
    ExerciseIntentProfile(
      exerciseCanonical: 'Landmine Press',
      displayName: 'Landmine Press',
      primaryMuscles: ['shoulders', 'triceps'],
      secondaryMuscles: ['upper_chest'],
      movementPatterns: ['angled_push'],
      equipment: ['barbell'],
      loadingStyle: 'unilateral_load',
      stabilityDemand: 'medium',
      jointStressFlags: ['spinal_loading'],
      defaultRepMin: 6,
      defaultRepMax: 12,
      progressionGroupId: 'vertical_press',
    ),
    ExerciseIntentProfile(
      exerciseCanonical: 'Squat',
      displayName: 'Squat',
      primaryMuscles: ['quads', 'glutes'],
      secondaryMuscles: ['adductors'],
      movementPatterns: ['squat'],
      equipment: ['barbell'],
      loadingStyle: 'bilateral_load',
      stabilityDemand: 'high',
      jointStressFlags: ['deep_knee_flexion', 'spinal_loading'],
      defaultRepMin: 3,
      defaultRepMax: 10,
      progressionGroupId: 'squat_pattern',
    ),
    ExerciseIntentProfile(
      exerciseCanonical: 'Goblet Squat',
      displayName: 'Goblet Squat',
      primaryMuscles: ['quads', 'glutes'],
      secondaryMuscles: ['core'],
      movementPatterns: ['squat'],
      equipment: ['dumbbell'],
      loadingStyle: 'bilateral_load',
      stabilityDemand: 'medium',
      jointStressFlags: ['deep_knee_flexion'],
      defaultRepMin: 8,
      defaultRepMax: 15,
      progressionGroupId: 'squat_pattern',
    ),
    ExerciseIntentProfile(
      exerciseCanonical: 'Romanian Deadlift',
      displayName: 'Romanian Deadlift',
      primaryMuscles: ['hamstrings', 'glutes'],
      secondaryMuscles: ['back'],
      movementPatterns: ['hinge'],
      equipment: ['barbell'],
      loadingStyle: 'bilateral_load',
      stabilityDemand: 'medium',
      jointStressFlags: ['spinal_loading'],
      defaultRepMin: 5,
      defaultRepMax: 12,
      progressionGroupId: 'hinge',
    ),
    ExerciseIntentProfile(
      exerciseCanonical: 'Hip Thrust',
      displayName: 'Hip Thrust',
      primaryMuscles: ['glutes'],
      secondaryMuscles: ['hamstrings'],
      movementPatterns: ['hip_extension'],
      equipment: ['barbell', 'machine'],
      loadingStyle: 'bilateral_load',
      stabilityDemand: 'low',
      jointStressFlags: [],
      defaultRepMin: 6,
      defaultRepMax: 15,
      progressionGroupId: 'hinge',
    ),
    ExerciseIntentProfile(
      exerciseCanonical: 'Pull Up',
      displayName: 'Pull Up',
      primaryMuscles: ['lats', 'biceps'],
      secondaryMuscles: ['upper_back'],
      movementPatterns: ['vertical_pull'],
      equipment: ['bodyweight'],
      loadingStyle: 'bodyweight',
      stabilityDemand: 'medium',
      jointStressFlags: ['elbow_flexion_irritation'],
      defaultRepMin: 4,
      defaultRepMax: 15,
      progressionGroupId: 'vertical_pull',
    ),
    ExerciseIntentProfile(
      exerciseCanonical: 'Lat Pulldown',
      displayName: 'Lat Pulldown',
      primaryMuscles: ['lats', 'biceps'],
      secondaryMuscles: ['upper_back'],
      movementPatterns: ['vertical_pull'],
      equipment: ['cable', 'machine'],
      loadingStyle: 'machine_guided',
      stabilityDemand: 'low',
      jointStressFlags: ['elbow_flexion_irritation'],
      defaultRepMin: 8,
      defaultRepMax: 15,
      progressionGroupId: 'vertical_pull',
    ),
    ExerciseIntentProfile(
      exerciseCanonical: 'Barbell Row',
      displayName: 'Barbell Row',
      primaryMuscles: ['upper_back', 'lats'],
      secondaryMuscles: ['biceps'],
      movementPatterns: ['horizontal_pull', 'hinge'],
      equipment: ['barbell'],
      loadingStyle: 'bilateral_load',
      stabilityDemand: 'high',
      jointStressFlags: ['spinal_loading'],
      defaultRepMin: 5,
      defaultRepMax: 12,
      progressionGroupId: 'horizontal_pull',
    ),
    ExerciseIntentProfile(
      exerciseCanonical: 'Seated Cable Row',
      displayName: 'Seated Cable Row',
      primaryMuscles: ['upper_back', 'lats'],
      secondaryMuscles: ['biceps'],
      movementPatterns: ['horizontal_pull'],
      equipment: ['cable', 'machine'],
      loadingStyle: 'machine_guided',
      stabilityDemand: 'low',
      jointStressFlags: [],
      defaultRepMin: 8,
      defaultRepMax: 15,
      progressionGroupId: 'horizontal_pull',
    ),
  ];
}
