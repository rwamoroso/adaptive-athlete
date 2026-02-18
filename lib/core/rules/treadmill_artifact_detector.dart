class SegmentInput {
  const SegmentInput({
    required this.id,
    required this.idx,
    required this.speedMps,
    required this.durationS,
    required this.distanceM,
  });

  final String id;
  final int idx;
  final double? speedMps;
  final int? durationS;
  final double? distanceM;
}

class TreadmillArtifactFlag {
  const TreadmillArtifactFlag({
    required this.segmentId,
    required this.reason,
  });

  final String segmentId;
  final String reason;
}

class TreadmillArtifactResult {
  const TreadmillArtifactResult({
    required this.filtered,
    required this.flags,
    required this.excludedCount,
  });

  final List<SegmentInput> filtered;
  final List<TreadmillArtifactFlag> flags;
  final int excludedCount;
}

class TreadmillArtifactDetector {
  static const double maxSpeedMps = 12.0;
  static const double maxAdjacentDeltaMps = 4.0;

  static TreadmillArtifactResult filter(List<SegmentInput> segments) {
    if (segments.isEmpty) {
      return const TreadmillArtifactResult(
          filtered: <SegmentInput>[],
          flags: <TreadmillArtifactFlag>[],
          excludedCount: 0);
    }

    final sorted = [...segments]..sort((a, b) => a.idx.compareTo(b.idx));
    final filtered = <SegmentInput>[];
    final flags = <TreadmillArtifactFlag>[];

    for (var i = 0; i < sorted.length; i++) {
      final current = sorted[i];
      var artifact = false;

      if (current.speedMps != null && current.speedMps! > maxSpeedMps) {
        artifact = true;
        flags.add(TreadmillArtifactFlag(
            segmentId: current.id, reason: 'speed_above_12_mps'));
      }

      if (!artifact && i > 0) {
        final previous = sorted[i - 1];
        if (current.speedMps != null && previous.speedMps != null) {
          final delta = (current.speedMps! - previous.speedMps!).abs();
          if (delta > maxAdjacentDeltaMps) {
            artifact = true;
            flags.add(TreadmillArtifactFlag(
                segmentId: current.id,
                reason: 'adjacent_speed_delta_too_large'));
          }
        }
      }

      if (!artifact) {
        filtered.add(current);
      }
    }

    return TreadmillArtifactResult(
        filtered: filtered,
        flags: flags,
        excludedCount: sorted.length - filtered.length);
  }
}
