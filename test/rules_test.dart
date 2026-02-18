import 'package:adaptive_athlete/core/rules/recovery_gating.dart';
import 'package:adaptive_athlete/core/rules/treadmill_artifact_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recovery gate blocks when sleep unknown', () {
    final result = RecoveryGating.evaluate(null);
    expect(result.progressionAllowed, isFalse);
    expect(result.reasoning, 'sleep unknown');
  });

  test('recovery gate blocks when sleep below 6h', () {
    final result = RecoveryGating.evaluate(300);
    expect(result.progressionAllowed, isFalse);
  });

  test('recovery gate allows when sleep sufficient', () {
    final result = RecoveryGating.evaluate(420);
    expect(result.progressionAllowed, isTrue);
  });

  test('artifact detector excludes impossible speed', () {
    final result = TreadmillArtifactDetector.filter(const [
      SegmentInput(id: '1', idx: 0, speedMps: 3, durationS: 60, distanceM: 180),
      SegmentInput(
          id: '2', idx: 1, speedMps: 13, durationS: 60, distanceM: 780),
    ]);

    expect(result.excludedCount, 1);
    expect(result.filtered.length, 1);
  });
}
