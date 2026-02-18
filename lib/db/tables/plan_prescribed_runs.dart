import 'package:drift/drift.dart';

class PlanPrescribedRuns extends Table {
  TextColumn get id => text()();
  TextColumn get planDayId => text()();
  TextColumn get dayLabel => text().nullable()();
  TextColumn get liftFocus => text().nullable()();
  TextColumn get runType => text().nullable()();
  TextColumn get durationText => text().nullable()();
  TextColumn get targetPace => text().nullable()();
  TextColumn get effortHrGuardrails => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
