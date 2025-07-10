import 'package:firebase_auth/firebase_auth.dart';
import 'package:Tunyuke/services/auth_service.dart';

enum SignUpResult { success, error }

class RegisterController {
  final AuthService _authService;
  // Change callbacks to return a result or just indicate success/failure
  final Function(String message) onSignUpSuccess;
  final Function(String message) onSignUpError;
  // Removed onNavigateToLogin from controller's direct responsibility

  RegisterController({
    required AuthService authService,
    required this.onSignUpSuccess,
    required this.onSignUpError,
  }) : _authService = authService;

  Future<void> signUp({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      await _authService.signUpWithEmailAndPassword(email, password, username);
      onSignUpSuccess("User signed up successfully!");
      // Don't navigate here. The UI (RegisterScreen) will handle navigation
      // after it receives the success callback.
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else {
        message = 'An error occurred during sign up: ${e.message}';
      }
      onSignUpError(message);
    } catch (e) {
      onSignUpError('An unexpected error occurred. Please try again.');
      print("Unexpected error during sign up in RegisterController: $e");
    }
  }
}
