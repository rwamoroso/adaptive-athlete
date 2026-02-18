import 'package:drift/drift.dart';

class RunSessions extends Table {
  TextColumn get id => text()();
  TextColumn get runKey => text().withDefault(const Constant(''))();
  TextColumn get workoutDayId => text().nullable()();
  TextColumn get planDayId => text().nullable()();
  IntColumn get startTime => integer().nullable()();
  IntColumn get endTime => integer().nullable()();
  IntColumn get durationS => integer().nullable()();
  RealColumn get distanceM => real().nullable()();
  RealColumn get avgHr => real().nullable()();
  RealColumn get maxHr => real().nullable()();
  BoolColumn get treadmill => boolean().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get activityType => text().nullable()();
  IntColumn get calories => integer().nullable()();
  IntColumn get movingTimeS => integer().nullable()();
  IntColumn get elapsedTimeS => integer().nullable()();
  IntColumn get sourcePriority => integer().withDefault(const Constant(0))();
  TextColumn get importFileName => text().nullable()();
  TextColumn get rawMetricsJson => text().nullable()();
  TextColumn get source => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
