import 'package:adaptive_athlete/core/parsing/strength_set_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses 180x10r2', () {
    final parsed = StrengthSetParser.parse('180x10r2');
    expect(parsed.weight, 180);
    expect(parsed.reps, 10);
    expect(parsed.rir, 2);
  });

  test('parses spaced input', () {
    final parsed = StrengthSetParser.parse('180 x 10 r2');
    expect(parsed.weight, 180);
    expect(parsed.reps, 10);
    expect(parsed.rir, 2);
  });

  test('parses BWx12r3', () {
    final parsed = StrengthSetParser.parse('BWx12r3');
    expect(parsed.weight, isNull);
    expect(parsed.unit, 'bw');
    expect(parsed.reps, 12);
    expect(parsed.rir, 3);
  });

  test('parses missing rir', () {
    final parsed = StrengthSetParser.parse('185x10');
    expect(parsed.weight, 185);
    expect(parsed.reps, 10);
    expect(parsed.rir, isNull);
  });
}
