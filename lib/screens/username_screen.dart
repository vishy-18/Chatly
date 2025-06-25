import 'package:chatly/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatly/screens/chat_home_screen.dart';

class UsernameScreen extends StatefulWidget {
  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isChecking = false;
  String? errorText;

  Future<void> _submitUsername() async {
    final username = _controller.text.trim();

    if (username.isEmpty || username.length < 3) {
      setState(() => errorText = 'Username must be at least 3 characters.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => isChecking = true);

    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    if (result.docs.isNotEmpty) {
      setState(() {
        errorText = 'Username already taken';
        isChecking = false;
      });
      return;
    }

    final user = AuthService().currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'username': username,
        'email': user.email,
        'photoURL': user.photoURL,
      }, SetOptions(merge: true)); // ✅ safer update

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ChatHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose Username'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Pick a unique username',
              style: GoogleFonts.poppins(fontSize: 20),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Username',
                errorText: errorText,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (errorText != null) {
                  setState(() => errorText = null);
                }
              },
            ),
            SizedBox(height: 20),
            isChecking
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _submitUsername,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
