import 'package:eatit/models/userModel.dart';
import 'package:eatit/ui/homeNavigationBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../services/platformService.dart';
import '../../services/userService.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _googleSignIn = GoogleSignIn();

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

      if (userCredential.user != null) {
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          // For new users, show a welcome message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Welcome! Your account has been created using Google.')),
          );

          // Store the user and navigate immediately
          await userService.storeUserInFirestore(userCredential.user!);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  HomeNavigationBar(user: userCredential.user!),
            ),
          );
        } else {
          // For existing users, show the dialog and exit early
          _showExistingGoogleAccountDialog(userCredential.user!);
          // return;
        }
        UserModel user = UserModel.fromFirebaseUser(userCredential.user!);
        UserService().storeUserLocally(user);
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

  void _showExistingGoogleAccountDialog(User user) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Ensures the dialog remains open until a selection is made
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Google Account Already Linked'),
          content: Text(
              'This Google account is already linked to an existing account. Would you like to continue with your existing account or use a different Google account?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Successfully signed in with Google!')),
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeNavigationBar(user: user),
                  ),
                );
              },
              child: Text('Continue with this Account'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close the dialog
                await _googleSignIn
                    .signOut(); // Sign out to allow account selection
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Please select a different Google account.')),
                );
              },
              child: Text('Use a Different Account'),
            ),
          ],
        );
      },
    );
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
