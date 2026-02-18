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

int unixMsNow() => DateTime.now().millisecondsSinceEpoch;
