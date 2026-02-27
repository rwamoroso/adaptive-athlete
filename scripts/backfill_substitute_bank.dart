import 'dart:io';

import 'package:adaptive_athlete/core/parsing/exercise_normalizer.dart';
import 'package:adaptive_athlete/db/app_db.dart';
import 'package:adaptive_athlete/features/training/exercise_substitution_service.dart';
import 'package:drift/native.dart';

class _ExerciseGroup {
  _ExerciseGroup({
    required this.planDayId,
    required this.prescribedExerciseCanonical,
  });

  final String planDayId;
  final String prescribedExerciseCanonical;
  final List<PlannedStrengthSetView> prescribedSets =
      <PlannedStrengthSetView>[];
}

class BackfillResult {
  const BackfillResult({
    required this.planRows,
    required this.distinctGroups,
    required this.groupsWithSuggestions,
    required this.suggestedRowWritesAttempted,
    required this.beforeCount,
    required this.afterCount,
  });

  final int planRows;
  final int distinctGroups;
  final int groupsWithSuggestions;
  final int suggestedRowWritesAttempted;
  final int beforeCount;
  final int afterCount;
}

Future<BackfillResult> runBackfill(String dbPath) async {
  final dbFile = File(dbPath);
  if (!dbFile.existsSync()) {
    throw ArgumentError('Database not found: $dbPath');
  }

  final db = AppDb.forTesting(NativeDatabase(dbFile));
  try {
    final beforeCount = await _countPlanExerciseAlternatives(db);

    final planRows = await db.select(db.planPrescribedStrengthSets).get();
    final grouped = <String, _ExerciseGroup>{};
    for (final row in planRows) {
      final exercise = row.exerciseCanonical.trim();
      if (exercise.isEmpty) continue;
      final normalized = ExerciseNormalizer.normalize(exercise);
      final key = '${row.planDayId}::$normalized';
      final group = grouped.putIfAbsent(
        key,
        () => _ExerciseGroup(
          planDayId: row.planDayId,
          prescribedExerciseCanonical: exercise,
        ),
      );
      group.prescribedSets.add(
        PlannedStrengthSetView(
          setIndex: row.setIndex,
          weight: row.weight,
          reps: row.reps,
          rir: row.rir,
          unit: row.unit,
        ),
      );
    }

    final service = ExerciseSubstitutionService(db: db);
    final allEquipment = ExerciseSubstitutionService.knownEquipment.toSet();
    var groupsWithSuggestions = 0;
    var suggestedRowsProcessed = 0;

    for (final group in grouped.values) {
      final suggestions = await service.suggestAlternatives(
        prescribedExerciseCanonical: group.prescribedExerciseCanonical,
        prescribedSets: group.prescribedSets,
        planDayId: group.planDayId,
        availableEquipment: allEquipment,
        contraindications: const <String>{},
        limit: 6,
      );
      if (suggestions.isEmpty) continue;

      final prescribedNormalized =
          ExerciseNormalizer.normalize(group.prescribedExerciseCanonical);
      var insertedForGroup = 0;
      for (var i = 0; i < suggestions.length; i++) {
        final candidate = suggestions[i];
        final altNormalized =
            ExerciseNormalizer.normalize(candidate.exerciseCanonical);
        if (altNormalized == prescribedNormalized) {
          continue;
        }
        final priority = suggestions.length - i;
        final notes = 'taxonomy_seed_backfill';

        await db.upsertPlanExerciseAlternative(
          planDayId: group.planDayId,
          prescribedExerciseCanonical: prescribedNormalized,
          alternativeExerciseCanonical: altNormalized,
          priority: priority,
          notes: notes,
        );
        await db.upsertPlanExerciseAlternative(
          planDayId: null,
          prescribedExerciseCanonical: prescribedNormalized,
          alternativeExerciseCanonical: altNormalized,
          priority: priority,
          notes: notes,
        );
        suggestedRowsProcessed += 2;
        insertedForGroup++;
      }

      if (insertedForGroup > 0) {
        groupsWithSuggestions++;
      }
    }

    final afterCount = await _countPlanExerciseAlternatives(db);
    return BackfillResult(
      planRows: planRows.length,
      distinctGroups: grouped.length,
      groupsWithSuggestions: groupsWithSuggestions,
      suggestedRowWritesAttempted: suggestedRowsProcessed,
      beforeCount: beforeCount,
      afterCount: afterCount,
    );
  } finally {
    await db.close();
  }
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: flutter pub run scripts/backfill_substitute_bank.dart '
      '<path-to-adaptive_athlete_local.db.sqlite>',
    );
    exit(2);
  }

  final result = await runBackfill(args.first);
  stdout.writeln('Plan prescribed rows: ${result.planRows}');
  stdout.writeln('Distinct plan-day exercise groups: ${result.distinctGroups}');
  stdout.writeln('Groups with suggestions: ${result.groupsWithSuggestions}');
  stdout.writeln(
    'Suggested row writes attempted (day+global): '
    '${result.suggestedRowWritesAttempted}',
  );
  stdout.writeln(
    'plan_exercise_alternatives count before: ${result.beforeCount}',
  );
  stdout.writeln(
    'plan_exercise_alternatives count after:  ${result.afterCount}',
  );
  stdout.writeln(
    'Inserted/updated delta: ${result.afterCount - result.beforeCount}',
  );
}

Future<int> _countPlanExerciseAlternatives(AppDb db) async {
  final row = await db
      .customSelect(
        'select count(*) as c from plan_exercise_alternatives',
      )
      .getSingle();
  return row.read<int>('c');
}
