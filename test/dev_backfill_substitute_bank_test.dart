import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../scripts/backfill_substitute_bank.dart' as backfill;

void main() {
  test('backfills substitute bank into a real local app db', () async {
    final dbPath = Platform.environment['AA_BACKFILL_DB_PATH'];
    if (dbPath == null || dbPath.isEmpty) {
      // Intentionally no-op unless explicitly run with a real db path.
      // ignore: avoid_print
      print('Skipping: set AA_BACKFILL_DB_PATH to run this dev backfill test');
      return;
    }

    final result = await backfill.runBackfill(dbPath);
    // Print details for command-line visibility.
    // ignore: avoid_print
    print('BackfillResult('
        'planRows=${result.planRows}, '
        'groups=${result.distinctGroups}, '
        'groupsWithSuggestions=${result.groupsWithSuggestions}, '
        'writes=${result.suggestedRowWritesAttempted}, '
        'before=${result.beforeCount}, '
        'after=${result.afterCount})');

    expect(result.planRows, greaterThan(0));
  });
}
