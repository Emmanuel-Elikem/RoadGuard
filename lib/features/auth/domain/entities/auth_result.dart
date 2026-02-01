/// Authentication result types.
library;

import 'app_user.dart';

/// Represents the result of an authentication operation.
sealed class AuthResult {
  const AuthResult();
}

/// Successful authentication.
class AuthSuccess extends AuthResult {
  final AppUser user;
  const AuthSuccess(this.user);
}

/// Authentication failed with an error.
class AuthFailure extends AuthResult {
  final AuthError error;
  const AuthFailure(this.error);
}

/// Types of authentication errors.
enum AuthError {
  // Email/Password errors
  invalidEmail('Invalid email address'),
  userDisabled('This account has been disabled'),
  userNotFound('No account found with this email'),
  wrongPassword('Incorrect password'),
  invalidCredential('Invalid email or password'),
  emailAlreadyInUse('An account already exists with this email'),
  weakPassword('Password must be at least 6 characters'),

  // Google Sign In errors
  googleSignInCancelled('Google sign in was cancelled'),
  googleSignInFailed('Google sign in failed. Please try again'),
  accountExistsWithDifferentCredential(
    'An account already exists with this email using a different sign-in method',
  ),
  credentialAlreadyInUse('This credential is already linked to another account'),

  // Account errors
  requiresRecentLogin('Please sign in again to perform this action'),

  // Network errors
  networkError('Network error. Check your connection'),
  tooManyRequests('Too many attempts. Please try again later'),

  // Generic errors
  operationNotAllowed('This sign in method is not enabled'),
  unknown('An unknown error occurred');

  final String message;
  const AuthError(this.message);
}
