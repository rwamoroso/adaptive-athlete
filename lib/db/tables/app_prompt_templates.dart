import 'package:drift/drift.dart';

class AppPromptTemplates extends Table {
  TextColumn get templateKey => text()();
  TextColumn get templateText => text()();
  TextColumn get source =>
      text().withDefault(const Constant('user_override'))();
  TextColumn get versionTag => text().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {templateKey};
}
