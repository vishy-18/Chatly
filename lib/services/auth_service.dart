import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Conditionally set the clientId for web
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '201039766736-upd0pnv1jstote82dgna02euqgq75s92.apps.googleusercontent.com'
        : null,
  );

  /// Sign in with Google and ensure Firestore user document is created
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnapshot = await userDoc.get();

        // ✅ Create user doc if it doesn't exist
        if (!docSnapshot.exists) {
          await userDoc.set({
            'email': user.email,
            'username': null,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return user;
    } catch (e) {
      print('❌ Google Sign-In error: $e');
      return null;
    }
  }

  /// Sign out both from Google and Firebase
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Get the currently logged-in user
  User? get currentUser => _auth.currentUser;
}
