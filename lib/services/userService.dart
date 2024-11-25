import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eatit/models/userModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create user document in Firestore
  Future<void> createUserInFirestore(User? user) async {
    if (user != null) {
      try {
        final userModel = UserModel(
          displayName: user.displayName ?? '',
          email: user.email!,
          profilePhoto: user.photoURL,
          // phoneNumber: user.phoneNumber,
        );
        await _firestore.collection('users').doc(user.email).set(userModel.toMap());
      } catch (e) {
        print('Error creating user in Firestore: $e');
      }
    }
  }

  Future<void> storeUserLocally(User? user) async {
    if (user != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userEmail', user.email!);
      await prefs.setString('displayName', user.displayName ?? '');
    }
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('userData', jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> loadCachedUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('userData');
    return userDataString != null ? jsonDecode(userDataString) : null;
  }

  

 // Get user data
  Future<UserModel?> getUserData(String email) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _firestore.collection('users').doc(email).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      } else {
        print('No user found with email: $email');
        return null;
      }
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<UserModel?> getCachedUserData() async {
    return null; 
  }

  // Log out the current user
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  Future<void> deleteUserAccount(String email) async {
  try {
    await _firestore.collection('users').doc(email).delete();
    print('User account deleted successfully.');
  } catch (e) {
    print('Error deleting user account: $e');
    throw e; // Re-throw to handle errors in the UI
  }
 }
}
