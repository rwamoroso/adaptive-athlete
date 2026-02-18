import 'package:drift/drift.dart';

class PrescribedStrengthSets extends Table {
  TextColumn get id => text()();
  TextColumn get workoutDayId => text()();
  TextColumn get exerciseCanonical => text()();
  IntColumn get setIndex => integer()();
  RealColumn get weight => real().nullable()();
  IntColumn get reps => integer().nullable()();
  IntColumn get rir => integer().nullable()();
  TextColumn get unit => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
