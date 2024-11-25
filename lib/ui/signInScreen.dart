import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/firestoreService.dart';
import '../services/platformService.dart';
import '../services/userService.dart';
import 'homeNavigationBar.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();
  final UserService _userService = UserService();

  String appVersion = 'Loading...';
  String platform = 'Loading...';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _initializeAppInfo();
  }

  /// Initialize app version and platform information
  Future<void> _initializeAppInfo() async {
    try {
      final version = await PlatformService.getAppVersion();
      final platformName = PlatformService.getPlatform();

      setState(() {
        appVersion = version;
        platform = platformName;
        loading = false;
      });
    } catch (e) {
      print('Error retrieving app info: $e');
      setState(() {
        appVersion = 'Unavailable';
        platform = 'Unavailable';
        loading = false;
      });
    }
  }

  Future<User?> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-in canceled')),
        );
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-in failed, please try again.')),
        );
        return null;
      }

      final bool userExists = await _firestoreService.checkUserExists(user) ?? false;

      if (userExists) {
        final proceed = await _showConfirmationDialog(
          title: 'Existing Account',
          content: 'Do you want to continue with your existing account?',
        );

        if (proceed) {
          await _userService.storeUserLocally(user);
          return user;
        } else {
          return null; // User canceled
        }
      } else {
        final createAccount = await _showConfirmationDialog(
          title: 'Create New Account',
          content: 'This account does not exist. Do you want to create a new account?',
        );

        if (createAccount) {
          await _userService.createUserInFirestore(user); // Create new account
          await _userService.storeUserLocally(user);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account Created Successfully')),
          );
          return user;
        } else {
          return null; // User canceled account creation
        }
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign-in failed, please try again.')),
      );
      return null;
    }
  }

  Future<bool> _showConfirmationDialog({required String title, required String content}) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false; // Default to false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () async {
                User? user = await _signInWithGoogle();
                if (user != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeNavigationBar(user: user),
                    ),
                  );
                }
              },
              child: const Text('Sign in with Google'),
            ),
          ),
          Text('Version: $appVersion | Platform: $platform'),
        ],
      ),
    );
  }
}
