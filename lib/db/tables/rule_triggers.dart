import 'package:drift/drift.dart';

class RuleTriggers extends Table {
  TextColumn get id => text()();
  TextColumn get triggerDate => text()();
  TextColumn get ruleCode => text()();
  BoolColumn get triggered => boolean()();
  TextColumn get detailsJson => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
