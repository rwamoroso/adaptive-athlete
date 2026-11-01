String toYmd(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime parseYmd(String value) {
  final parts = value.split('-');
  if (parts.length != 3) {
    throw FormatException('Invalid YYYY-MM-DD: $value');
  }
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// Adds calendar days to a date without treating a day as 24 elapsed hours.
/// The returned value is local midnight on the resulting calendar date.
DateTime addCalendarDateDays(DateTime value, int days) {
  final shifted = DateTime.utc(value.year, value.month, value.day)
      .add(Duration(days: days));
  return DateTime(shifted.year, shifted.month, shifted.day);
}

/// Adds whole calendar days to a YYYY-MM-DD value without using local elapsed
/// time. UTC is used only as a stable calendar representation, so daylight
/// saving transitions cannot move the result onto an adjacent date.
String addCalendarDays(String value, int days) {
  final parts = value.split('-');
  if (parts.length != 3) {
    throw FormatException('Invalid YYYY-MM-DD: $value');
  }
  final date = DateTime.utc(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
  return toYmd(date.add(Duration(days: days)));
}

int unixMsNow() => DateTime.now().millisecondsSinceEpoch;
