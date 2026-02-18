import 'package:drift/drift.dart';

class PlanPrescribedStrengthSets extends Table {
  TextColumn get id => text()();
  TextColumn get planDayId => text()();
  TextColumn get exerciseCanonical => text()();
  IntColumn get setIndex => integer()();
  RealColumn get weight => real().nullable()();
  IntColumn get reps => integer().nullable()();
  IntColumn get rir => integer().nullable()();
  TextColumn get unit => text()();
  TextColumn get rawSetString => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
