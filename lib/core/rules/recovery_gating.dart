enum RecoveryReadiness {
  ready,
  caution,
  insufficientData,
}

class RecoveryGateResult {
  const RecoveryGateResult({
    required this.readiness,
    required this.progressionAllowed,
    required this.reasoning,
    required this.flags,
  });

  final RecoveryReadiness readiness;
  final bool progressionAllowed;
  final String reasoning;
  final List<String> flags;

  String get label => switch (readiness) {
        RecoveryReadiness.ready => 'Ready',
        RecoveryReadiness.caution => 'Caution',
        RecoveryReadiness.insufficientData => 'Not enough data',
      };
}

class RecoveryGating {
  static RecoveryGateResult evaluate(int? totalSleepMin) {
    if (totalSleepMin == null) {
      return const RecoveryGateResult(
        readiness: RecoveryReadiness.insufficientData,
        progressionAllowed: false,
        reasoning: 'Add sleep or a recovery check-in for guidance',
        flags: ['sleep_unknown'],
      );
    }

    if (totalSleepMin < 360) {
      return const RecoveryGateResult(
        readiness: RecoveryReadiness.caution,
        progressionAllowed: false,
        reasoning: 'Less than 6 hours of sleep was logged',
        flags: ['low_sleep'],
      );
    }

    return const RecoveryGateResult(
      readiness: RecoveryReadiness.ready,
      progressionAllowed: true,
      reasoning: 'Sleep supports the planned session',
      flags: <String>[],
    );
  }
}
