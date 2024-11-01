import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../views/HomeNavigationBar.dart';
import 'appService.dart';
import '../views/sign_In_view.dart';

class SignInController {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppService _appService = AppService(); // Use the consolidated AppService

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      await _googleSignIn.signOut(); // Sign out before signing in again
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        final User? user = userCredential.user;

        if (user != null) {
          final userDoc = await _appService.getUserData(user.uid);
          if (userDoc != null) {
            _showExistingAccountDialog(context, user);
          } else {
            await _appService.createAccount(
                user.uid, user.email ?? '', user.displayName ?? '', user.photoURL ?? '');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => HomeNavigationBar(user: user)),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found')),
          );
        }
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: $e')),
      );
    }
  }

  void _showExistingAccountDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Account Already Exists'),
          content: const Text('An account with this email already exists. Choose an option:'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => HomeNavigationBar(user: user)),
                );
              },
              child: const Text('Continue with Existing Account'),
            ),
            TextButton(
              onPressed: () async {
                await user.delete();
                Navigator.pop(context);
                _googleSignIn.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SignInScreen()),
                );
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
