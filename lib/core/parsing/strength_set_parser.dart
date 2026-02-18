class StrengthSetParseResult {
  const StrengthSetParseResult({
    required this.raw,
    required this.weight,
    required this.reps,
    required this.rir,
    required this.unit,
  });

  final String raw;
  final double? weight;
  final int? reps;
  final int? rir;
  final String unit;
}

class StrengthSetParser {
  static final RegExp _pattern = RegExp(
    r'^\s*(bw|\d+(?:\.\d+)?)\s*(kg|lb)?\s*x\s*(\d+)?\s*(?:r\s*(\d+))?\s*$',
    caseSensitive: false,
  );

  static StrengthSetParseResult parse(String raw) {
    final trimmed = raw.trim();
    final match = _pattern.firstMatch(trimmed);

    if (match == null) {
      return StrengthSetParseResult(
        raw: raw,
        weight: null,
        reps: null,
        rir: null,
        unit: 'unknown',
      );
    }

    final weightToken = match.group(1)?.toLowerCase();
    final explicitUnit = match.group(2)?.toLowerCase();
    final repsToken = match.group(3);
    final rirToken = match.group(4);

    if (weightToken == 'bw') {
      return StrengthSetParseResult(
        raw: raw,
        weight: null,
        reps: repsToken == null ? null : int.tryParse(repsToken),
        rir: rirToken == null ? null : int.tryParse(rirToken),
        unit: 'bw',
      );
    }

    final parsedWeight =
        weightToken == null ? null : double.tryParse(weightToken);
    final parsedReps = repsToken == null ? null : int.tryParse(repsToken);
    final parsedRir = rirToken == null ? null : int.tryParse(rirToken);

    return StrengthSetParseResult(
      raw: raw,
      weight: parsedWeight,
      reps: parsedReps,
      rir: parsedRir,
      unit: explicitUnit ?? 'unknown',
    );
  }

  static String format({
    required double? weight,
    required int? reps,
    required int? rir,
    required String unit,
  }) {
    if (reps == null) {
      return '';
    }
    final weightPart = switch (unit) {
      'bw' => 'BW',
      _ => weight == null
          ? 'unknown'
          : weight.toStringAsFixed(weight.truncateToDouble() == weight ? 0 : 1),
    };
    final rirPart = rir == null ? '' : 'r$rir';
    return '${weightPart}x$reps$rirPart';
  }
}
