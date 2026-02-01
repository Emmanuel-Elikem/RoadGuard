/// Firebase Auth data source - interfaces with Firebase Auth SDK.
///
/// This layer handles all Firebase-specific code, mapping Firebase
/// User objects to our domain AppUser entity.
library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/auth_repository.dart';

/// Firebase implementation of AuthRepository.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  bool _googleSignInInitialized = false;
  Completer<GoogleSignInAccount?>? _authCompleter;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = GoogleSignIn.instance;

  /// Initialize Google Sign In (must be called before using Google auth).
  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;

    await _googleSignIn.initialize();
    _googleSignInInitialized = true;
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
      return const AuthFailure(AuthError.unknown);
    }
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();

      // Check if authenticate is supported (not supported on web)
      if (!_googleSignIn.supportsAuthenticate()) {
        return const AuthFailure(AuthError.googleSignInFailed);
      }

      // Set up a completer to get the authentication result
      _authCompleter = Completer<GoogleSignInAccount?>();
      StreamSubscription<GoogleSignInAuthenticationEvent>? subscription;

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
      final googleUser = await _authCompleter!.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () => null,
      );

      if (googleUser == null) {
        return const AuthFailure(AuthError.googleSignInCancelled);
      }

      // Get auth credentials for Firebase
      final authorization = await googleUser.authorizationClient
          .authorizationForScopes(['email']);

      if (authorization == null) {
        // Request authorization
        final newAuth = await googleUser.authorizationClient
            .authorizeScopes(['email']);
        
        final credential = GoogleAuthProvider.credential(
          accessToken: newAuth.accessToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        return AuthSuccess(_mapUser(userCredential.user)!);
      }

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);
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
      // Return success with a placeholder user (email was sent)
      return AuthSuccess(AppUser(uid: '', email: email));
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
      if (user == null) {
        return const AuthFailure(AuthError.userNotFound);
      }
      if (user.emailVerified) {
        // Already verified, return success
        return AuthSuccess(_mapUser(user)!);
      }
      await user.sendEmailVerification();
      return AuthSuccess(_mapUser(user)!);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_mapFirebaseError(e));
    } catch (e) {
      return const AuthFailure(AuthError.unknown);
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
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

      await _ensureGoogleSignInInitialized();

      if (!_googleSignIn.supportsAuthenticate()) {
        return const AuthFailure(AuthError.googleSignInFailed);
      }

      // Set up completer for auth result
      _authCompleter = Completer<GoogleSignInAccount?>();
      StreamSubscription<GoogleSignInAuthenticationEvent>? subscription;

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

      await _googleSignIn.authenticate();

      final googleUser = await _authCompleter!.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () => null,
      );

      if (googleUser == null) {
        return const AuthFailure(AuthError.googleSignInCancelled);
      }

      final authorization = await googleUser.authorizationClient
          .authorizeScopes(['email']);

      final credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
      );

      final result = await user.linkWithCredential(credential);
      return AuthSuccess(_mapUser(result.user)!);
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
      'account-exists-with-different-credential' => AuthError.accountExistsWithDifferentCredential,
      'requires-recent-login' => AuthError.requiresRecentLogin,
      'credential-already-in-use' => AuthError.credentialAlreadyInUse,
      _ => AuthError.unknown,
    };
  }
}
