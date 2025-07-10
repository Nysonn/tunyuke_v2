import 'package:firebase_auth/firebase_auth.dart';
import 'package:Tunyuke/services/auth_service.dart';

class LoginController {
  final AuthService _authService;
  final Function(String message) onSignInSuccess;
  final Function(String message) onSignInError;
  // Removed onNavigateToDashboard from controller's direct responsibility

  LoginController({
    required AuthService authService,
    required this.onSignInSuccess,
    required this.onSignInError,
    // No longer requiring onNavigateToDashboard as a direct parameter
  }) : _authService = authService;

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      onSignInSuccess("User signed in successfully!");
      // Don't navigate here. The UI (LoginScreen) will handle navigation
      // after it receives the success callback.
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided for that user.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else if (e.code == 'user-disabled') {
        message = 'This user account has been disabled.';
      } else {
        message = 'An error occurred during sign in: ${e.message}';
      }
      onSignInError(message);
    } catch (e) {
      onSignInError('An unexpected error occurred. Please try again.');
      print("Unexpected error during sign in in LoginController: $e");
    }
  }
}
