import 'package:drift/drift.dart';

class CloudAthleteProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text()();
  TextColumn get name => text()();
  TextColumn get dateOfBirth => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()();
  TextColumn get createdByUserId => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
