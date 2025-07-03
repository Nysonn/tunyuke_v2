import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Get an instance of Firestore

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
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Method to allow users sign in with email and password.
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e; // Re-throw the Firebase Auth exception to be caught by the UI
    } catch (e) {
      throw Exception(
        'An unexpected error occurred: $e',
      ); // Re-throw general exceptions
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
