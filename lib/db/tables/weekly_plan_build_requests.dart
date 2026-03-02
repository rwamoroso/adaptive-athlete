import 'package:drift/drift.dart';

class WeeklyPlanBuildRequests extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text()();
  TextColumn get athleteProfileId => text()();
  TextColumn get weekStart => text()();
  TextColumn get weekEnd => text()();
  TextColumn get splitType => text()();
  TextColumn get modifier => text()();
  TextColumn get mode => text()();
  TextColumn get promptSnapshot => text()();
  TextColumn get requestPayloadJson => text()();
  TextColumn get responsePayloadJson => text().nullable()();
  BoolColumn get success => boolean()();
  TextColumn get errorText => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
