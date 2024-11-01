import 'package:eatit/controllers/platform_controller.dart';
import 'package:flutter/material.dart';

import '../controllers/sign_in_controller.dart';

class SignInScreen extends StatelessWidget {
  final SignInController _controller = SignInController(); // Initialize SignInController
  final PlatformController _platformController = PlatformController(); // Initialize PlatformController

  SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _controller.signInWithGoogle(context), // Trigger sign-in action
              child: const Text('Sign in with Google'),
            ),
            FutureBuilder<String>(
              future: _platformController.getAppVersion(), // Get version from controller
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const Text('Error fetching version');
                } else if (snapshot.hasData) {
                  return Text(
                    'App Version: ${snapshot.data}',
                    style: const TextStyle(fontSize: 16),
                  );
                } else {
                  return const Text('App Version: Unknown',
                      style: TextStyle(fontSize: 16));
                }
              },
            ),
            FutureBuilder<String>(
              future: Future.value(_platformController.getPlatformName()), // Display platform type
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const Text('Error fetching platform');
                } else if (snapshot.hasData) {
                  return Text(
                    'Platform: ${snapshot.data}',
                    style: const TextStyle(fontSize: 16),
                  );
                } else {
                  return const Text('Platform: Unknown',
                      style: TextStyle(fontSize: 16));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
