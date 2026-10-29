class PlannerIssue {
  const PlannerIssue(this.message, this.recovery, {this.retryable = false});
  final String message;
  final String recovery;
  final bool retryable;

  factory PlannerIssue.from(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('401') || raw.contains('jwt') || raw.contains('session')) {
      return const PlannerIssue('Your sign-in needs attention.',
          'Your text is preserved. Sign in again, then retry.',
          retryable: true);
    }
    if (raw.contains('provider') ||
        raw.contains('502') ||
        raw.contains('503') ||
        raw.contains('429')) {
      return const PlannerIssue('The AI planner is temporarily unavailable.',
          'Retry later, or use Copy Prompt and paste the AI response here.',
          retryable: true);
    }
    if (raw.contains('timeout') ||
        raw.contains('socket') ||
        raw.contains('connection') ||
        raw.contains('network')) {
      return const PlannerIssue('The planner could not connect.',
          'Check your connection and retry. Your current plan and pasted text are preserved.',
          retryable: true);
    }
    if (raw.contains('ten_week') || raw.contains('long-term propagation')) {
      return const PlannerIssue('The ten-week plan section needs correction.',
          'Ask for ten consecutive weeks starting on the selected date. If you only want this week, turn off Propagate Long-term Changes.');
    }
    if (raw.contains('week_start') || raw.contains('week_end')) {
      return const PlannerIssue(
          'The response dates do not match the selected week.',
          'Choose the matching week or ask the AI to regenerate the response for your selected dates.');
    }
    return const PlannerIssue('The plan response could not be applied.',
        'Review the validation details, correct the response, then choose Check Response before applying.');
  }
}

class PlannerGenerationFailure implements Exception {
  const PlannerGenerationFailure(this.cause, this.generatedText);
  final Object cause;
  final String? generatedText;
  @override
  String toString() => cause.toString();
}
