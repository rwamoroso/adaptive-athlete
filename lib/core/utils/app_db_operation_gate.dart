import 'dart:async';

import '../../db/app_db.dart';

/// Serializes HealthKit writes and cloud sync operations for one database.
class AppDbOperationGate {
  AppDbOperationGate._();

  static final Map<String, Future<void>> _tails = <String, Future<void>>{};

  static Future<T> run<T>(AppDb db, Future<T> Function() operation) async {
    // Multiple AppDb objects can briefly point at the same file while the app
    // switches from guest to signed-in providers. Serialize by file name so
    // those connections share the same gate.
    final key = db.scope.databaseName;
    final previous = _tails[key];
    final release = Completer<void>();
    final tail = release.future;
    _tails[key] = tail;
    try {
      await previous;
      return await operation();
    } finally {
      release.complete();
      if (identical(_tails[key], tail)) _tails.remove(key);
    }
  }
}
