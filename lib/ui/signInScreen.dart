import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eatit/models/userModel.dart';
import 'package:eatit/riverpods/familyriverpod.dart';
import 'package:eatit/ui/homeNavigationBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../services/platformService.dart';
import '../../services/userService.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  UserService userService = UserService();

  String? appVersion = PlatformService.getAppVersion() ?? 'NA';
  String? platform = PlatformService.getPlatform() ?? 'NA';

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
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 20),
              if (_isLoading)
                CircularProgressIndicator()
              else ...[
                ElevatedButton(
                  onPressed: _signInWithEmail,
                  child: Text('Sign In with Email'),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _signUpWithEmail,
                  child: Text('Sign Up with Email'),
                ),
                SizedBox(height: 20),
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
    setState(() {
      _isLoading = true;
    });

    try {
      await _googleSignIn.signOut(); // Ensure no previous session

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Sign-In canceled")),
        );
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Check if there's an existing Firestore user document
        UserModel? existingUser =
            await userService.getUserData(firebaseUser.email!);

        if (existingUser != null && (existingUser.isDeleted ?? false)) {
          // If exists and is marked as deleted, prompt the user.
          final result = await _showExistingGoogleAccountDialog(firebaseUser);
          if (result) {
            ref.invalidate(userFamiliesProvider(firebaseUser.email!));
            if (mounted) setState(() {});
          }
          return; // Let the dialog handle the next steps.
        }

        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          // For new users, show a welcome message.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Welcome! Your account has been created using Google.')),
          );
        }

        // For active accounts, update Firestore if needed.
        await userService.storeUserInFirestore(firebaseUser);
        UserModel user = UserModel.fromFirebaseUser(firebaseUser);
        await userService.storeUserLocally(user);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeNavigationBar(user: firebaseUser),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(e.message ?? 'Google sign-in failed. Please try again.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _showExistingGoogleAccountDialog(User firebaseUser) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false, // Force a selection.
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Restore or Create New Account?'),
          content: Text(
            'A previously deleted account was found for this Google account. '
            'Would you like to restore your old account (revive) or create a new one?',
          ),
          actions: [
            // Revive the old account (i.e. set isDeleted to false only)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(true); // Close the dialog.
                // Retrieve the existing user document first.
                UserModel? existingUser =
                    await userService.getUserData(firebaseUser.email!);
                if (existingUser != null) {
                  // For reviving, update only the isDeleted flag to false.
                  Map<String, dynamic> updatedData = existingUser.toJson();
                  updatedData['isDeleted'] = false; // Revive the account
                  await _firestore
                      .collection('users')
                      .doc(firebaseUser.email)
                      .update(updatedData);
                } else {
                  // In an unlikely case it disappeared, fallback to full store.
                  await userService.storeUserInFirestore(firebaseUser);
                }
                UserModel revivedUser =
                    UserModel.fromFirebaseUser(firebaseUser);
                await userService.storeUserLocally(revivedUser);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Your previous account has been revived.')),
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeNavigationBar(user: firebaseUser),
                  ),
                );
              },
              child: Text('Revive Old Account'),
            ),
            // Create new account (override old document)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(true); // Close the dialog.
                // Override the old record by calling storeUserInFirestore to create new account data.
                await userService.storeUserInFirestore(firebaseUser);
                UserModel newUser = UserModel.fromFirebaseUser(firebaseUser);
                await userService.storeUserLocally(newUser);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('A new account has been created.')),
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeNavigationBar(user: firebaseUser),
                  ),
                );
              },
              child: Text('Create New Account'),
            ),
          ],
        );
      },
    );
    return result;
  }

  /// ************
  /// these methods will be used later

  @Deprecated("will be used later")
  Future<void> _signInWithEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Successfully signed in with email!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeNavigationBar(user: userCredential.user!),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('No user found with this email. Please sign up.')),
        );
      } else if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Incorrect password. Please try again.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(e.message ?? 'An error occurred. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @Deprecated("will be used later")
  Future<void> _signUpWithEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Account Created Successfully")),
      );

      await userService.storeUserInFirestore(userCredential.user!);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeNavigationBar(user: userCredential.user!),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Email is already in use. Do you want to sign in or create a new account?'),
            action: SnackBarAction(
              label: 'Sign In',
              onPressed: () {
                _signInWithEmail();
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(e.message ?? 'An error occurred. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
