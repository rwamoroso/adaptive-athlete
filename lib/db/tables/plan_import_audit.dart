import 'package:drift/drift.dart';

class PlanImportAudit extends Table {
  TextColumn get id => text()();
  IntColumn get importedAt => integer()();
  TextColumn get fileName => text()();
  BoolColumn get success => boolean()();
  TextColumn get detailsJson => text()();
  TextColumn get conflictReportPath => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
