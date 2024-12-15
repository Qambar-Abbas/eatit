import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:eatit/services/userService.dart';
import 'ui/homeNavigationBar.dart';
import 'ui/signInScreen.dart';
import 'ui/theme.dart';
import 'models/userModel.dart';

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyClNt-wD3h2hH7-d9Z8VvOy8LUDneJMKXY",
      appId: "1:861621886960:android:331326c53ce6741fb7c735",
      messagingSenderId: "861621886960",
      projectId: "eatit-f68fb",
    ),
  );
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();

  UserModel? cachedUser = await UserService().loadCachedUserData();

  runApp(MyApp(userData: cachedUser));
}

class MyApp extends StatelessWidget {
  final UserModel? userData;

  const MyApp({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eat-It',
      theme: appTheme,
      home: userData == null
          ? const SignInScreen()
          : HomeNavigationBar(user: FirebaseAuth.instance.currentUser),
    );
  }
}
