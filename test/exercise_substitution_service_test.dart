import 'package:adaptive_athlete/core/parsing/exercise_normalizer.dart';
import 'package:adaptive_athlete/db/app_db.dart';
import 'package:adaptive_athlete/features/training/exercise_substitution_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shows curated alternatives when prescribed exercise profile is missing',
      () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.upsertPlanExerciseAlternative(
      planDayId: null,
      prescribedExerciseCanonical: 'Custom PT Press',
      alternativeExerciseCanonical: 'Bench Press',
      priority: 1,
    );

    final service = ExerciseSubstitutionService(db: db);
    final suggestions = await service.suggestAlternatives(
      prescribedExerciseCanonical: 'Custom PT Press',
      prescribedSets: const <PlannedStrengthSetView>[],
      planDayId: null,
      availableEquipment: const <String>{},
      contraindications: const <String>{},
    );

    expect(suggestions, isNotEmpty);
    final bench = suggestions.firstWhere(
      (c) => c.exerciseCanonical == 'Bench Press',
    );
    expect(bench.isCurated, isTrue);
  });

  test('shows curated alternatives even when alternative profile is missing',
      () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.upsertPlanExerciseAlternative(
      planDayId: null,
      prescribedExerciseCanonical: 'Bench Press',
      alternativeExerciseCanonical: 'Custom PT Press Variant',
      priority: 1,
    );

    final service = ExerciseSubstitutionService(db: db);
    final suggestions = await service.suggestAlternatives(
      prescribedExerciseCanonical: 'Bench Press',
      prescribedSets: const <PlannedStrengthSetView>[],
      planDayId: null,
      availableEquipment: const <String>{},
      contraindications: const <String>{},
    );

    final normalizedAlt =
        ExerciseNormalizer.normalize('Custom PT Press Variant');
    final customAlt = suggestions.firstWhere(
      (c) => c.exerciseCanonical == normalizedAlt,
    );
    expect(customAlt.isCurated, isTrue);
    expect(customAlt.tier, SubstitutionTier.weak);
  });

  test('suggests core alternatives for Core-prefixed exercise labels',
      () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final service = ExerciseSubstitutionService(db: db);
    final suggestions = await service.suggestAlternatives(
      prescribedExerciseCanonical: 'Core: Straight Leg Raise',
      prescribedSets: const <PlannedStrengthSetView>[],
      planDayId: null,
      availableEquipment: const <String>{'bodyweight', 'cable'},
      contraindications: const <String>{},
    );

    expect(suggestions, isNotEmpty);
    expect(
      suggestions.any((c) => c.exerciseCanonical == 'Reverse Crunch'),
      isTrue,
    );
  });

  test('plan day alternatives are preferred and deduped against global bank',
      () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.upsertPlanExerciseAlternative(
      planDayId: null,
      prescribedExerciseCanonical: 'Bench Press',
      alternativeExerciseCanonical: 'Push Up',
      priority: 10,
    );
    await db.upsertPlanExerciseAlternative(
      planDayId: 'day_1',
      prescribedExerciseCanonical: 'Bench Press',
      alternativeExerciseCanonical: 'Push Up',
      priority: 999,
    );
    await db.upsertPlanExerciseAlternative(
      planDayId: null,
      prescribedExerciseCanonical: 'Bench Press',
      alternativeExerciseCanonical: 'Dumbbell Bench Press',
      priority: 20,
    );

    final rows = await db.getPlanExerciseAlternativesForPlanDay(
      planDayId: 'day_1',
      prescribedExerciseCanonical: 'Bench Press',
    );

    expect(
      rows.map((r) => r.exerciseCanonical).toList(),
      ['Push Up', 'Dumbbell Bench Press'],
    );
  });

  test('leg curl variants are discoverable for substitution search', () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final service = ExerciseSubstitutionService(db: db);
    final suggestions = await service.suggestAlternatives(
      prescribedExerciseCanonical: 'Kneeling Leg Curl',
      prescribedSets: const <PlannedStrengthSetView>[],
      planDayId: null,
      availableEquipment: const <String>{'machine'},
      contraindications: const <String>{},
    );

    expect(suggestions.length, greaterThan(6));
    expect(
      suggestions.any((c) => c.exerciseCanonical == 'Seated Leg Curl'),
      isTrue,
    );
  });

  test('normalizes sitting leg curl alias to seated leg curl', () {
    expect(
      ExerciseNormalizer.normalize('sitting leg curls'),
      'Seated Leg Curl',
    );
  });
}
