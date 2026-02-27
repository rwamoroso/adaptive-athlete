import 'package:drift/drift.dart';

class CloudWorkspaceMemberships extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text()();
  TextColumn get userId => text()();
  TextColumn get userEmail => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get role => text()();
  TextColumn get status => text()();
  IntColumn get createdAt => integer()();
  TextColumn get createdByUserId => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
