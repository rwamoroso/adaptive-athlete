import 'package:adaptive_athlete/features/training/weekly_consistency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('counts consecutive weeks and ignores future sessions', () {
    final streak = calculateWeeklyConsistencyStreak(
      today: DateTime(2026, 11, 10),
      plannedDates: {
        '2026-11-09',
        '2026-11-11',
        '2026-11-02',
        '2026-11-04',
        '2026-10-26',
      },
      completedDates: {
        '2026-11-09',
        '2026-11-02',
        '2026-11-04',
        '2026-10-26',
      },
    );

    expect(streak, 3);
  });

  test('a missed session that was due ends the streak', () {
    final streak = calculateWeeklyConsistencyStreak(
      today: DateTime(2026, 11, 10),
      plannedDates: {
        '2026-11-09',
        '2026-11-10',
        '2026-11-02',
      },
      completedDates: {
        '2026-11-09',
        '2026-11-02',
      },
    );

    expect(streak, 0);
  });
}
