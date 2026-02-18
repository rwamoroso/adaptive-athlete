import 'package:drift/drift.dart';

class PlanSummarySnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get planCycleId => text()();
  TextColumn get tabName => text()();
  TextColumn get snapshotJson => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
