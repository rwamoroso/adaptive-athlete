class ExerciseNormalizer {
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
  };

  static String normalize(String input) {
    final cleaned = input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
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
