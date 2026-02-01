/// Authentication repository interface - domain layer.
///
/// This defines WHAT authentication operations are available,
/// without specifying HOW they're implemented.
library;

import '../entities/entities.dart';

/// Abstract repository for authentication operations.
///
/// Implemented by FirebaseAuthRepository in the data layer.
abstract class AuthRepository {
  /// Stream of authentication state changes.
  ///
  /// Emits the current user when signed in, null when signed out.
  Stream<AppUser?> get authStateChanges;

  /// The currently signed-in user, or null if not signed in.
  AppUser? get currentUser;

  /// Whether a user is currently signed in.
  bool get isSignedIn;

  /// Sign in with email and password.
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  });

  /// Create a new account with email and password.
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Sign in with Google account.
  Future<AuthResult> signInWithGoogle();

  /// Sign in anonymously (guest mode).
  Future<AuthResult> signInAnonymously();

  /// Send password reset email.
  Future<AuthResult> sendPasswordResetEmail(String email);

  /// Send email verification to current user.
  Future<AuthResult> sendEmailVerification();

  /// Check if current user's email is verified.
  /// Returns true if verified, false otherwise.
  Future<bool> isEmailVerified();

  /// Reload current user to get fresh verification status.
  Future<void> reloadUser();

  /// Sign out the current user.
  Future<void> signOut();

  /// Link anonymous account with email/password.
  ///
  /// Allows a guest user to create a full account without losing data.
  Future<AuthResult> linkWithEmail({
    required String email,
    required String password,
  });

  /// Link anonymous account with Google.
  Future<AuthResult> linkWithGoogle();

  /// Delete the current user's account.
  Future<void> deleteAccount();
}
