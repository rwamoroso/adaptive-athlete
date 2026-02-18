import 'package:drift/drift.dart';

class WorkoutDays extends Table {
  TextColumn get id => text()();
  TextColumn get workoutDate => text()(); // YYYY-MM-DD
  IntColumn get createdAt => integer()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
