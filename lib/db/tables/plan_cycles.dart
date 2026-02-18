import 'package:drift/drift.dart';

class PlanCycles extends Table {
  TextColumn get id => text()();
  TextColumn get cycleKey => text()();
  TextColumn get weekStart => text()(); // YYYY-MM-DD (Monday)
  TextColumn get weekEnd => text()(); // YYYY-MM-DD (Sunday)
  TextColumn get source => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
