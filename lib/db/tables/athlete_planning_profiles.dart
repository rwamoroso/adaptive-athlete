import 'package:drift/drift.dart';

class AthletePlanningProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text()();
  TextColumn get athleteProfileId => text()();
  TextColumn get primaryGoal => text()();
  TextColumn get goalTargetJson => text()();
  TextColumn get experienceLevel => text()();
  TextColumn get preferredSplit => text()();
  IntColumn get daysPerWeek => integer()();
  TextColumn get availableEquipmentJson => text()();
  TextColumn get contraindicationsJson => text()();
  TextColumn get scheduleConstraintsJson => text()();
  TextColumn get biometricsJson => text().withDefault(const Constant('{}'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
