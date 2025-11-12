import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';

class EmailSignInService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  
  User? get currentUser => _auth.currentUser;

  
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  
  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      log("Registration error: ${e.message}");
      rethrow; 
    }
  }

  
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      log("Sign in error: ${e.message}");
      rethrow;
    }
  }

  
  Future<void> signOut() async {
    await _auth.signOut();
  }

  
  String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
        return 'The email address or password is invalid.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}