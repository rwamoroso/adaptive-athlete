import 'package:drift/drift.dart';

class PlanExerciseAlternatives extends Table {
  TextColumn get id => text()();
  TextColumn get planDayId => text().nullable()();
  TextColumn get prescribedExerciseCanonical => text()();
  TextColumn get alternativeExerciseCanonical => text()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
