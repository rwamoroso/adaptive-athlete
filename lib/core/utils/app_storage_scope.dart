enum AppStorageScopeKind { guest, user }

class AppStorageScope {
  const AppStorageScope.guest()
      : kind = AppStorageScopeKind.guest,
        userId = null;

  const AppStorageScope.user(this.userId)
      : kind = AppStorageScopeKind.user,
        assert(userId != null && userId != '');

  final AppStorageScopeKind kind;
  final String? userId;

  bool get isGuest => kind == AppStorageScopeKind.guest;
  bool get isUser => kind == AppStorageScopeKind.user;

  String get scopeKey {
    if (isGuest) {
      return 'guest';
    }
    return 'user_${_sanitize(userId!)}';
  }

  String get databaseName => 'adaptive_athlete_$scopeKey.db';

  static String _sanitize(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  @override
  bool operator ==(Object other) {
    return other is AppStorageScope &&
        other.kind == kind &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(kind, userId);

  @override
  String toString() {
    if (isGuest) {
      return 'AppStorageScope.guest()';
    }
    return 'AppStorageScope.user($userId)';
  }
}
