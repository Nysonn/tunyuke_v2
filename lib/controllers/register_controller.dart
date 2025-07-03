import 'package:firebase_auth/firebase_auth.dart';
import 'package:Tunyuke/services/auth_service.dart';

class RegisterController {
  final AuthService _authService;
  final Function(String message) onSignUpSuccess;
  final Function(String message) onSignUpError;
  final Function() onNavigateToLogin;

  RegisterController({
    required AuthService authService,
    required this.onSignUpSuccess,
    required this.onSignUpError,
    required this.onNavigateToLogin,
  }) : _authService = authService;

  Future<void> signUp({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      await _authService.signUpWithEmailAndPassword(email, password, username);
      onSignUpSuccess("User signed up successfully!");
      onNavigateToLogin(); // Trigger navigation to login screen
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
