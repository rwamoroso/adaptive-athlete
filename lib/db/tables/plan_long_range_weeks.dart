import 'package:drift/drift.dart';

class PlanLongRangeWeeks extends Table {
  TextColumn get id => text()();
  TextColumn get weekLabel => text()();
  IntColumn get weekNumber => integer().nullable()();
  TextColumn get weekStart => text()(); // YYYY-MM-DD
  TextColumn get weekEnd => text()(); // YYYY-MM-DD
  TextColumn get runFocus => text().nullable()();
  TextColumn get strengthFocus => text().nullable()();
  TextColumn get strengthProgressionExpectation => text().nullable()();
  TextColumn get primaryProgressionTarget => text().nullable()();
  TextColumn get recoveryEmphasis => text().nullable()();
  BoolColumn get deload => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  TextColumn get source => text()();
  TextColumn get lastPlanCycleId => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
