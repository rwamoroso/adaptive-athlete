enum CardioActivity {
  run(
    label: 'Run',
    distancePolicy: CardioDistancePolicy.required,
  ),
  treadmillRun(
    label: 'Treadmill Run',
    distancePolicy: CardioDistancePolicy.required,
    usesTreadmill: true,
  ),
  stationaryBike(
    label: 'Stationary Bike',
    distancePolicy: CardioDistancePolicy.optional,
  ),
  outdoorBike(
    label: 'Outdoor Bike',
    distancePolicy: CardioDistancePolicy.recommended,
  ),
  stairStepper(
    label: 'Stairstepper',
    distancePolicy: CardioDistancePolicy.optional,
  );

  const CardioActivity({
    required this.label,
    required this.distancePolicy,
    this.usesTreadmill = false,
  });

  final String label;
  final CardioDistancePolicy distancePolicy;
  final bool usesTreadmill;

  bool get requiresDistance => distancePolicy == CardioDistancePolicy.required;

  /// Empty legacy activity fields were historically used for running entries.
  /// Explicit non-running types always stay out of running mileage and pace.
  static bool isRunningSession(
      {String? activityType, String? title, bool treadmill = false}) {
    final values = <String>[activityType ?? '', title ?? '']
        .map((v) => v.trim().toLowerCase())
        .where((v) => v.isNotEmpty)
        .toList();
    const nonRunning = [
      'bike',
      'cycling',
      'cycle',
      'ride',
      'spin',
      'stair',
      'stepper',
      'walk',
      'hike',
      'hiking',
      'rower',
      'rowing',
      'swim',
      'elliptical',
      'sled',
      'rope',
      'versa',
      'airdyne'
    ];
    if (values.any((v) => v == 'row' || nonRunning.any(v.contains))) {
      return false;
    }
    if (treadmill || values.isEmpty) return true;
    const running = [
      'run',
      'jog',
      'sprint',
      'treadmill',
      'easy',
      'tempo',
      'interval',
      'repeat',
      'fartlek',
      'recovery',
      'long',
      'threshold',
      'track',
      'hill',
      'stride'
    ];
    return values.any((v) => running.any(v.contains));
  }

  static CardioActivity infer({
    required Iterable<String?> candidates,
    bool treadmill = false,
  }) {
    if (treadmill) {
      return CardioActivity.treadmillRun;
    }

    final normalized = candidates
        .whereType<String>()
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    if (normalized.any((value) => value.contains('treadmill'))) {
      return CardioActivity.treadmillRun;
    }
    if (normalized.any(_isStationaryBike)) {
      return CardioActivity.stationaryBike;
    }
    if (normalized.any(_isOutdoorBike)) {
      return CardioActivity.outdoorBike;
    }
    if (normalized.any(
      (value) => value.contains('stair') || value.contains('stepper'),
    )) {
      return CardioActivity.stairStepper;
    }
    return CardioActivity.run;
  }

  static bool _isStationaryBike(String value) {
    const keywords = <String>[
      'stationary bike',
      'spin bike',
      'spin',
      'indoor bike',
      'exercise bike',
      'airdyne',
      'echo bike',
      'assault bike',
    ];
    return keywords.any(value.contains);
  }

  static bool _isOutdoorBike(String value) {
    if (_isStationaryBike(value)) {
      return false;
    }
    return value.contains('bike') ||
        value.contains('cycle') ||
        value.contains('cycling');
  }
}

enum CardioDistancePolicy { required, recommended, optional }
