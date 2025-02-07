import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eatit/models/userModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'familyService.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createUserInFirestore(User? user) async {
    if (user != null) {
      try {
        final userModel = UserModel(
          displayName: user.displayName ?? '',
          email: user.email!,
          profileImageBase64: user.photoURL,
        );
        await _firestore
            .collection('users')
            .doc(user.email)
            .set(userModel.toJson());
      } catch (e) {
        print('Error creating user in Firestore: $e');
        rethrow;
      }
    }
  }

  Future<String?> convertProfileImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return null;

      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        return bytes.isNotEmpty ? base64Encode(bytes) : null;
      } else {
        print('Failed to load image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching or converting image: $e');
      return null;
    }
  }

  Future<void> updateFamilyList(String userEmail, String familyCode) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(userEmail);

      DocumentSnapshot userSnapshot = await userRef.get();

      if (userSnapshot.exists) {
        UserModel user =
            UserModel.fromJson(userSnapshot.data() as Map<String, dynamic>);

        user.familyList ??= [];
        if (!user.familyList!.contains(familyCode)) {
          user.familyList!.add(familyCode);
        }

        await userRef.update({'familyList': user.familyList});
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      print('Error updating family list: $e');
      rethrow;
    }
  }

  Future<void> storeUserLocally(User? user) async {
    if (user != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var profileBase64EncodeImage = await convertProfileImage(user.photoURL!);
      UserModel userModel = UserModel(
          displayName: user.displayName!,
          email: user.email!,
          profileImageBase64: profileBase64EncodeImage);
      await prefs.setString('userEmail', user.email!);
      await prefs.setString('displayName', user.displayName ?? '');
      await prefs.setString('userData', jsonEncode(userModel));
    }
  }

  Future<UserModel?> loadCachedUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('userData');

    if (userDataString != null) {
      Map<String, dynamic> jsonMap = json.decode(userDataString);
      UserModel user = UserModel.fromJson(jsonMap);
      return user;
    }
    return null;
  }

  Future<UserModel?> getUserData(String email) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection('users').doc(email).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      } else {
        print('No user found with email: $email');
        return null;
      }
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('userEmail');
      await prefs.remove('displayName');
      await prefs.remove('userData');

      print("User logged out and shared preferences cleared.");
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  Future<void> updateUserInFireBase(
      String generatedFamilyCode, UserModel user) async {
    user.addFamily(generatedFamilyCode);
    if (user.email != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.email)
            .update(user.toJson());
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userData', jsonEncode(user));
      } catch (e) {
        print('Error updating user in Firestore: $e');
        rethrow;
      }
    } else {
      print('User email is required to update user data.');
    }
  }

  Future<void> deleteUserAccount(String email) async {
    try {
      QuerySnapshot memberFamiliesSnapshot = await _firestore
          .collection('families')
          .where('members.$email', isNull: false)
          .get();

      for (var familyDoc in memberFamiliesSnapshot.docs) {
        String familyCode = familyDoc.id;
        await FamilyService().removeMember(familyCode, email);

        DocumentSnapshot updatedFamilySnapshot =
            await _firestore.collection('families').doc(familyCode).get();

        if (updatedFamilySnapshot.exists &&
            (updatedFamilySnapshot.data() as Map<String, dynamic>)['members']
                .isEmpty) {
          await _firestore.collection('families').doc(familyCode).delete();
          print('Deleted empty family document: $familyCode.');
        }
      }

      QuerySnapshot adminFamilySnapshot = await _firestore
          .collection('families')
          .where('adminEmail', isEqualTo: email)
          .get();

      for (var adminFamilyDoc in adminFamilySnapshot.docs) {
        String adminFamilyCode = adminFamilyDoc.id;
        await _firestore.collection('families').doc(adminFamilyCode).delete();
        print('Deleted admin family: $adminFamilyCode.');
      }

      await _firestore.collection('users').doc(email).delete();
      print('User account deleted successfully.');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('userEmail');
      await prefs.remove('displayName');
      await prefs.remove('userData');
    } catch (e) {
      print('Error deleting user account: $e');
      rethrow;
    }
  }

}
