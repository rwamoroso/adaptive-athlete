import 'package:drift/drift.dart';
import '../../db/app_db.dart';
import 'cardio_activity.dart';

Future<Map<String, double>> runningDistanceByDate(
    AppDb db, String start, String end) async {
  final rows = await db.customSelect("""
    select wd.workout_date, rs.distance_m, rs.activity_type, rs.title, rs.treadmill
    from run_sessions rs join workout_days wd on wd.id=rs.workout_day_id
    where wd.workout_date >= ? and wd.workout_date <= ?
  """,
      variables: [Variable.withString(start), Variable.withString(end)],
      readsFrom: {db.runSessions, db.workoutDays}).get();
  final distances = <String, double>{};
  for (final row in rows) {
    if (!CardioActivity.isRunningSession(
        activityType: row.data['activity_type'] as String?,
        title: row.data['title'] as String?,
        treadmill: row.data['treadmill'] == 1)) {
      continue;
    }
    final date = row.read<String>('workout_date');
    distances[date] = (distances[date] ?? 0) +
        ((row.data['distance_m'] as num?)?.toDouble() ?? 0);
  }
  return distances;
}
