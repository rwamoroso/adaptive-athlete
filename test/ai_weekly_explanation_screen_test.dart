import 'package:adaptive_athlete/core/utils/app_providers.dart';
import 'package:adaptive_athlete/features/ai/ai_weekly_explanation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders weekly explanation from shared AI response state',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(aiWeeklyPlanResponseProvider.notifier).state =
        'WEEK_PLAN_V1\n'
        'PLAN_EXPLANATION_V1\n'
        'WHY_THIS_WEEK: This week builds aerobic capacity.\n'
        'ADAPTATION_OR_GROWTH: Increases endurance and fatigue resistance.\n'
        'LOGIC_OVERVIEW: Progressive overload plus recovery spacing.\n'
        'END_PLAN_EXPLANATION_V1';

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: AiWeeklyExplanationScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'Why am I training like this for the week?\nThis week builds aerobic capacity.',
      ),
      findsOne,
    );
    expect(
      find.textContaining(
        'What adaptation or growth does the week provide to my body?\nIncreases endurance and fatigue resistance.',
      ),
      findsOne,
    );
    expect(
      find.textContaining(
        'Logic overview:\nProgressive overload plus recovery spacing.',
      ),
      findsOne,
    );
  });
}
