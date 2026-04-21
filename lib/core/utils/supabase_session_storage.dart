import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class ResilientSupabaseLocalStorage extends LocalStorage {
  const ResilientSupabaseLocalStorage({required this.delegate});

  final LocalStorage delegate;

  @override
  Future<void> initialize() => delegate.initialize();

  @override
  Future<bool> hasAccessToken() => delegate.hasAccessToken();

  @override
  Future<String?> accessToken() async {
    final persistedSession = await delegate.accessToken();
    if (persistedSession == null || persistedSession.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(persistedSession);
      if (decoded is Map<String, dynamic> || decoded is Map) {
        return persistedSession;
      }
    } catch (_) {
      // Older or corrupted installs can leave a non-JSON auth token in
      // SharedPreferences. Clear it so the user can sign in normally.
    }

    await delegate.removePersistedSession();
    return null;
  }

  @override
  Future<void> removePersistedSession() => delegate.removePersistedSession();

  @override
  Future<void> persistSession(String persistSessionString) {
    return delegate.persistSession(persistSessionString);
  }
}
