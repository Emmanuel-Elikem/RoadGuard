import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Authentication {
  // user profile stream
  Stream<User?> get authStateChanges =>
      FirebaseAuth.instance.authStateChanges();

  // google sign in
  Future<bool> signWithGoogle() async {
    try {
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

      if (gUser == null) {
        // The user canceled the sign-in process
        return false;
      }

      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // If user is successfully signed in
      return userCredential.user != null;
    } catch (e) {
      print('Error signing in with Google: $e');
      return false;
    }
  }

  // create account with email and password
  Future<String> createAccount(
      {required String emailAddress, required String password}) async {
    try {
      // Attempt to create a user account
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailAddress,
        password: password,
      );

      // Return success if the account is created
      return 'success';
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth exceptions
      switch (e.code) {
        case 'email-already-in-use':
          return 'The email is already in use.';

        case 'invalid-email':
          return 'The email address is badly formatted.';

        case 'operation-not-allowed':
          return 'Operation not allowed.';

        case 'weak-password':
          return 'The password is too weak.';

        case 'network-request-failed':
          return 'Network request failed.';

        // Default case for other FirebaseAuth exceptions
        default:
          return 'Error: ${e.message}';
      }
    } catch (e) {
      // Catch any unexpected errors and return the error message
      return e.toString();
    }
  }

  // sigin a user
  Future<String> signInUser(
      {required String emailAddress, required String password}) async {
    String error = '';
    try {
      // Attempt to sign in the user
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: emailAddress, password: password);

      // Return success if sign-in is successful
      return 'success';
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth exceptions
      switch (e.code) {
        case 'user-not-found':
          error = 'No user found for that email.';
          break;

        case 'wrong-password':
          error = 'Wrong password provided for that user.';
          break;

        case 'invalid-email':
          error = 'The email address is badly formatted.';
          break;

        case 'email-already-in-use':
          error = 'The email is already in use.';
          break;

        case 'operation-not-allowed':
          error = 'Operation not allowed.';
          break;

        case 'network-request-failed':
          error = 'Network request failed.';
          break;

        // Default case for unexpected errors
        default:
          error = '${e.message}';
      }
    }
    return error;
  }
}
