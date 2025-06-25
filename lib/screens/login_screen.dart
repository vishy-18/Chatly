import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatly/services/auth_service.dart';
import 'package:chatly/screens/chat_home_screen.dart';
import 'username_screen.dart';

class LoginScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  void _handleSignIn(BuildContext context) async {
    final user = await _authService.signInWithGoogle();
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()?['username'] != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ChatHomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => UsernameScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed. Try again.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.deepPurple.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Chatly',
              style: GoogleFonts.poppins(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Connect. Chat. Enjoy.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton.icon(
              icon: Image.asset('assets/google_logo.png', height: 24), // make sure to add Google icon
              label: Text(
                'Continue with Google',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () => _handleSignIn(context),
            ),
          ],
        ),
      ),
    );
  }
}
