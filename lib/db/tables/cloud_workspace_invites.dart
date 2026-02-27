import 'package:drift/drift.dart';

class CloudWorkspaceInvites extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text()();
  TextColumn get email => text()();
  TextColumn get role => text()();
  TextColumn get displayName => text().nullable()();
  IntColumn get expiresAt => integer()();
  TextColumn get status => text()();
  TextColumn get assignedProfileIdsJson => text()();
  IntColumn get createdAt => integer()();
  TextColumn get createdByUserId => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
