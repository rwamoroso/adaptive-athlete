import 'package:adaptive_athlete/core/utils/app_providers.dart';
import 'package:adaptive_athlete/db/app_db.dart';
import 'package:adaptive_athlete/features/export/export_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Export Garmin filter shows cardio and running options',
      (tester) async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDbProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ExportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cardio Only'), findsOneWidget);
    expect(find.text('Running Only'), findsOneWidget);
    expect(find.text('All Activities'), findsNothing);
  });
}
