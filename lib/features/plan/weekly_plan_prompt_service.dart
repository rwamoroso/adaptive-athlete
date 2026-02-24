import 'package:flutter/services.dart' show rootBundle;

import '../../db/app_db.dart';

class WeeklyPlanPromptService {
  WeeklyPlanPromptService({required this.db});

  final AppDb db;

  static const String weeklyPlanPromptTemplateKey = 'weekly_plan_workbook_text_v1';
  static const String weeklyPlanPromptAssetPath =
      'assets/prompts/weekly_plan_workbook_text_v1.md';
  static const String weeklyPlanPromptVersionTag = 'v1';

  Future<String> getDefaultPromptTemplate() async {
    return rootBundle.loadString(weeklyPlanPromptAssetPath);
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
