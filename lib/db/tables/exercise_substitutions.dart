import 'package:drift/drift.dart';

class ExerciseSubstitutions extends Table {
  TextColumn get id => text()();
  TextColumn get workoutDayId => text()();
  TextColumn get planDayId => text().nullable()();
  TextColumn get prescribedExerciseCanonical => text()();
  TextColumn get substituteExerciseCanonical => text()();
  TextColumn get reasonCode => text()();
  TextColumn get reasonNotes => text().nullable()();
  IntColumn get selectedAt => integer()();
  TextColumn get selectedBy => text().nullable()();
  RealColumn get matchScore => real().nullable()();
  TextColumn get matchExplanationJson => text().nullable()();
  BoolColumn get warningAcknowledged =>
      boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
        'UNIQUE(workout_day_id, prescribed_exercise_canonical)',
      ];
}
