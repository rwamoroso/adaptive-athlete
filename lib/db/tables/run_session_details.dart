import 'package:drift/drift.dart';

class RunSessionDetails extends Table {
  TextColumn get runSessionId => text()();
  BoolColumn get favorite => boolean().nullable()();
  RealColumn get aerobicTe => real().nullable()();
  RealColumn get avgRunCadence => real().nullable()();
  RealColumn get maxRunCadence => real().nullable()();
  RealColumn get avgPaceS => real().nullable()();
  RealColumn get bestPaceS => real().nullable()();
  RealColumn get totalAscent => real().nullable()();
  RealColumn get totalDescent => real().nullable()();
  RealColumn get avgStrideLengthM => real().nullable()();
  RealColumn get trainingStressScore => real().nullable()();
  IntColumn get steps => integer().nullable()();
  RealColumn get minTemp => real().nullable()();
  RealColumn get maxTemp => real().nullable()();
  TextColumn get decompression => text().nullable()();
  RealColumn get bestLapTimeS => real().nullable()();
  IntColumn get numberOfLaps => integer().nullable()();
  RealColumn get minElevation => real().nullable()();
  RealColumn get maxElevation => real().nullable()();
  TextColumn get rawMetricsJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {runSessionId};
}
