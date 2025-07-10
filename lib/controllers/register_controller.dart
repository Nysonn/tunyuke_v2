import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Tunyuke/services/auth_service.dart';

enum SignUpResult { success, error }

class RegisterController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _signUpSuccess = false;
  bool get signUpSuccess => _signUpSuccess;

  Future<void> signUp({
    required String email,
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _signUpSuccess = false;
    notifyListeners();
    try {
      await _authService.signUpWithEmailAndPassword(email, password, username);
      _signUpSuccess = true;
      _errorMessage = null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        _errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        _errorMessage = 'The account already exists for that email.';
      } else {
        _errorMessage = 'An error occurred during sign up:  e.message}';
      }
      _signUpSuccess = false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _signUpSuccess = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _signUpSuccess = false;
    notifyListeners();
  }
}
