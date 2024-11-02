import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/appService.dart';
import 'HomeNavigationBar.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Initialize Firestore instance
  
  String? appVersion;
  String? platform;

  @override
  void initState() {
    super.initState();
    _initializeAppInfo();
  }

  /// Initialize app version and platform information
  void _initializeAppInfo() async {
    try {
      final version = await AppService.getAppVersion();
      final platformName = AppService.getPlatform();

      setState(() {
        appVersion = version;
        platform = platformName;
      });
    } catch (e) {
      print('Error retrieving app info: $e');
      setState(() {
        appVersion = 'Unavailable';
        platform = 'Unavailable';
      });
    }
  }

  Future<User?> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled the sign-in
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Check if user exists in Firestore before creating a new account
      bool userExists = await _checkUserExists(userCredential.user); // Check user existence
      if (userExists) {
        return userCredential.user; // User exists, return the user
      } else {
        await _createUserInFirestore(userCredential.user); // Create user in Firestore
        return userCredential.user; // Return the new user
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  /// Check if the user already exists in Firestore
  Future<bool> _checkUserExists(User? user) async { // New method to check user existence
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.email).get();
      return doc.exists; // Return true if the user document exists
    }
    return false; // Return false if user is null
  }

  /// Create user document in Firestore
  Future<void> _createUserInFirestore(User? user) async { // Updated to include user existence check
    if (user != null) {
      try {
        // Create user document with user details
        await _firestore.collection('users').doc(user.email).set({
          'uid': user.uid,
          'displayName': user.displayName,
          'email': user.email,
          'photoURL': user.photoURL,
          'createdAt': Timestamp.now(),
        });
         ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account Created Successfull")),
      );
      } catch (e) {
        print('Error creating user in Firestore: $e');
      }
    }
  }

  void _handleSignIn() async {
    User? user = await _signInWithGoogle();
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeNavigationBar(user: user)),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sign In Successfull")),
      );
    } else {
      // Inform the user that account creation failed or user cancelled
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to sign in or user cancelled.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign In with Google")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _handleSignIn,
              child: const Text("Sign In with Google"),
            ),
            const SizedBox(height: 20),
            Text("App Version: ${appVersion ?? 'Loading...'}"),
            Text("Platform: ${platform ?? 'Loading...'}"),
          ],
        ),
      ),
    );
  }
}
