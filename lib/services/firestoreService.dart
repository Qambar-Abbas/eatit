import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Public getters for _auth and _firestore
  FirebaseFirestore get firestore => _firestore;
  FirebaseAuth get auth => _auth;

  Future<Map<String, dynamic>?> getUserDataFromFirestore(String email) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _firestore.collection('users').doc(email).get();
      if (doc.exists) {
        return doc.data();
      } else {
        print('No user found with email: $email');
        return null;
      }
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserData(String email) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection('users').doc(email).get();

      if (doc.exists) {
        return doc.data();
      } else {
        print('No user found with email: $email');
        return null;
      }
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Logout method
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  /// Delete account method
  Future<void> deleteAccount() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        String uid = currentUser.uid;

        // Fetch the user's families
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          List<String> familyIds = List<String>.from(userDoc['families'] ?? []);

          // Remove user from all families they belong to
          for (String familyId in familyIds) {
            await _firestore.collection('families').doc(familyId).update({
              'members': FieldValue.arrayRemove([uid]),
            });
          }

          // Delete the user's document from Firestore
          await _firestore.collection('users').doc(uid).delete();

          // Delete the user's authentication account
          await currentUser.delete();

          print("User account deleted successfully.");
        } else {
          print("User document not found.");
        }
      }
    } catch (e) {
      print("Error deleting account: $e");
    }
  }

  Future<bool> checkUserExists(User user) async {
  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.email) // Assuming user is identified by their email
        .get();

    return userDoc.exists; // Check if the document exists
  } catch (e) {
    print('Error checking user existence: $e');
    return false; // Return false if an error occurs
  }
}

}
