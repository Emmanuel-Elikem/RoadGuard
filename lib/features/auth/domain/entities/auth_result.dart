/// Authentication result types.
library;

import 'app_user.dart';

/// Represents the result of an authentication operation.
sealed class AuthResult {
  const AuthResult();
}

/// Successful authentication with a user.
class AuthSuccess extends AuthResult {
  final AppUser user;
  const AuthSuccess(this.user);
}

/// Password reset email sent successfully.
/// Does not include a user since no authentication occurred.
class PasswordResetEmailSent extends AuthResult {
  final String email;
  const PasswordResetEmailSent(this.email);
}

/// Email verification sent successfully.
class EmailVerificationSent extends AuthResult {
  const EmailVerificationSent();
}

/// Authentication failed with an error.
class AuthFailure extends AuthResult {
  final AuthError error;
  const AuthFailure(this.error);
}

/// Types of authentication errors.
enum AuthError {
  // Email/Password errors
  invalidEmail('Please enter a valid email address'),
  userDisabled('This account has been deactivated. Contact support for help.'),
  userNotFound('We couldn\'t find an account with that email'),
  wrongPassword('The password you entered is incorrect'),
  invalidCredential('The email or password you entered is incorrect'),
  emailAlreadyInUse('This email is already in use. Try signing in instead.'),
  weakPassword('Password must be at least 6 characters'),

  // Google Sign In errors
  googleSignInCancelled('Google sign-in was cancelled'),
  googleSignInFailed('Google sign-in didn\'t work. Please try again.'),
  accountExistsWithDifferentCredential(
    'This email is linked to a different sign-in method. Try another way.',
  ),
  credentialAlreadyInUse(
    'This sign-in is already connected to another account',
  ),

  // Account errors
  requiresRecentLogin('For security, please sign in again to continue'),

  // Network errors
  networkError('No internet connection. Please check and try again.'),
  tooManyRequests('Too many attempts. Please try again later'),

  // Generic errors
  operationNotAllowed('This sign-in option is not available right now'),
  unknown('Something went wrong. Please try again.');

  final String message;
  const AuthError(this.message);
}
