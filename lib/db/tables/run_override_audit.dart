import 'package:drift/drift.dart';

class RunOverrideAudit extends Table {
  TextColumn get id => text()();
  TextColumn get runKey => text()();
  TextColumn get workoutDayId => text().nullable()();
  TextColumn get oldSource => text()();
  TextColumn get newSource => text()();
  TextColumn get oldSnapshotJson => text()();
  TextColumn get newSnapshotJson => text()();
  TextColumn get reason => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
