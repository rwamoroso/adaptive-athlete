import 'package:drift/drift.dart';

class AppContextState extends Table {
  TextColumn get id => text().withDefault(const Constant('default'))();
  TextColumn get activeWorkspaceId => text().nullable()();
  TextColumn get activeProfileId => text().nullable()();
  TextColumn get activeRole => text().nullable()();
  TextColumn get lastAuthUserId => text().nullable()();
  BoolColumn get needsCloudClaim =>
      boolean().withDefault(const Constant(false))();
  TextColumn get pendingInviteToken => text().nullable()();
  IntColumn get updatedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
