import 'package:drift/drift.dart';

class CloudAthleteProfileAssignments extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text()();
  TextColumn get athleteProfileId => text()();
  TextColumn get userId => text()();
  BoolColumn get canView => boolean().withDefault(const Constant(true))();
  BoolColumn get canEdit => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();
  TextColumn get createdByUserId => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
