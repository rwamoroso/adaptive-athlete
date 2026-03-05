import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_providers.dart';
import '../ui/clinical_widgets.dart';

class AiWeeklyExplanationScreen extends ConsumerWidget {
  const AiWeeklyExplanationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawResponse = ref.watch(aiWeeklyPlanResponseProvider);
    final explanation = _extractPlanExplanation(rawResponse);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        Text(
          'AI WEEKLY EXPLANATION',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        const ClinicalBanner(
          text:
              'Paste AI weekly response in Plan > Step 3. This tab presents the latest response and explanation.',
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(text: 'Latest AI Response'),
              const SizedBox(height: 8),
              SelectableText(
                rawResponse.trim().isEmpty
                    ? 'No AI response yet. Paste and apply from Plan > Step 3.'
                    : rawResponse.trim(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(text: 'Weekly Explanation'),
              const SizedBox(height: 8),
              if (explanation == null)
                const Text(
                  'No PLAN_EXPLANATION_V1 block found yet. Paste and apply AI response from Plan > Step 3.',
                )
              else ...[
                Text(
                  'Why am I training like this for the week?\n${explanation.whyThisWeek.isEmpty ? 'Not provided.' : explanation.whyThisWeek}',
                ),
                const SizedBox(height: 10),
                Text(
                  'What adaptation or growth does the week provide to my body?\n${explanation.adaptationOrGrowth.isEmpty ? 'Not provided.' : explanation.adaptationOrGrowth}',
                ),
                if (explanation.logicOverview.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Logic overview:\n${explanation.logicOverview}'),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanExplanationView {
  const _PlanExplanationView({
    required this.whyThisWeek,
    required this.adaptationOrGrowth,
    required this.logicOverview,
  });

  final String whyThisWeek;
  final String adaptationOrGrowth;
  final String logicOverview;
}

_PlanExplanationView? _extractPlanExplanation(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final lines = LineSplitter().convert(trimmed);
  final start = lines.indexWhere(
    (line) => line.trim().toUpperCase() == 'PLAN_EXPLANATION_V1',
  );
  if (start < 0) {
    return null;
  }

  var end = -1;
  for (var i = start + 1; i < lines.length; i++) {
    if (lines[i].trim().toUpperCase() == 'END_PLAN_EXPLANATION_V1') {
      end = i;
      break;
    }
  }
  final endIndex = end < 0 ? lines.length : end;

  String whyThisWeek = '';
  String adaptationOrGrowth = '';
  String logicOverview = '';

  for (var i = start + 1; i < endIndex; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) {
      continue;
    }
    final colon = line.indexOf(':');
    if (colon <= 0) {
      continue;
    }
    final key = line.substring(0, colon).trim().toUpperCase();
    final value = line.substring(colon + 1).trim();
    switch (key) {
      case 'WHY_THIS_WEEK':
        whyThisWeek = value;
        break;
      case 'ADAPTATION_OR_GROWTH':
        adaptationOrGrowth = value;
        break;
      case 'LOGIC_OVERVIEW':
        logicOverview = value;
        break;
    }
  }

  if (whyThisWeek.isEmpty &&
      adaptationOrGrowth.isEmpty &&
      logicOverview.isEmpty) {
    return null;
  }
  return _PlanExplanationView(
    whyThisWeek: whyThisWeek,
    adaptationOrGrowth: adaptationOrGrowth,
    logicOverview: logicOverview,
  );
}
