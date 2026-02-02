/// Firebase Auth data source - interfaces with Firebase Auth SDK.
///
/// This layer handles all Firebase-specific code, mapping Firebase
/// User objects to our domain AppUser entity.
library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/auth_repository.dart';

/// Firebase implementation of AuthRepository.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  bool _googleSignInInitialized = false;
  Completer<GoogleSignInAccount?>? _authCompleter;

  FirebaseAuthRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = GoogleSignIn.instance;

  /// Initialize Google Sign In (must be called before using Google auth).
  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;

    await _googleSignIn.initialize();
    _googleSignInInitialized = true;
  }

  /// Common helper for Google authentication flow.
  /// Returns GoogleAuthCredential on success, or AuthFailure on error.
  /// This extracts the common logic between signInWithGoogle and linkWithGoogle.
  Future<({OAuthCredential? credential, AuthFailure? failure})>
  _getGoogleCredential() async {
    await _ensureGoogleSignInInitialized();

    // Check if authenticate is supported (not supported on web)
    if (!_googleSignIn.supportsAuthenticate()) {
      return (
        credential: null,
        failure: const AuthFailure(AuthError.googleSignInFailed),
      );
    }

    // Clean up any previous completer to prevent memory leaks
    _authCompleter = null;

    // Set up a new completer to get the authentication result
    _authCompleter = Completer<GoogleSignInAccount?>();
    StreamSubscription<GoogleSignInAuthenticationEvent>? subscription;

    GoogleSignInAccount? googleUser;
    try {
      subscription = _googleSignIn.authenticationEvents.listen(
        (event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            _authCompleter?.complete(event.user);
            subscription?.cancel();
          } else if (event is GoogleSignInAuthenticationEventSignOut) {
            _authCompleter?.complete(null);
            subscription?.cancel();
          }
        },
        onError: (error) {
          _authCompleter?.completeError(error);
          subscription?.cancel();
        },
      );

      // Trigger authentication
      await _googleSignIn.authenticate();

      // Wait for the result
      googleUser = await _authCompleter!.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () => null,
      );
    } finally {
      // Ensure subscription is always cancelled to prevent memory leaks
      await subscription?.cancel();
    }

    if (googleUser == null) {
      return (
        credential: null,
        failure: const AuthFailure(AuthError.googleSignInCancelled),
      );
    }

    // Get auth credentials for Firebase
    final authorization = await googleUser.authorizationClient
        .authorizationForScopes(['email']);

    if (authorization == null) {
      // Request authorization
      final newAuth = await googleUser.authorizationClient.authorizeScopes([
        'email',
      ]);

      final credential = GoogleAuthProvider.credential(
        accessToken: newAuth.accessToken,
      );
      return (credential: credential, failure: null);
    }

    // Create Firebase credential
    final credential = GoogleAuthProvider.credential(
      accessToken: authorization.accessToken,
    );
    return (credential: credential, failure: null);
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().map(_mapUser);
  }

  @override
  AppUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  bool get isSignedIn => _auth.currentUser != null;

  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthSuccess(_mapUser(credential.user)!);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_mapFirebaseError(e));
    } catch (e) {
      // Log unexpected error type for debugging
      debugPrint('Auth error type: ${e.runtimeType}, message: $e');
      // Try to extract error code from string for common Firebase errors
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('invalid-credential') ||
          errorString.contains('wrong-password')) {
        return const AuthFailure(AuthError.invalidCredential);
      } else if (errorString.contains('user-not-found')) {
        return const AuthFailure(AuthError.userNotFound);
      } else if (errorString.contains('too-many-requests') ||
          errorString.contains('blocked')) {
        return const AuthFailure(AuthError.tooManyRequests);
      } else if (errorString.contains('invalid-email')) {
        return const AuthFailure(AuthError.invalidEmail);
      } else if (errorString.contains('network')) {
        return const AuthFailure(AuthError.networkError);
      }
      return const AuthFailure(AuthError.unknown);
    }
  }

  @override
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthSuccess(_mapUser(credential.user)!);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_mapFirebaseError(e));
    } catch (e) {
      // Log unexpected error type for debugging
      debugPrint('Signup error type: ${e.runtimeType}, message: $e');
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('email-already-in-use')) {
        return const AuthFailure(AuthError.emailAlreadyInUse);
      } else if (errorString.contains('weak-password')) {
        return const AuthFailure(AuthError.weakPassword);
      } else if (errorString.contains('invalid-email')) {
        return const AuthFailure(AuthError.invalidEmail);
      } else if (errorString.contains('too-many-requests') ||
          errorString.contains('blocked')) {
        return const AuthFailure(AuthError.tooManyRequests);
      } else if (errorString.contains('network')) {
        return const AuthFailure(AuthError.networkError);
      }
      return const AuthFailure(AuthError.unknown);
    }
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      final result = await _getGoogleCredential();

      if (result.failure != null) {
        return result.failure!;
      }

      // Sign in to Firebase with credential
      final userCredential = await _auth.signInWithCredential(
        result.credential!,
      );
      return AuthSuccess(_mapUser(userCredential.user)!);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const AuthFailure(AuthError.googleSignInCancelled);
      }
      return const AuthFailure(AuthError.googleSignInFailed);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_mapFirebaseError(e));
    } catch (e) {
      return const AuthFailure(AuthError.googleSignInFailed);
    }
  }

  @override
  Future<AuthResult> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      return AuthSuccess(_mapUser(credential.user)!);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_mapFirebaseError(e));
    } catch (e) {
      return const AuthFailure(AuthError.unknown);
    }
  }

  @override
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      // Return specific result type for password reset (no user authentication occurred)
      return PasswordResetEmailSent(email.trim());
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_mapFirebaseError(e));
    } catch (e) {
      return const AuthFailure(AuthError.unknown);
    }
  }

  @override
  Future<AuthResult> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      debugPrint('sendEmailVerification: currentUser = ${user?.email}');
      if (user == null) {
        debugPrint('sendEmailVerification: ERROR - No user signed in');
        return const AuthFailure(AuthError.userNotFound);
      }
      debugPrint(
        'sendEmailVerification: emailVerified = ${user.emailVerified}',
      );
      if (user.emailVerified) {
        // Already verified, return success with user
        debugPrint('sendEmailVerification: Already verified, skipping');
        return AuthSuccess(_mapUser(user)!);
      }
      debugPrint(
        'sendEmailVerification: Calling Firebase sendEmailVerification...',
      );
      await user.sendEmailVerification();
      debugPrint(
        'sendEmailVerification: SUCCESS - Email sent to ${user.email}',
      );
      // Return specific result type for email verification sent
      return const EmailVerificationSent();
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'sendEmailVerification: FirebaseAuthException - ${e.code}: ${e.message}',
      );
      return AuthFailure(_mapFirebaseError(e));
    } catch (e) {
      debugPrint('sendEmailVerification: Unknown error - $e');
      return const AuthFailure(AuthError.unknown);
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    debugPrint('isEmailVerified: user = ${user?.email}');
    if (user == null) {
      debugPrint('isEmailVerified: No user, returning false');
      return false;
    }
    debugPrint('isEmailVerified: Before reload, emailVerified = ${user.emailVerified}');
    await user.reload();
    final reloadedUser = _auth.currentUser;
    debugPrint('isEmailVerified: After reload, emailVerified = ${reloadedUser?.emailVerified}');
    return reloadedUser?.emailVerified ?? false;
  }

  @override
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleSignInInitialized) {
      await _googleSignIn.disconnect();
    }
  }

  @override
  Future<AuthResult> linkWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const AuthFailure(AuthError.userNotFound);
      }

      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );

      final result = await user.linkWithCredential(credential);
      return AuthSuccess(_mapUser(result.user)!);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_mapFirebaseError(e));
    } catch (e) {
      return const AuthFailure(AuthError.unknown);
    }
  }

  @override
  Future<AuthResult> linkWithGoogle() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const AuthFailure(AuthError.userNotFound);
      }

      final result = await _getGoogleCredential();

      if (result.failure != null) {
        return result.failure!;
      }

      // Link with Firebase credential
      final linkResult = await user.linkWithCredential(result.credential!);
      return AuthSuccess(_mapUser(linkResult.user)!);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const AuthFailure(AuthError.googleSignInCancelled);
      }
      return const AuthFailure(AuthError.googleSignInFailed);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_mapFirebaseError(e));
    } catch (e) {
      return const AuthFailure(AuthError.googleSignInFailed);
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }

  /// Maps Firebase User to our domain AppUser.
  AppUser? _mapUser(User? user) {
    if (user == null) return null;

    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isAnonymous: user.isAnonymous,
      emailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime,
      lastSignInAt: user.metadata.lastSignInTime,
    );
  }

  /// Maps Firebase Auth errors to our AuthError enum.
  AuthError _mapFirebaseError(FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-email' => AuthError.invalidEmail,
      'user-disabled' => AuthError.userDisabled,
      'user-not-found' => AuthError.userNotFound,
      'wrong-password' => AuthError.wrongPassword,
      // Firebase now returns 'invalid-credential' for both wrong password and user not found
      'invalid-credential' => AuthError.invalidCredential,
      'email-already-in-use' => AuthError.emailAlreadyInUse,
      'weak-password' => AuthError.weakPassword,
      'operation-not-allowed' => AuthError.operationNotAllowed,
      'too-many-requests' => AuthError.tooManyRequests,
      'network-request-failed' => AuthError.networkError,
      'account-exists-with-different-credential' =>
        AuthError.accountExistsWithDifferentCredential,
      'requires-recent-login' => AuthError.requiresRecentLogin,
      'credential-already-in-use' => AuthError.credentialAlreadyInUse,
      _ => AuthError.unknown,
    };
  }
}
