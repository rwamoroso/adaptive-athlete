import 'package:drift/drift.dart';

class PlanDays extends Table {
  TextColumn get id => text()();
  TextColumn get planCycleId => text()();
  IntColumn get dayNumber => integer()(); // 1..7
  TextColumn get sheetName => text()();
  TextColumn get estimatedDate => text().nullable()(); // YYYY-MM-DD estimate
  TextColumn get sessionType => text().nullable()(); // push|pull|legs|rest|unknown
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
