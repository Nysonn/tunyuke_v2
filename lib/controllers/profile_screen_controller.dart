import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class ProfileScreenController extends ChangeNotifier {
  bool _isDisposed = false;

  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final ValueNotifier<String?> _userName = ValueNotifier<String?>(null);
  ValueNotifier<String?> get userName => _userName;

  final ValueNotifier<String?> _userEmail = ValueNotifier<String?>(null);
  ValueNotifier<String?> get userEmail => _userEmail;

  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);
  ValueNotifier<bool> get isLoading => _isLoading;

  final ValueNotifier<String?> _dataError = ValueNotifier<String?>(null);
  ValueNotifier<String?> get dataError => _dataError;

  final ValueNotifier<bool> _isLoggingOut = ValueNotifier<bool>(false);
  ValueNotifier<bool> get isLoggingOut => _isLoggingOut;

  ProfileScreenController();

  // Initialize and fetch user profile data
  Future<void> initialize() async {
    if (_isDisposed) return;

    _isLoading.value = true;
    _dataError.value = null;
    _safeNotifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get email from Firebase Auth
        _userEmail.value = user.email;

        // Get username from Firestore
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (_isDisposed) return;

        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data() as Map<String, dynamic>;
          _userName.value = userData['username'] ?? 'Unknown User';
        } else {
          _userName.value = user.displayName ?? 'Unknown User';
        }

        _dataError.value = null;
        print("Profile data loaded successfully");
      } else {
        _dataError.value = "No user found. Please log in again.";
        print("No current user found");
      }
    } catch (e) {
      if (_isDisposed) return;
      _dataError.value = "Error loading profile: $e";
      print("Error fetching profile data: $e");
    } finally {
      if (_isDisposed) return;
      _isLoading.value = false;
      _safeNotifyListeners();
    }
  }

  // Logout user
  Future<bool> logout() async {
    if (_isDisposed) return false;

    _isLoggingOut.value = true;
    _dataError.value = null;
    _safeNotifyListeners();

    try {
      // Sign out from Firebase and clear SharedPreferences
      await _authService.signOut();

      // Clear all local data
      _userName.value = null;
      _userEmail.value = null;

      print("User logged out successfully");
      return true;
    } catch (e) {
      if (_isDisposed) return false;
      _dataError.value = "Error logging out: $e";
      print("Error during logout: $e");
      return false;
    } finally {
      if (_isDisposed) return false;
      _isLoggingOut.value = false;
      _safeNotifyListeners();
    }
  }

  // Refresh profile data
  Future<void> refreshProfile() async {
    await initialize();
  }

  // Safe method to call notifyListeners only when appropriate
  void _safeNotifyListeners() {
    if (!_isDisposed &&
        WidgetsBinding.instance.schedulerPhase !=
            SchedulerPhase.persistentCallbacks) {
      notifyListeners();
    } else if (!_isDisposed) {
      // Schedule for after the current build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) {
          notifyListeners();
        }
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _userName.dispose();
    _userEmail.dispose();
    _isLoading.dispose();
    _dataError.dispose();
    _isLoggingOut.dispose();
    super.dispose();
  }
}
