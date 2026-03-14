import 'package:adaptive_athlete/features/plan/biometrics_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('computePromptPayload is deterministic for valid input', () {
    const input = BiometricsInput(
      age: 32,
      sex: 'male',
      heightFt: 5,
      heightIn: 11,
      weightLb: 185,
      buildType: 'athletic',
    );

    final payload =
        BiometricsCalculator.computePromptPayload(input: input, daysPerWeek: 5);

    expect(
      payload,
      equals(<String, dynamic>{
        'age': 32,
        'sex': 'male',
        'height_ft_inchs': '5 ft 11 in',
        'weight_lb': 185.0,
        'build_type': 'athletic',
        'body_fat_percent': 21.1,
        'lean_mass_kg': 66.2,
        'bmi': 25.8,
        'estimated_bmr_kcal': 1811,
        'estimated_tdee_kcal': 2898,
      }),
    );
  });

  test('body fat is clamped and rounded deterministically', () {
    const input = BiometricsInput(
      age: 79,
      sex: 'female',
      heightFt: 4,
      heightIn: 10,
      weightLb: 280,
      buildType: 'fluffy',
    );

    final payload =
        BiometricsCalculator.computePromptPayload(input: input, daysPerWeek: 2);

    expect(payload['body_fat_percent'], 60.0);
    expect(payload['estimated_tdee_kcal'], isA<int>());
  });

  test('normalizeInputMap rejects invalid biometrics input', () {
    final normalized = BiometricsCalculator.normalizeInputMap(<String, dynamic>{
      'age': 8,
      'sex': 'male',
      'height_ft': 5,
      'height_in': 11,
      'weight_lb': 180.0,
      'build_type': 'lean',
    });

    expect(normalized, isNull);
  });
}
