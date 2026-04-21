import 'package:flutter/services.dart' show rootBundle;

import '../../db/app_db.dart';

class WeeklyPlanPromptService {
  WeeklyPlanPromptService({required this.db});

  final AppDb db;

  static const String weeklyPlanPromptTemplateKey =
      'weekly_plan_workbook_text_v1';
  static const String weeklyPlanPromptAssetPath =
      'assets/prompts/weekly_plan_workbook_text_v1.md';
  static const String weeklyPlanPromptVersionTag = 'v1';
  static const String _fallbackPromptTemplate = '''
ADAPTIVE ATHLETE WEEKLY PLAN PROMPT (FALLBACK)

You are generating WEEK_PLAN_V1 output for the Adaptive Athlete app.
Return exactly one 7-day plan that is safe, practical, and progression-aware.

Formatting requirements:
- Use the app's expected WEEK_PLAN_V1 structure with 7 ordered days.
- Keep prescription language concise and actionable.
- Include recovery-aware loading decisions when fatigue or poor sleep is implied.
- Maintain consistency between run/cardio and strength prescriptions.
- If strength substitutions are required, provide clearly ranked alternatives with rationale.

Output only the plan content expected by the app, with no extra preamble.
''';

  Future<String> getDefaultPromptTemplate() async {
    try {
      final text = await rootBundle.loadString(weeklyPlanPromptAssetPath);
      if (text.trim().isNotEmpty) {
        return text;
      }
    } catch (_) {
      // Fall through to the built-in fallback template.
    }
    return _fallbackPromptTemplate;
  }

  Future<String?> getPromptOverride() async {
    final row = await db.getAppPromptTemplateByKey(weeklyPlanPromptTemplateKey);
    return row?.templateText;
  }

  Future<bool> hasPromptOverride() async {
    final row = await db.getAppPromptTemplateByKey(weeklyPlanPromptTemplateKey);
    return row != null && row.templateText.trim().isNotEmpty;
  }

  Future<String> getEffectivePromptTemplate() async {
    final override = await getPromptOverride();
    if (override != null && override.trim().isNotEmpty) {
      return override;
    }
    return getDefaultPromptTemplate();
  }

  Future<void> savePromptOverride(String text) async {
    await db.upsertAppPromptTemplate(
      templateKey: weeklyPlanPromptTemplateKey,
      templateText: text,
      source: 'user_override',
      versionTag: weeklyPlanPromptVersionTag,
    );
  }

  Future<void> clearPromptOverride() async {
    await db.deleteAppPromptTemplateByKey(weeklyPlanPromptTemplateKey);
  }
}
