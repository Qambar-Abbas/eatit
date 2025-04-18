import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eatit/models/userModel.dart';
import 'package:eatit/services/familyService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stores or merges a [UserModel] in Firestore
  Future<void> storeUserInFirestore(User user) async {
    try {
      final userRef =
      _firestore.collection('users_collection').doc(user.email);
      final userModel = UserModel(
        uid: user.uid,
        displayName: user.displayName,
        email: user.email,
        photoURL: user.photoURL,
      );

      await userRef.set(userModel.toMap(), SetOptions(merge: true));
      print("✅ User data stored successfully.");
    } catch (e) {
      print("❌ Error storing user in Firestore: $e");
    }
  }

  /// Adds or removes a family code from a user's document
  Future<void> addOrRemoveUserFamilies({
    required String userEmail,
    required String familyCode,
    required bool add,
  }) async {
    final userDoc =
    _firestore.collection('users_collection').doc(userEmail);

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

  /// Retrieves user data from Firestore and converts to [UserModel]
  Future<UserModel?> getUserData(String email) async {
    try {
      final doc = await _firestore
          .collection('users_collection')
          .doc(email)
          .get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return UserModel.fromMap(data);
    } catch (e) {
      print("❌ Error fetching user data: $e");
      return null;
    }
  }

  /// Adds a single family to the user's local model and Firestore
  Future<void> addFamilyToUser(String email, String familyCode) async {
    try {
      final user = await getUserData(email);
      if (user == null) throw Exception("User not found.");

      final updated = user.addFamily(familyCode);
      await _firestore
          .collection('users_collection')
          .doc(email)
          .update(updated.toMap());
      print("✅ Family added successfully.");
    } catch (e) {
      print("❌ Error adding family to user: $e");
      rethrow;
    }
  }

  /// Removes a single family from the user's local model and Firestore
  Future<void> removeFamilyFromUser(String email, String familyCode) async {
    try {
      final user = await getUserData(email);
      if (user == null) throw Exception("User not found.");

      final updated = user.removeFamily(familyCode);
      await _firestore
          .collection('users_collection')
          .doc(email)
          .update(updated.toMap());
      print("✅ Family removed successfully.");
    } catch (e) {
      print("❌ Error removing family from user: $e");
      rethrow;
    }
  }

  /// Persists user locally using SharedPreferences
  Future<void> storeUserLocally(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userData', jsonEncode(user.toMap()));
      print("✅ User data stored locally.");
    } catch (e) {
      print("❌ Error storing user locally: $e");
    }
  }

  /// Loads cached user data from SharedPreferences
  Future<UserModel?> loadCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');
      if (userDataString == null) return null;

      final map = json.decode(userDataString) as Map<String, dynamic>;
      return UserModel.fromMap(map);
    } catch (e) {
      print("❌ Error loading cached user data: $e");
      return null;
    }
  }

  /// Retrieves cached user email if available
  Future<String?> loadCachedUserEmail() async {
    try {
      final user = await loadCachedUserData();
      return user?.email;
    } catch (e) {
      print("❌ Error loading cached user email: $e");
      return null;
    }
  }

  /// Logs out the user and clears local data
  Future<void> logout() async {
    try {
      await _googleSignIn.disconnect();
      await _googleSignIn.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print("✅ User logged out and local data cleared.");
    } catch (e) {
      print("❌ Error logging out: $e");
    }
  }

  /// Performs logical deletion of user account and related Firestore data
  Future<void> deleteUserAccountWithGoogle() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user currently signed in.',
      );
    }
    final email = currentUser.email!;

    try {
      await _reauthenticateUserForDeletion(currentUser);
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users_collection').doc(email);

      await _removeUserFromAllFamilies(email, batch, currentUser);
      await _deleteFamilyForAdminUser(email, batch);

      batch.update(userRef, {'isDeleted': true});
      await batch.commit();

      print("✅ Logical deletion: Firestore documents updated.");
      await logout();
    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuthException: ${e.code} - ${e.message}");
      throw Exception('Logical deletion failed: ${e.message}');
    } catch (e) {
      print("❌ Unexpected error during logical deletion: $e");
      rethrow;
    }
  }

  Future<void> _removeUserFromAllFamilies(
      String email,
      WriteBatch batch,
      User user,
      ) async {
    final nonAdminSnapshot = await _firestore
        .collection('families_collection')
        .where('members', arrayContains: {'email': email})
        .get();

    for (final doc in nonAdminSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['adminEmail'] != email) {
        batch.update(doc.reference, {
          'members': FieldValue.arrayRemove([
            {'email': email, 'name': user.displayName}
          ])
        });
      }
    }
  }

  Future<void> _deleteFamilyForAdminUser(
      String email,
      WriteBatch batch,
      ) async {
    final adminQuery = await _firestore
        .collection('families_collection')
        .where('adminEmail', isEqualTo: email)
        .where('isDeleted', isEqualTo: false)
        .get();
    if (adminQuery.docs.isNotEmpty) {
      final adminRef = adminQuery.docs.first.reference;
      batch.update(adminRef, {'isDeleted': true});
      await disconnectUserFromFamily(adminRef.id, email);
    }
  }

  Future<void> _reauthenticateUserForDeletion(User user) async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google Sign-In was cancelled.',
      );
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await user.reauthenticateWithCredential(credential);
    print("✅ Google user reauthenticated.");
  }

  Future<void> disconnectUserFromFamily(
      String familyCode,
      String adminEmail,
      ) async {
    final usersSnapshot = await _firestore
        .collection('users_collection')
        .get();
    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      final families = data['families'] as List<dynamic>?;
      if (families != null && families.contains(familyCode)) {
        if (doc.id != adminEmail) {
          await doc.reference.update({
            'families': FieldValue.arrayRemove([familyCode])
          });
          print("✅ Removed $familyCode from ${doc.id}");
        }
      }
    }
  }
}



// import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:eatit/models/userModel.dart';
// import 'package:eatit/services/familyService.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class UserService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final _googleSignIn = GoogleSignIn();
//
//   Future<void> storeUserInFirestore(User user) async {
//     try {
//       DocumentReference userRef =
//           _firestore.collection('users_collection').doc(user.email);
//       UserModel userModel = UserModel(
//         uid: user.uid,
//         displayName: user.displayName,
//         email: user.email,
//         photoURL: user.photoURL,
//         families: null,
//         isDeleted: false,
//       );
//
//       await userRef.set(userModel.toJson(), SetOptions(merge: true));
//
//       print("✅ User data stored successfully.");
//     } catch (e) {
//       print("❌ Error storing user in Firestore: $e");
//     }
//   }
//
//   Future<void> addOrRemoveUserFamilies({
//     required String userEmail,
//     required String familyCode,
//     required bool add,
//   }) async {
//     final DocumentReference userDoc =
//         _firestore.collection('users_collection').doc(userEmail);
//
//     try {
//       if (add) {
//         await userDoc.update({
//           'families': FieldValue.arrayUnion([familyCode]),
//         });
//         print("✅ Family code '$familyCode' added for $userEmail.");
//       } else {
//         await userDoc.update({
//           'families': FieldValue.arrayRemove([familyCode]),
//         });
//         print("✅ Family code '$familyCode' removed for $userEmail.");
//       }
//     } catch (e) {
//       print("❌ Error updating user families: $e");
//       rethrow;
//     }
//   }
//
//   Future<UserModel?> getUserData(String email) async {
//     try {
//       DocumentSnapshot<Map<String, dynamic>> doc =
//           await _firestore.collection('users_collection').doc(email).get();
//       return doc.exists ? UserModel.fromJson(doc.data()!) : null;
//     } catch (e) {
//       print("❌ Error fetching user data: $e");
//       return null;
//     }
//   }
//
//   Future<void> addFamilyToUser(String email, String familyCode) async {
//     try {
//       UserModel? user = await getUserData(email);
//       if (user == null) throw Exception("User not found.");
//
//       UserModel updatedUser = user.addFamily(familyCode);
//       await _firestore
//           .collection('users_collection')
//           .doc(email)
//           .update(updatedUser.toJson());
//       print("✅ Family added successfully.");
//     } catch (e) {
//       print("❌ Error adding family to user: $e");
//       rethrow;
//     }
//   }
//
//   Future<void> removeFamilyFromUser(String email, String familyCode) async {
//     try {
//       UserModel? user = await getUserData(email);
//       if (user == null) throw Exception("User not found.");
//
//       UserModel updatedUser = user.removeFamily(familyCode);
//       await _firestore
//           .collection('users_collection')
//           .doc(email)
//           .update(updatedUser.toJson());
//       print("✅ Family removed successfully.");
//     } catch (e) {
//       print("❌ Error removing family from user: $e");
//       rethrow;
//     }
//   }
//
//   Future<void> storeUserLocally(UserModel user) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.setString('userData', jsonEncode(user.toJson()));
//       print("✅ User data stored locally.");
//     } catch (e) {
//       print("❌ Error storing user locally: $e");
//     }
//   }
//
//   Future<UserModel?> loadCachedUserData() async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? userDataString = prefs.getString('userData');
//
//       return (userDataString != null)
//           ? UserModel.fromJson(json.decode(userDataString))
//           : null;
//     } catch (e) {
//       print("❌ Error loading cached user data: $e");
//       return null;
//     }
//   }
//
//   Future<String?> loadCachedUserEmail() async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? userDataString = prefs.getString('userData');
//
//       if (userDataString != null) {
//         var userData = UserModel.fromJson(json.decode(userDataString));
//         return userData.email!;
//       }
//     } catch (e) {
//       print("❌ Error loading cached user data: $e");
//       return null;
//     }
//     return null;
//   }
//
//   Future<void> logout() async {
//     try {
//       await _googleSignIn.disconnect();
//       await _googleSignIn.signOut();
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.clear();
//       print("✅ User logged out and local data cleared.");
//     } catch (e) {
//       print("❌ Error logging out: $e");
//     }
//   }
//
//   Future<void> deleteUserAccountWithGoogle() async {
//     final User? user = _auth.currentUser;
//     if (user == null) {
//       throw FirebaseAuthException(
//         code: 'no-user',
//         message: 'No user currently signed in.',
//       );
//     }
//     final String email = user.email ?? '';
//
//     try {
//       await reauthenticateUserForDeletion(user);
//       WriteBatch batch = _firestore.batch();
//       DocumentReference userRef = _firestore.collection('users_collection').doc(email);
//
//       //Remove member from all list of families
//       await _removeUserFromAllFamilies(email, batch, user);
//
//       // Deleting the family created by the user
//       await _deleteFamilyForAdminUser(email, batch);
//
//       batch.update(userRef, {'isDeleted': true});
//
//       await batch.commit();
//       print("✅ Logical deletion: Firestore documents updated.");
//
//       await logout();
//     } on FirebaseAuthException catch (e) {
//       print("❌ FirebaseAuthException: ${e.code} - ${e.message}");
//       throw Exception('Logical deletion failed: ${e.message}');
//     } catch (e) {
//       print("❌ Unexpected error during logical deletion: $e");
//       rethrow;
//     }
//   }
//
//   Future<void> _removeUserFromAllFamilies(String email, WriteBatch batch, User user) async {
//     QuerySnapshot nonAdminFamiliesSnapshot = await _firestore
//         .collection('families_collection')
//         .where('members', arrayContains: {'email': email}).get();
//     for (var familyDoc in nonAdminFamiliesSnapshot.docs) {
//       final data = familyDoc.data() as Map<String, dynamic>;
//
//       if ((data['adminEmail'] ?? '') != email) {
//         batch.update(familyDoc.reference, {
//           'members': FieldValue.arrayRemove([
//             {'email': email, 'name': user.displayName}
//           ])
//         });
//       }
//     }
//   }
//
//   Future<void> _deleteFamilyForAdminUser(String email, WriteBatch batch) async {
//     QuerySnapshot adminFamilyQuery = await _firestore
//         .collection('families_collection')
//         .where('adminEmail', isEqualTo: email)
//         .where('isDeleted', isEqualTo: false)
//         .get();
//     if (adminFamilyQuery.docs.isNotEmpty) {
//       DocumentReference adminFamilyRef =
//           adminFamilyQuery.docs.first.reference;
//       batch.update(adminFamilyRef, {'isDeleted': true});
//       await disconnectUserFromFamily(adminFamilyRef.id, email);
//
//     }
//   }
//
//   Future<void> reauthenticateUserForDeletion(User user) async {
//     final GoogleSignIn googleSignIn = GoogleSignIn();
//     final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
//     if (googleUser == null) {
//       throw FirebaseAuthException(
//         code: 'sign-in-cancelled',
//         message: 'Google Sign-In was cancelled.',
//       );
//     }
//     final GoogleSignInAuthentication googleAuth =
//         await googleUser.authentication;
//     final AuthCredential credential = GoogleAuthProvider.credential(
//       accessToken: googleAuth.accessToken,
//       idToken: googleAuth.idToken,
//     );
//     await user.reauthenticateWithCredential(credential);
//     print("✅ Google user reauthenticated.");
//   }
//
//   Future<void> disconnectUserFromFamily(
//       String familyCode, String adminEmail) async {
//     final usersSnapshot = await _firestore.collection('users_collection').get();
//
//     for (var doc in usersSnapshot.docs) {
//       final userData = doc.data();
//       final List<dynamic>? families = userData['families'];
//
//       if (families != null && families.contains(familyCode)) {
//         if (doc.id != adminEmail) {
//           await _firestore.collection('users_collection').doc(doc.id).update({
//             'families': FieldValue.arrayRemove([familyCode])
//           });
//           print("✅ Removed $familyCode from ${doc.id}");
//         }
//       }
//     }
//   }
// }
