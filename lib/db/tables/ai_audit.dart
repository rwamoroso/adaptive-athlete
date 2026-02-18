import 'package:drift/drift.dart';

class AiAudit extends Table {
  TextColumn get id => text()();
  IntColumn get requestedAt => integer()();
  TextColumn get dateWindowStart => text().nullable()();
  TextColumn get dateWindowEnd => text().nullable()();
  TextColumn get inputSnapshotJson => text()();
  TextColumn get responseJson => text()();
  BoolColumn get schemaValid => boolean()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
