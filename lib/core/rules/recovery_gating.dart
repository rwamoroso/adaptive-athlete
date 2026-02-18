class RecoveryGateResult {
  const RecoveryGateResult({
    required this.progressionAllowed,
    required this.reasoning,
    required this.flags,
  });

  final bool progressionAllowed;
  final String reasoning;
  final List<String> flags;
}

class RecoveryGating {
  static RecoveryGateResult evaluate(int? totalSleepMin) {
    if (totalSleepMin == null) {
      return const RecoveryGateResult(
        progressionAllowed: false,
        reasoning: 'sleep unknown',
        flags: ['sleep_unknown'],
      );
    }

    if (totalSleepMin < 360) {
      return const RecoveryGateResult(
        progressionAllowed: false,
        reasoning: 'total sleep < 6h',
        flags: ['low_sleep'],
      );
    }

    return const RecoveryGateResult(
      progressionAllowed: true,
      reasoning: 'recovery gate passed',
      flags: <String>[],
    );
  }
}
