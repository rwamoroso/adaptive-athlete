import 'package:drift/drift.dart';

class PlanLongRangeWeekPerformance extends Table {
  TextColumn get id => text()();
  TextColumn get planLongRangeWeekId => text().nullable()();
  TextColumn get weekLabel => text().nullable()();
  IntColumn get weekNumber => integer().nullable()();
  TextColumn get weekStart => text()(); // YYYY-MM-DD
  TextColumn get weekEnd => text()(); // YYYY-MM-DD
  TextColumn get evaluatedPlanCycleId => text().nullable()();
  TextColumn get evaluationSource => text()();
  IntColumn get plannedDayCount => integer()();
  IntColumn get completedPlanDays => integer()();
  IntColumn get plannedRunDays => integer()();
  IntColumn get actualRunDays => integer()();
  IntColumn get plannedRunSessions => integer()();
  IntColumn get actualRunSessions => integer()();
  IntColumn get plannedStrengthExercises => integer()();
  IntColumn get actualStrengthExercises => integer()();
  IntColumn get plannedStrengthSets => integer()();
  IntColumn get actualStrengthSets => integer()();
  TextColumn get strengthProgressionExpectation => text().nullable()();
  TextColumn get strengthProgressionEvaluation => text().nullable()();
  RealColumn get actualRunDistanceM => real().nullable()();
  IntColumn get actualRunDurationS => integer().nullable()();
  TextColumn get metricsJson => text().nullable()();
  IntColumn get capturedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
