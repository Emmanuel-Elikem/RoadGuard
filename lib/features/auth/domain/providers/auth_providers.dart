/// Authentication providers - Riverpod state management for auth.
///
/// These providers expose auth state throughout the app.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/storage_service.dart';
import '../../data/datasources/firebase_auth_datasource.dart';
import '../entities/entities.dart';
import '../repositories/auth_repository.dart';

/// Provides the auth repository instance.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// Stream of auth state changes.
///
/// Usage:
/// ```dart
/// final authState = ref.watch(authStateProvider);
/// authState.when(
///   data: (user) => user != null ? HomeScreen() : AuthScreen(),
///   loading: () => SplashScreen(),
///   error: (e, _) => ErrorScreen(),
/// );
/// ```
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// The currently signed-in user (synchronous access).
final currentUserProvider = Provider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull;
});

/// Whether a user is currently signed in.
final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// Whether the current user is a guest (anonymous).
final isGuestProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isAnonymous ?? false;
});

/// Authentication notifier for performing auth actions.
///
/// Usage:
/// ```dart
/// ref.read(authNotifierProvider.notifier).signInWithEmail(email, password);
/// ```
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

/// State for auth operations (loading, success, error).
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final AppUser user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthErrorState extends AuthState {
  final String message;
  final AuthError? error; // Store the actual error type for robust checking
  const AuthErrorState(this.message, {this.error});
}

/// Notifier that handles auth actions and state.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthInitial());

  /// Sign in with email and password.
  Future<bool> signInWithEmail(String email, String password) async {
    state = const AuthLoading();

    final result = await _repo.signInWithEmail(
      email: email,
      password: password,
    );

    return _handleResult(result);
  }

  /// Create account with email and password.
  Future<bool> signUpWithEmail(String email, String password) async {
    state = const AuthLoading();

    final result = await _repo.signUpWithEmail(
      email: email,
      password: password,
    );

    return _handleResult(result);
  }

  /// Sign in with Google.
  Future<bool> signInWithGoogle() async {
    state = const AuthLoading();

    final result = await _repo.signInWithGoogle();
    return _handleResult(result);
  }

  /// Sign in as guest (anonymous).
  Future<bool> signInAsGuest() async {
    state = const AuthLoading();

    final result = await _repo.signInAnonymously();
    return _handleResult(result);
  }

  /// Send password reset email.
  Future<bool> sendPasswordReset(String email) async {
    state = const AuthLoading();

    final result = await _repo.sendPasswordResetEmail(email);

    if (result is PasswordResetEmailSent) {
      state = const AuthInitial(); // Reset to initial, not authenticated
      return true;
    } else if (result is AuthFailure) {
      state = AuthErrorState(result.error.message);
      return false;
    }
    return false;
  }

  /// Send email verification to current user.
  Future<bool> sendEmailVerification() async {
    state = const AuthLoading();

    final result = await _repo.sendEmailVerification();

    if (result is EmailVerificationSent || result is AuthSuccess) {
      // Keep user authenticated, just sent verification
      final user = _repo.currentUser;
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = const AuthInitial();
      }
      return true;
    } else if (result is AuthFailure) {
      state = AuthErrorState(result.error.message);
      return false;
    }
    return false;
  }

  /// Check if email is verified and reload user state.
  Future<bool> checkEmailVerified() async {
    debugPrint('checkEmailVerified: Starting check...');
    final isVerified = await _repo.isEmailVerified();
    debugPrint('checkEmailVerified: isVerified = $isVerified');
    if (isVerified) {
      // Reload to get updated user
      final user = _repo.currentUser;
      debugPrint(
        'checkEmailVerified: Got user = ${user?.email}, emailVerified = ${user?.emailVerified}',
      );
      if (user != null) {
        state = AuthAuthenticated(user);
        debugPrint('checkEmailVerified: Set state to AuthAuthenticated');
      }
    }
    return isVerified;
  }

  /// Sign out and clear user session.
  Future<void> signOut() async {
    state = const AuthLoading();
    await StorageService.instance.clearUser();
    await _repo.signOut();
    state = const AuthUnauthenticated();
  }

  /// Link anonymous account with email.
  Future<bool> linkWithEmail(String email, String password) async {
    state = const AuthLoading();

    final result = await _repo.linkWithEmail(email: email, password: password);

    return _handleResult(result);
  }

  /// Link anonymous account with Google.
  Future<bool> linkWithGoogle() async {
    state = const AuthLoading();

    final result = await _repo.linkWithGoogle();
    return _handleResult(result);
  }

  /// Reset state to initial.
  void resetState() {
    state = const AuthInitial();
  }

  /// Handle auth result and update state.
  bool _handleResult(AuthResult result) {
    if (result is AuthSuccess) {
      state = AuthAuthenticated(result.user);
      return true;
    } else if (result is AuthFailure) {
      // Pass the error type for robust checking in UI
      state = AuthErrorState(result.error.message, error: result.error);
      return false;
    }
    return false;
  }
}
