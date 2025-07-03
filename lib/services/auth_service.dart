// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Keys for SharedPreferences
  static const String _kLoggedInKey = 'isLoggedIn';
  static const String _kUserUidKey = 'userUid';

  // Method to allow a user to Register with Us using email, username and a password
  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      if (userCredential.user != null) {
        // Set the display name
        await userCredential.user!.updateDisplayName(username.trim());

        // Store user data in Firestore using the user's UID as the document ID
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'username': username.trim(),
          'email': email.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Save login state after successful sign up
        await _saveLoginState(true, userCredential.user!.uid);
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('An unexpected error occurred during sign up: $e');
    }
  }

  // Method to allow a user to Login with Us using email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Save login state after successful sign in
      if (userCredential.user != null) {
        await _saveLoginState(true, userCredential.user!.uid);
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('An unexpected error occurred during sign in: $e');
    }
  }

  // NEW: Method to check if a user's profile exists in Firestore
  Future<bool> checkFirestoreProfileExists(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      return userDoc.exists;
    } catch (e) {
      print("Error checking Firestore profile for UID $uid: $e");
      // Depending on your error handling strategy, you might rethrow or return false
      return false; // Assume profile doesn't exist on error
    }
  }

  // --- Shared Preferences Management ---

  Future<void> _saveLoginState(bool isLoggedIn, String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedInKey, isLoggedIn);
    if (isLoggedIn && uid != null) {
      await prefs.setString(_kUserUidKey, uid);
    } else {
      await prefs.remove(_kUserUidKey);
    }
    print("Login state saved: isLoggedIn=$isLoggedIn, uid=$uid");
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLoggedInKey) ?? false;
  }

  Future<String?> getCurrentUserUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserUidKey);
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _saveLoginState(false, null); // Clear login state on logout
      print("User signed out and login state cleared.");
    } catch (e) {
      throw Exception('Error signing out: $e');
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
