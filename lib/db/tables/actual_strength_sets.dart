import 'package:drift/drift.dart';

class ActualStrengthSets extends Table {
  TextColumn get id => text()();
  TextColumn get workoutDayId => text()();
  TextColumn get planDayId => text().nullable()();
  IntColumn get performedAt => integer().nullable()();
  TextColumn get exerciseCanonical => text()();
  TextColumn get prescribedExerciseCanonical => text().nullable()();
  TextColumn get substitutionId => text().nullable()();
  IntColumn get setIndex => integer()();
  RealColumn get weight => real().nullable()();
  IntColumn get reps => integer().nullable()();
  IntColumn get rir => integer().nullable()();
  TextColumn get unit => text()();
  TextColumn get source => text()();
  TextColumn get rawSetString => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
