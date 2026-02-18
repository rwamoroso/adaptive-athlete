import 'package:drift/drift.dart';

class RunSegments extends Table {
  TextColumn get id => text()();
  TextColumn get runSessionId => text()();
  IntColumn get idx => integer()();
  IntColumn get durationS => integer().nullable()();
  RealColumn get distanceM => real().nullable()();
  RealColumn get speedMps => real().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
