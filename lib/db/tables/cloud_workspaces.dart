import 'package:drift/drift.dart';

class CloudWorkspaces extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get createdAt => integer()();
  TextColumn get createdByUserId => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
