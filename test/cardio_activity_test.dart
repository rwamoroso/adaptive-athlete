import 'package:adaptive_athlete/features/training/cardio_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CardioActivity.infer', () {
    test('recognizes common indoor bike names before generic bike names', () {
      for (final name in <String>[
        'Stationary Bike',
        'Spin class',
        'Echo Bike intervals',
        'Indoor Bike',
      ]) {
        expect(
          CardioActivity.infer(candidates: <String?>[name]),
          CardioActivity.stationaryBike,
        );
      }
    });

    test('recognizes outdoor cycling names', () {
      for (final name in <String>['Outdoor Bike', 'Road cycling', 'Cycle']) {
        expect(
          CardioActivity.infer(candidates: <String?>[name]),
          CardioActivity.outdoorBike,
        );
      }
    });

    test('uses explicit treadmill flag over text inference', () {
      expect(
        CardioActivity.infer(
          candidates: const <String?>['Outdoor Bike'],
          treadmill: true,
        ),
        CardioActivity.treadmillRun,
      );
    });
  });

  test('distance policies match activity behavior', () {
    expect(CardioActivity.run.distancePolicy, CardioDistancePolicy.required);
    expect(
      CardioActivity.stationaryBike.distancePolicy,
      CardioDistancePolicy.optional,
    );
    expect(
      CardioActivity.outdoorBike.distancePolicy,
      CardioDistancePolicy.recommended,
    );
  });
}
