class ExerciseNormalizer {
  static const Set<String> _sectionPrefixes = {
    'core',
    'accessory',
    'warmup',
    'warm-up',
    'mobility',
    'finisher',
  };

  static const Map<String, String> _map = {
    'back squat': 'Back Squat',
    'squat': 'Back Squat',
    'bench': 'Bench Press',
    'bench press': 'Bench Press',
    'deadlift': 'Deadlift',
    'rdl': 'Romanian Deadlift',
    'romainian deadlift': 'Romanian Deadlift',
    'pull up': 'Pull Up',
    'pull-up': 'Pull Up',
    'seated leg curl': 'Seated Leg Curl',
    'seated leg curls': 'Seated Leg Curl',
    'sitting leg curl': 'Seated Leg Curl',
    'sitting leg curls': 'Seated Leg Curl',
    'lying leg curl': 'Lying Leg Curl',
    'lying leg curls': 'Lying Leg Curl',
    'kneeling leg curl': 'Kneeling Leg Curl',
    'kneeling leg curls': 'Kneeling Leg Curl',
    'standing leg curl': 'Standing Leg Curl',
    'standing leg curls': 'Standing Leg Curl',
  };

  static String normalize(String input) {
    var cleaned = input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final colonIdx = cleaned.indexOf(':');
    if (colonIdx > 0) {
      final prefix = cleaned.substring(0, colonIdx).trim();
      final remainder = cleaned.substring(colonIdx + 1).trim();
      if (_sectionPrefixes.contains(prefix) && remainder.isNotEmpty) {
        cleaned = remainder;
      }
    }
    if (cleaned.isEmpty) {
      return 'Unknown Exercise';
    }
    return _map[cleaned] ?? cleaned.split(' ').map(_titleCase).join(' ');
  }

  static List<String> get commonExercises =>
      _map.values.toSet().toList()..sort();

  static String _titleCase(String token) {
    if (token.isEmpty) {
      return token;
    }
    return token[0].toUpperCase() + token.substring(1);
  }
}
