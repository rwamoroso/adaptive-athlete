import 'package:drift/drift.dart';

class SleepNights extends Table {
  TextColumn get id => text()();
  TextColumn get sleepDate => text()(); // YYYY-MM-DD
  IntColumn get startTime => integer().nullable()();
  IntColumn get endTime => integer().nullable()();
  IntColumn get totalSleepMin => integer().nullable()();
  IntColumn get remMin => integer().nullable()();
  IntColumn get deepMin => integer().nullable()();
  IntColumn get lightMin => integer().nullable()();
  IntColumn get awakeMin => integer().nullable()();
  TextColumn get source => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
