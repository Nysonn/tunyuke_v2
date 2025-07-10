import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Tunyuke/services/auth_service.dart';

class LoginController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _loginSuccess = false;
  bool get loginSuccess => _loginSuccess;

  Future<void> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    _loginSuccess = false;
    notifyListeners();
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      _loginSuccess = true;
      _errorMessage = null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        _errorMessage = 'Wrong password provided for that user.';
      } else if (e.code == 'invalid-email') {
        _errorMessage = 'The email address is not valid.';
      } else if (e.code == 'user-disabled') {
        _errorMessage = 'This user account has been disabled.';
      } else {
        _errorMessage = 'An error occurred during sign in:  ${e.message}';
      }
      _loginSuccess = false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _loginSuccess = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _loginSuccess = false;
    notifyListeners();
  }
}
