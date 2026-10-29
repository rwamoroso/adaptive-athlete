import '../app_db.dart';

/// Focused database boundary for workout-day screens.
class WorkoutDao {
  const WorkoutDao(this._db);

  final AppDb _db;

  Future<List<WorkoutDay>> listDays({bool descending = true}) {
    return _db.listWorkoutDays(desc: descending);
  }

  Future<WorkoutDayDetail> getDay(String dateYmd) {
    return _db.getWorkoutDayDetail(dateYmd);
  }

  Future<String> createOrGetDay(String dateYmd) {
    return _db.createOrGetWorkoutDayByDate(dateYmd);
  }
}
