import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AppService _appService = AppService();

  String? appVersion;
  String? platform;
  bool loading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    _initializeAppInfo();
    _checkStoredUser(); // Check if a user is already stored locally
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

  /// Check if a user is already stored locally and navigate if so
  Future<void> _checkStoredUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('userEmail'); // Retrieve stored email

    if (email != null) {
      User? user = _auth.currentUser; // Check current Firebase auth state
      if (user != null && user.email == email) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeNavigationBar(user: user)),
        );
      }
    }
    setState(() {
      loading = false;
    });
  }

  Future<User?> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      bool userExists = await _checkUserExists(userCredential.user);
      if (userExists) {
        await _appService.storeUserLocally(userCredential.user); // Store user locally
        return userCredential.user;
      } else {
        await _appService.createUserInFirestore(userCredential.user);
        await _appService.storeUserLocally(userCredential.user); // Store user locally
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account Created Successfully")),
        );
        return userCredential.user;
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  /// Check if the user already exists in Firestore
  Future<bool> _checkUserExists(User? user) async {
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.email).get();
      return doc.exists;
    }
    return false;
  }

  void _handleSignIn() async {
    User? user = await _signInWithGoogle();
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeNavigationBar(user: user)),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sign In Successful")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to sign in or user cancelled.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      // Display a loading indicator or blank screen while loading is true
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
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
