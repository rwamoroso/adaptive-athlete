import 'dart:math' as math;

const List<String> kBiometricsSexOptions = <String>[
  'male',
  'female',
  'other',
];

const List<String> kBiometricsBuildTypes = <String>[
  'skinny',
  'lean',
  'athletic',
  'average',
  'fluffy',
  'stocky',
  'muscular',
];

class BiometricsInput {
  const BiometricsInput({
    required this.age,
    required this.sex,
    required this.heightFt,
    required this.heightIn,
    required this.weightLb,
    required this.buildType,
  });

  final int age;
  final String sex;
  final int heightFt;
  final int heightIn;
  final double weightLb;
  final String buildType;

  Map<String, dynamic> toStorageJson() => <String, dynamic>{
        'age': age,
        'sex': sex,
        'height_ft': heightFt,
        'height_in': heightIn,
        'weight_lb': BiometricsCalculator.roundTo(weightLb, 1),
        'build_type': buildType,
      };
}

class BiometricsCalculator {
  static const Map<String, double> _buildTypeBodyFatAdjustment =
      <String, double>{
    'skinny': -4.0,
    'lean': -2.0,
    'athletic': -1.0,
    'average': 0.0,
    'stocky': 2.0,
    'fluffy': 4.0,
    'muscular': -3.0,
  };

  static BiometricsInput? parseInput(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final age = _asInt(raw['age']);
    final sex = '${raw['sex'] ?? ''}'.trim().toLowerCase();
    final heightFt = _asInt(raw['height_ft']);
    final heightIn = _asInt(raw['height_in']);
    final weightLb = _asDouble(raw['weight_lb']);
    final buildType = '${raw['build_type'] ?? ''}'.trim().toLowerCase();

    if (age == null || age < 10 || age > 120) {
      return null;
    }
    if (!kBiometricsSexOptions.contains(sex)) {
      return null;
    }
    if (heightFt == null || heightFt < 3 || heightFt > 8) {
      return null;
    }
    if (heightIn == null || heightIn < 0 || heightIn > 11) {
      return null;
    }
    if (weightLb == null || weightLb < 50 || weightLb > 700) {
      return null;
    }
    if (!kBiometricsBuildTypes.contains(buildType)) {
      return null;
    }

    return BiometricsInput(
      age: age,
      sex: sex,
      heightFt: heightFt,
      heightIn: heightIn,
      weightLb: weightLb,
      buildType: buildType,
    );
  }

  static Map<String, dynamic>? normalizeInputMap(Map<String, dynamic>? raw) {
    final parsed = parseInput(raw);
    if (parsed == null) {
      return null;
    }
    return parsed.toStorageJson();
  }

  static Map<String, dynamic>? computePromptPayloadFromMap({
    required Map<String, dynamic>? rawInput,
    required int daysPerWeek,
  }) {
    final parsed = parseInput(rawInput);
    if (parsed == null) {
      return null;
    }
    return computePromptPayload(input: parsed, daysPerWeek: daysPerWeek);
  }

  static Map<String, dynamic> computePromptPayload({
    required BiometricsInput input,
    required int daysPerWeek,
  }) {
    final totalInches = (input.heightFt * 12) + input.heightIn;
    final heightCm = totalInches * 2.54;
    final heightM = heightCm / 100.0;
    final weightKg = input.weightLb * 0.45359237;

    final bmi = weightKg / (heightM * heightM);
    final sexFlag = switch (input.sex) {
      'male' => 1.0,
      'female' => 0.0,
      _ => 0.5,
    };

    final baseBodyFat =
        (1.20 * bmi) + (0.23 * input.age) - (10.8 * sexFlag) - 5.4;
    final buildAdjustment = _buildTypeBodyFatAdjustment[input.buildType] ?? 0.0;
    final bodyFatPercent = _clamp(baseBodyFat + buildAdjustment, 3.0, 60.0);
    final leanMassKg = weightKg * (1 - (bodyFatPercent / 100.0));

    final sexConstant = switch (input.sex) {
      'male' => 5.0,
      'female' => -161.0,
      _ => -78.0,
    };
    final bmr =
        (10 * weightKg) + (6.25 * heightCm) - (5 * input.age) + sexConstant;
    final activityFactor = _activityFactorForDaysPerWeek(daysPerWeek);
    final tdee = bmr * activityFactor;

    return <String, dynamic>{
      'age': input.age,
      'sex': input.sex,
      'height_ft_inchs': formatHeightFtIn(input.heightFt, input.heightIn),
      'weight_lb': roundTo(input.weightLb, 1),
      'build_type': input.buildType,
      'body_fat_percent': roundTo(bodyFatPercent, 1),
      'lean_mass_kg': roundTo(leanMassKg, 1),
      'bmi': roundTo(bmi, 1),
      'estimated_bmr_kcal': bmr.round(),
      'estimated_tdee_kcal': tdee.round(),
    };
  }

  static String formatHeightFtIn(int ft, int inches) => '$ft ft $inches in';

  static String titleCaseLabel(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) {
      return '';
    }
    return normalized
        .split(RegExp(r'[_\s-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static double roundTo(double value, int precision) {
    final factor = math.pow(10, precision).toDouble();
    return (value * factor).round() / factor;
  }

  static int? _asInt(dynamic raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.round();
    }
    return int.tryParse('$raw');
  }

  static double? _asDouble(dynamic raw) {
    if (raw is double) {
      return raw;
    }
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse('$raw');
  }

  static double _clamp(double value, double minValue, double maxValue) {
    if (value < minValue) {
      return minValue;
    }
    if (value > maxValue) {
      return maxValue;
    }
    return value;
  }

  static double _activityFactorForDaysPerWeek(int daysPerWeek) {
    if (daysPerWeek <= 1) {
      return 1.2;
    }
    if (daysPerWeek == 2) {
      return 1.3;
    }
    if (daysPerWeek == 3) {
      return 1.4;
    }
    if (daysPerWeek == 4) {
      return 1.5;
    }
    if (daysPerWeek == 5) {
      return 1.6;
    }
    if (daysPerWeek == 6) {
      return 1.7;
    }
    return 1.75;
  }
}
