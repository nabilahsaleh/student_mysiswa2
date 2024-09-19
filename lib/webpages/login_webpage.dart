import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:student_mysiswa2/webpages/home_webpage.dart';

class LoginWebPage extends StatefulWidget {
  const LoginWebPage({super.key});

  @override
  _LoginWebPageState createState() => _LoginWebPageState();
}

class _LoginWebPageState extends State<LoginWebPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Sign in with Google method
  Future<void> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Check if the sign-in was successful
      if (googleUser == null) {
        // Sign-in process was canceled by the user
        return;
      }

      // Check if the email ends with '@student.kptm.edu.my' before proceeding
      if (googleUser.email.endsWith('@student.kptm.edu.my')) {
        // Obtain the authentication details from the Google account
        GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Create a new credential with the Google account tokens
        AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase using the Google account credentials
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        User? user = userCredential.user;

        // Proceed only if the user is found
        if (user != null) {
          print('Signed in with Google: ${user.displayName}');
          // Navigate to the next screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    HomeWebPage()), // Replace with your next page
          );
        } else {
          print('Google Sign-In failed: No user found');
        }
      } else {
        // Email does not match the allowed domain
        await _googleSignIn.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Use your student email')),
        );
      }
    } catch (e) {
      // Handle any errors that might occur during sign-in
      print('Error signing in with Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing in: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Kad MySiswa', style: TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xFF9BBFDD),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth < 600
                  ? 20.0
                  : screenWidth < 1200
                      ? 100.0
                      : 500.0,
            ),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'SIGN IN',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await signInWithGoogle();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 37, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Colors.grey),
                        ),
                      ),
                      icon: Image.asset(
                        'assets/google_icon.png',
                        height: 24,
                      ),
                      label: const Text(
                        'Sign in with Google',
                        style: TextStyle(fontSize: 18, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
