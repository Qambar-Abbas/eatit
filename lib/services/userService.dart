import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eatit/models/familyModel.dart';
import 'package:eatit/models/userModel.dart';
import 'package:eatit/services/familyService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> storeUserInFirestore(User user) async {
    try {
      DocumentReference userRef =
          _firestore.collection('users').doc(user.email);
      UserModel userModel = UserModel(
        uid: user.uid,
        displayName: user.displayName,
        email: user.email,
        photoURL: user.photoURL,
        families: null,
        isDeleted: false,
      );

      await userRef.set(userModel.toJson(), SetOptions(merge: true));

      print("✅ User data stored successfully.");
    } catch (e) {
      print("❌ Error storing user in Firestore: $e");
    }
  }

  Future<void> updateUserFamilies({
    required String userEmail,
    required String familyCode,
    required bool add,
  }) async {
    final DocumentReference userDoc =
        _firestore.collection('users').doc(userEmail);

    try {
      if (add) {
        await userDoc.update({
          'families': FieldValue.arrayUnion([familyCode]),
        });
        print("✅ Family code '$familyCode' added for $userEmail.");
      } else {
        await userDoc.update({
          'families': FieldValue.arrayRemove([familyCode]),
        });
        print("✅ Family code '$familyCode' removed for $userEmail.");
      }
    } catch (e) {
      print("❌ Error updating user families: $e");
      rethrow;
    }
  }

  Future<UserModel?> getUserData(String email) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection('users').doc(email).get();
      return doc.exists ? UserModel.fromJson(doc.data()!) : null;
    } catch (e) {
      print("❌ Error fetching user data: $e");
      return null;
    }
  }

  Future<void> addFamilyToUser(String email, String familyCode) async {
    try {
      UserModel? user = await getUserData(email);
      if (user == null) throw Exception("User not found.");

      UserModel updatedUser = user.addFamily(familyCode);
      await _firestore
          .collection('users')
          .doc(email)
          .update(updatedUser.toJson());
      print("✅ Family added successfully.");
    } catch (e) {
      print("❌ Error adding family to user: $e");
      rethrow;
    }
  }

  Future<void> removeFamilyFromUser(String email, String familyCode) async {
    try {
      UserModel? user = await getUserData(email);
      if (user == null) throw Exception("User not found.");

      UserModel updatedUser = user.removeFamily(familyCode);
      await _firestore
          .collection('users')
          .doc(email)
          .update(updatedUser.toJson());
      print("✅ Family removed successfully.");
    } catch (e) {
      print("❌ Error removing family from user: $e");
      rethrow;
    }
  }

  Future<void> storeUserLocally(UserModel user) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userData', jsonEncode(user.toJson()));
      print("✅ User data stored locally.");
    } catch (e) {
      print("❌ Error storing user locally: $e");
    }
  }

  Future<UserModel?> loadCachedUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userDataString = prefs.getString('userData');

      return (userDataString != null)
          ? UserModel.fromJson(json.decode(userDataString))
          : null;
    } catch (e) {
      print("❌ Error loading cached user data: $e");
      return null;
    }
  }

  Future<String?> loadCachedUserEmail() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userDataString = prefs.getString('userData');

      if (userDataString != null) {
        var userData = UserModel.fromJson(json.decode(userDataString));
        return userData.email!;
      }
    } catch (e) {
      print("❌ Error loading cached user data: $e");
      return null;
    }
    return null;
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print("✅ User logged out and local data cleared.");
    } catch (e) {
      print("❌ Error logging out: $e");
    }
  }

  Future<void> deleteUserAccount() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user currently signed in.',
      );
    }

    final String email = user.email ?? '';

    try {
      await _firestore.collection('users').doc(email).update({
        'isDeleted': true,
      });

      final familiesSnapshot = await _firestore
          .collection('families')
          .where('members', arrayContains: {'email': email}).get();

      for (var familyDoc in familiesSnapshot.docs) {
        await FamilyService().removeMember(familyDoc.id, email);
      }

      final adminFamiliesSnapshot = await _firestore
          .collection('families')
          .where('adminEmail', isEqualTo: email)
          .get();

      for (var adminFamilyDoc in adminFamiliesSnapshot.docs) {
        await _firestore.collection('families').doc(adminFamilyDoc.id).delete();
      }

      await user.delete();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      print("✅ User account and all related data deleted successfully.");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw FirebaseAuthException(
          code: 'reauthentication-required',
          message: 'Please re-authenticate before deleting your account.',
        );
      } else {
        throw Exception('❌ Auth deletion failed: ${e.message}');
      }
    } catch (e) {
      print("❌ Unexpected error deleting user account: $e");
      rethrow;
    }
  }
}
