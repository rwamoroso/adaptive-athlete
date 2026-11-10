import '../../core/utils/date_utils.dart';

int calculateWeeklyConsistencyStreak({
  required DateTime today,
  required Set<String> plannedDates,
  required Set<String> completedDates,
  int maximumWeeks = 12,
}) {
  final currentWeekStart = DateTime(
    today.year,
    today.month,
    today.day - (today.weekday - 1),
  );
  var streak = 0;
  for (var weekOffset = 0; weekOffset < maximumWeeks; weekOffset++) {
    final weekStart = DateTime(
      currentWeekStart.year,
      currentWeekStart.month,
      currentWeekStart.day - (weekOffset * 7),
    );
    final weekEnd = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + 6,
    );
    final effectiveEnd = weekOffset == 0 ? today : weekEnd;
    final due = plannedDates.where((date) {
      final value = parseYmd(date);
      return !value.isBefore(weekStart) && !value.isAfter(effectiveEnd);
    }).toSet();
    if (due.isEmpty) {
      if (weekOffset == 0) continue;
      break;
    }
    if (!due.every(completedDates.contains)) break;
    streak++;
  }
  return streak;
}
