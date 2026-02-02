/// RoadGuard user entity - domain layer representation.
///
/// This is the clean architecture domain entity. It's independent of
/// Firebase or any external service, making it easy to test and swap
/// implementations.
library;

/// Represents an authenticated user in the app.
class AppUser {
  /// Unique identifier from Firebase Auth.
  final String uid;

  /// User's email address (null for anonymous users).
  final String? email;

  /// Display name (from profile or Google account).
  final String? displayName;

  /// Profile photo URL (from Google or uploaded).
  final String? photoUrl;

  /// Whether the user signed in anonymously (guest mode).
  final bool isAnonymous;

  /// Whether the user's email has been verified.
  final bool emailVerified;

  /// When the account was created.
  final DateTime? createdAt;

  /// When the user last signed in.
  final DateTime? lastSignInAt;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
    this.emailVerified = false,
    this.createdAt,
    this.lastSignInAt,
  });

  /// Returns the display name, or email, or "Guest" as fallback.
  String get nameOrEmail => displayName ?? email ?? 'Guest';

  /// Returns initials for avatar placeholder.
  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return displayName![0].toUpperCase();
    }
    if (email != null && email!.isNotEmpty) {
      return email![0].toUpperCase();
    }
    return 'G';
  }

  /// Whether this is a full account (not anonymous).
  bool get hasAccount => !isAnonymous && email != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() => 'AppUser(uid: $uid, email: $email, name: $displayName)';
}
