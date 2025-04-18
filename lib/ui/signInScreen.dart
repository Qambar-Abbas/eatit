import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eatit/models/userModel.dart';
import 'package:eatit/ui/homeNavigationBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../services/platformService.dart';
import '../../services/userService.dart';
import '../services/riverpods/familyRiverpod.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  UserService userService = UserService();

  String? appVersion = PlatformService.getAppVersion();
  String? platform = PlatformService.getPlatform();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              if (_isLoading)
                CircularProgressIndicator()
              else ...[
                ElevatedButton(
                  onPressed: _signInWithGoogle,
                  child: Text('Sign In with Google'),
                ),
              ],
              Text('Version: $appVersion | Platform: $platform'),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    _setLoading(true);
    try {
      // Initiate the sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _showSnackBar("Google Sign-In canceled");
        return;
      }
      // Obtain auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase using the Google credentials
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        await _handleFirebaseOperations(user, userCredential);
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? 'Google sign-in failed. Please try again.');
    } catch (e) {
      _showSnackBar('An unexpected error occurred: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _handleFirebaseOperations(
      User firebaseUser, UserCredential userCredential) async {
    // Check for an existing Firestore user document
    final UserModel? existingUser =
        await userService.getUserData(firebaseUser.email!);

    // If an existing account is deleted, ask the user whether to revive it.
    if (existingUser != null && existingUser.isDeleted) {
      final bool shouldRevive =
          await _showExistingGoogleAccountDialog(firebaseUser);
      if (shouldRevive) {
        // set user isDeleted families to false here
        ref.invalidate(userFamiliesProvider(firebaseUser.email!));
        // Do not proceed further; navigation is already handled in the dialog flow.
        return;
      }
    }

    // Welcome message for new accounts
    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      await userService.storeUserInFirestore(firebaseUser);
      _showSnackBar('Welcome! Your account has been created using Google.');
    }

    // Update local and remote data for active accounts
    final UserModel user = UserModel.fromFirebaseUser(firebaseUser);
    ref.invalidate(userFamiliesProvider(user.email!));
    await userService.storeUserLocally(user);
    _navigateToHome(user);

  }

  Future<bool> _showExistingGoogleAccountDialog(User firebaseUser) async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restore or Create New Account?'),
          content: const Text(
            'A previously deleted account was found for this Google account. '
            'Would you like to restore your old account (revive) or create a new one?',
          ),
          actions: [
            // Revive Old Account
            TextButton(
              onPressed: () async {
                Navigator.of(context)
                    .pop(true); // Close the dialog and return true.
                await _reviveAccount(firebaseUser);
              },
              child: const Text('Revive Old Account'),
            ),
            // Create New Account
            TextButton(
              onPressed: () async {
                Navigator.of(context)
                    .pop(true); // Close the dialog and return true.
                await _createNewAccount(firebaseUser);
              },
              child: const Text('Create New Account'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Revives an existing (soft-deleted) account.
  Future<void> _reviveAccount(User firebaseUser) async {
    final String email = firebaseUser.email!;
    final UserModel? existingUser = await userService.getUserData(email);
    final DocumentReference userRef =
    _firestore.collection('users_collection').doc(email);

    if (existingUser != null) {
      // “Undelete” the existing record
      final Map<String, dynamic> updatedMap = existingUser.toMap()
        ..['isDeleted'] = false;
      await userRef.update(updatedMap);
    } else {
      // If no Firestore record exists, create one from the Firebase user
      await userService.storeUserInFirestore(firebaseUser);
    }

    // Store a fresh local copy (always un-deleted)
    final UserModel revivedUser = UserModel.fromFirebaseUser(firebaseUser);
    await userService.storeUserLocally(revivedUser);

    _showSnackBar('Your previous account has been revived.');
    _navigateToHome(revivedUser);
  }

  // Future<void> _reviveAccount(User firebaseUser) async {
  //   final UserModel? existingUser =
  //       await userService.getUserData(firebaseUser.email!);
  //   if (existingUser != null) {
  //     final Map<String, dynamic> updatedData = existingUser.toJson()
  //       ..['isDeleted'] = false;
  //     await _firestore
  //         .collection('users_collection')
  //         .doc(firebaseUser.email)
  //         .update(updatedData);
  //   } else {
  //     // Fallback if the record is missing.
  //     await userService.storeUserInFirestore(firebaseUser);
  //   }
  //   final UserModel revivedUser = UserModel.fromFirebaseUser(firebaseUser);
  //   await userService.storeUserLocally(revivedUser);
  //   _showSnackBar('Your previous account has been revived.');
  //   _navigateToHome(revivedUser);
  // }

  /// Creates a new account by overriding the old document.
  Future<void> _createNewAccount(User firebaseUser) async {
    await userService.storeUserInFirestore(firebaseUser);
    final UserModel newUser = UserModel.fromFirebaseUser(firebaseUser);
    await userService.storeUserLocally(newUser);
    _showSnackBar('A new account has been created.');
    _navigateToHome(newUser);
  }

  /// Helper method to navigate to the home screen.
  void _navigateToHome(UserModel user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeNavigationBar(user: user),
      ),
    );
  }

  /// Helper method to show a snackbar with a provided message.
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Helper method to update the loading state.
  void _setLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }
}
