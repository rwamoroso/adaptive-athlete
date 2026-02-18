import 'dart:convert';

class ExtractedDataSummary {
  const ExtractedDataSummary({
    required this.runsSummary,
    required this.sleepSummary,
    required this.strengthSummary,
  });

  final String runsSummary;
  final String sleepSummary;
  final String strengthSummary;

  Map<String, dynamic> toJson() => {
        'runs_summary': runsSummary,
        'sleep_summary': sleepSummary,
        'strength_summary': strengthSummary,
      };

  static ExtractedDataSummary fromJson(Map<String, dynamic> json) =>
      ExtractedDataSummary(
        runsSummary: json['runs_summary'] as String? ?? 'unknown',
        sleepSummary: json['sleep_summary'] as String? ?? 'unknown',
        strengthSummary: json['strength_summary'] as String? ?? 'unknown',
      );
}

class AiFlags {
  const AiFlags({
    required this.treadmillArtifactsDetected,
    required this.lowSleep,
    required this.missingMetrics,
  });

  final bool treadmillArtifactsDetected;
  final bool lowSleep;
  final bool missingMetrics;

  Map<String, dynamic> toJson() => {
        'treadmill_artifacts_detected': treadmillArtifactsDetected,
        'low_sleep': lowSleep,
        'missing_metrics': missingMetrics,
      };

  static AiFlags fromJson(Map<String, dynamic> json) => AiFlags(
        treadmillArtifactsDetected:
            json['treadmill_artifacts_detected'] as bool? ?? false,
        lowSleep: json['low_sleep'] as bool? ?? false,
        missingMetrics: json['missing_metrics'] as bool? ?? false,
      );
}

class PlanUpdate {
  const PlanUpdate({required this.date, required this.action});

  final String date;
  final String action;

  Map<String, dynamic> toJson() => {'date': date, 'action': action};

  static PlanUpdate fromJson(Map<String, dynamic> json) => PlanUpdate(
        date: json['date'] as String? ?? 'unknown',
        action: json['action'] as String? ?? 'unknown',
      );
}

class AiAuditPayload {
  const AiAuditPayload(
      {required this.dataUsedIds, required this.rulesTriggered});

  final List<String> dataUsedIds;
  final List<String> rulesTriggered;

  Map<String, dynamic> toJson() => {
        'data_used_ids': dataUsedIds,
        'rules_triggered': rulesTriggered,
      };

  static AiAuditPayload fromJson(Map<String, dynamic> json) => AiAuditPayload(
        dataUsedIds:
            (json['data_used_ids'] as List<dynamic>? ?? const <dynamic>[])
                .map((e) => e.toString())
                .toList(),
        rulesTriggered:
            (json['rules_triggered'] as List<dynamic>? ?? const <dynamic>[])
                .map((e) => e.toString())
                .toList(),
      );
}

class AiAnalyzeResponse {
  const AiAnalyzeResponse({
    required this.extractedDataSummary,
    required this.flags,
    required this.progressionAllowed,
    required this.reasoning,
    required this.planUpdates,
    required this.audit,
  });

  final ExtractedDataSummary extractedDataSummary;
  final AiFlags flags;
  final bool progressionAllowed;
  final String reasoning;
  final List<PlanUpdate> planUpdates;
  final AiAuditPayload audit;

  Map<String, dynamic> toJson() => {
        'extracted_data_summary': extractedDataSummary.toJson(),
        'flags': flags.toJson(),
        'progression_allowed': progressionAllowed,
        'reasoning': reasoning,
        'plan_updates': planUpdates.map((e) => e.toJson()).toList(),
        'audit': audit.toJson(),
      };

  static AiAnalyzeResponse fromJson(Map<String, dynamic> json) =>
      AiAnalyzeResponse(
        extractedDataSummary: ExtractedDataSummary.fromJson(
            json['extracted_data_summary'] as Map<String, dynamic>? ??
                const {}),
        flags: AiFlags.fromJson(
            json['flags'] as Map<String, dynamic>? ?? const {}),
        progressionAllowed: json['progression_allowed'] as bool? ?? false,
        reasoning: json['reasoning'] as String? ?? 'unknown',
        planUpdates:
            (json['plan_updates'] as List<dynamic>? ?? const <dynamic>[])
                .map((e) => PlanUpdate.fromJson(e as Map<String, dynamic>))
                .toList(),
        audit: AiAuditPayload.fromJson(
            json['audit'] as Map<String, dynamic>? ?? const {}),
      );

  String prettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

class AiAnalyzeRequest {
  const AiAnalyzeRequest({
    required this.date,
    required this.runsCount,
    required this.sleepMinutes,
    required this.strengthSetsCount,
    required this.treadmillExcludedSegments,
    required this.progressionAllowed,
    required this.progressionReasoning,
    required this.dataUsedIds,
    required this.rulesTriggered,
  });

  final String date;
  final int runsCount;
  final int? sleepMinutes;
  final int strengthSetsCount;
  final int treadmillExcludedSegments;
  final bool progressionAllowed;
  final String progressionReasoning;
  final List<String> dataUsedIds;
  final List<String> rulesTriggered;

  Map<String, dynamic> toSnapshotJson() => {
        'date': date,
        'runs_count': runsCount,
        'sleep_minutes': sleepMinutes,
        'strength_sets_count': strengthSetsCount,
        'treadmill_excluded_segments': treadmillExcludedSegments,
        'progression_allowed': progressionAllowed,
        'progression_reasoning': progressionReasoning,
      };
}

class AiAnalyzeService {
  const AiAnalyzeService();

  Future<AiAnalyzeResponse> analyze(AiAnalyzeRequest request) async {
    final sleepSummary = request.sleepMinutes == null
        ? 'unknown'
        : '${request.sleepMinutes} min';

    return AiAnalyzeResponse(
      extractedDataSummary: ExtractedDataSummary(
        runsSummary: request.runsCount == 0
            ? 'unknown'
            : '${request.runsCount} run session(s)',
        sleepSummary: sleepSummary,
        strengthSummary: request.strengthSetsCount == 0
            ? 'unknown'
            : '${request.strengthSetsCount} actual set(s)',
      ),
      flags: AiFlags(
        treadmillArtifactsDetected: request.treadmillExcludedSegments > 0,
        lowSleep: request.sleepMinutes != null && request.sleepMinutes! < 360,
        missingMetrics: request.sleepMinutes == null ||
            request.runsCount == 0 ||
            request.strengthSetsCount == 0,
      ),
      progressionAllowed: request.progressionAllowed,
      reasoning: request.progressionReasoning,
      planUpdates: <PlanUpdate>[
        PlanUpdate(
          date: request.date,
          action: request.progressionAllowed
              ? 'Maintain planned progression where prescribed values exist.'
              : 'Hold progression; no speed/load increase due to recovery gate.',
        ),
      ],
      audit: AiAuditPayload(
          dataUsedIds: request.dataUsedIds,
          rulesTriggered: request.rulesTriggered),
    );
  }
}
