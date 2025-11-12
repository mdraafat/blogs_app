import 'dart:developer';

import '../firebase/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleSignInService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isInitialized = false;

  
  User? get currentUser => _auth.currentUser;

  
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  
  Future<void> _initialize() async {
    if (!_isInitialized) {
      await _googleSignIn.initialize(
        clientId: Constants.serverClientId,
      );
      _isInitialized = true;
    }
  }

  
  Future<User?> signInWithGoogle() async {
    try {
      await _initialize();

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      final authorizationClient = googleUser.authorizationClient;
      
      GoogleSignInClientAuthorization? authorization = 
          await authorizationClient.authorizationForScopes(['email', 'profile']);
      
      String? accessToken = authorization?.accessToken;

      if (accessToken == null) {
        final retryAuthorization = await authorizationClient
            .authorizationForScopes(['email', 'profile']);
        accessToken = retryAuthorization?.accessToken;
        
        if (accessToken == null) {
          throw FirebaseAuthException(
            code: 'access-token-error',
            message: 'Failed to retrieve access token',
          );
        }
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        await _createUserDocument(user);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      log("Google sign in error: ${e.message}");
      rethrow;
    } catch (e) {
      log("Unexpected error during Google sign in: $e");
      rethrow;
    }
  }

  
  Future<void> _createUserDocument(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoURL': user.photoURL ?? '',
        'provider': 'google',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      log("Sign out error: $e");
      rethrow;
    }
  }

  
  String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}