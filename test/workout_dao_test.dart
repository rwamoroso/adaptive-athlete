import 'package:adaptive_athlete/db/app_db.dart';
import 'package:adaptive_athlete/db/dao/workout_dao.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WorkoutDao creates, lists, and loads workout days', () async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final dao = WorkoutDao(db);

    final id = await dao.createOrGetDay('2026-10-29');
    final duplicateId = await dao.createOrGetDay('2026-10-29');
    final days = await dao.listDays();
    final detail = await dao.getDay('2026-10-29');

    expect(duplicateId, id);
    expect(days, hasLength(1));
    expect(days.single.workoutDate, '2026-10-29');
    expect(detail.workoutDay?.id, id);
  });
}
