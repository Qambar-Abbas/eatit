import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eatit/models/familyModel.dart';
import 'package:eatit/services/userService.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FamilyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _familiesCollection =
      FirebaseFirestore.instance.collection('families_collection');

  /// Converts a [FamilyModel] into a Map for Firestore storage.
  Map<String, dynamic> _familyToMap(FamilyModel family) {
    return {
      'familyName': family.familyName,
      'adminEmail': family.adminEmail,
      'familyCode': family.familyCode,
      'members': family.members,
      'cook': family.cook,
      'foodMenu': family.foodMenu,
      'isDeleted': family.isDeleted,
    };
  }

  /// Creates a [FamilyModel] from Firestore snapshot data.
  FamilyModel _mapToFamilyModel(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;

    return FamilyModel(
      familyName: data['familyName'] as String? ?? '',
      adminEmail: data['adminEmail'] as String? ?? '',
      familyCode: snap.id,
      members: List<String>.from(data['members'] as List? ?? const []),
      cook: data['cook'] as String?,
      foodMenu: Map<String, dynamic>.from(data['foodMenu']),
      isDeleted: data['isDeleted'] as bool? ?? false,
    );
  }

  Future<void> createAndStoreFamilyInFirebase(FamilyModel family) async {
    try {
      final existing = await _familiesCollection
          .where('adminEmail', isEqualTo: family.adminEmail)
          .get();

      final hasActiveFamily = existing.docs.any((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isDeleted'] != true;
      });

      if (hasActiveFamily) {
        throw Exception('You have already created a family.');
      }

      final docRef = _familiesCollection.doc();
      final updated = family.copyWith(familyCode: docRef.id);

      await docRef.set(_familyToMap(updated));

      await UserService().addOrRemoveUserFamilies(
        userEmail: updated.adminEmail,
        familyCode: docRef.id,
        add: true,
      );

      print("✅ Family created with code: ${docRef.id}");
    } catch (e) {
      print("❌ Error creating family: $e");
      rethrow;
    }
  }

  Future<void> updateFamilyFoodMenu({
    required String familyCode,
    required String day,
    required String mealType, // 'lunch' or 'dinner'
    required List<String> values,
  }) async {
    try {
      final docRef = _familiesCollection.doc(familyCode);

      // Directly update only the specific meal for the day
      await docRef.update({
        'foodMenu.$day.$mealType': values,
      });

      print('✅ Efficiently updated $mealType for $day to $values');
    } catch (e) {
      print('❌ Error updating food menu efficiently: $e');
      rethrow;
    }
  }

  Future<FamilyModel?> fetchFamilyDataFromFirebase() async {
    try {
      final userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) throw Exception("User not authenticated.");

      final userSnap =
          await _firestore.collection('users').doc(userEmail).get();
      if (!userSnap.exists) throw Exception("User document not found.");

      final families = List<String>.from(userSnap.get('families') ?? []);
      if (families.isEmpty)
        throw Exception("User does not belong to any family.");

      return await getFamilyByCodeFromFirebase(families.first);
    } catch (e) {
      print("❌ Error fetching family data: $e");
      return null;
    }
  }

  Future<FamilyModel?> getFamilyByCodeFromFirebase(String familyCode) async {
    try {
      final snap = await _familiesCollection.doc(familyCode).get();
      if (!snap.exists) throw Exception('Family not found.');

      return _mapToFamilyModel(snap);
    } catch (e) {
      print("❌ Error fetching family by ID: $e");
      return null;
    }
  }

  Future<FamilyModel?> getAdminFamily(String adminEmail) async {
    try {
      final query = await _familiesCollection
          .where('adminEmail', isEqualTo: adminEmail)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return _mapToFamilyModel(query.docs.first);
    } catch (e) {
      print("❌ Error fetching admin family: $e");
      return null;
    }
  }

  /// Toggles the cook for a family: assigns if different, clears if the same
  Future<void> toggleFamilyCook({
    required String familyCode,
    required String memberEmail,
  }) async {
    final docRef = _familiesCollection.doc(familyCode);
    final snap = await docRef.get();
    if (!snap.exists) throw Exception('Family not found.');

    final currentCook = snap.get('cook') as String?;
    final newCook = (currentCook == memberEmail) ? null : memberEmail;

    await docRef.update({'cook': newCook});

    print("✅ Cook updated for $familyCode: $newCook");
  }

  Future<void> addOrRemoveFamilyMembers({
    required String familyCode,
    required String memberEmail,
    required bool add,
  }) async {
    final familyDoc = _familiesCollection.doc(familyCode);
    final snap = await familyDoc.get();
    final isDeleted = snap.get('isDeleted') as bool? ?? false;
    if (isDeleted) {
      throw Exception("🚫 This family has been deleted.");
    }

    try {
      if (add) {
        await familyDoc.update({
          'members': FieldValue.arrayUnion([memberEmail]),
        });
        print("✅ Member added: $memberEmail");
      } else {
        await familyDoc.update({
          'members': FieldValue.arrayRemove([memberEmail]),
        });
        print("✅ Member removed: $memberEmail");

        // Also remove from the user’s family list
        await UserService().addOrRemoveUserFamilies(
          userEmail: memberEmail,
          familyCode: familyCode,
          add: false,
        );
      }
    } catch (e) {
      print("❌ Error updating family members: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getWeeklyMenu(String familyCode) async {
    try {
      final snap = await _familiesCollection.doc(familyCode).get();
      if (!snap.exists) throw Exception("Family does not exist.");

      final menuData = snap.get('foodMenu');
      if (menuData is Map<String, dynamic>) {
        return menuData;
      } else if (menuData is List) {
        return {for (var item in menuData) item['day']: item};
      } else {
        throw Exception("Invalid data format for foodMenu.");
      }
    } catch (e) {
      print("❌ Error fetching weekly menu: $e");
      return null;
    }
  }

  Future<FamilyModel?> getAdminFamilyData(String adminEmail) async {
    try {
      final query = await _familiesCollection
          .where('adminEmail', isEqualTo: adminEmail)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return _mapToFamilyModel(query.docs.first);
    } catch (e) {
      print('Error fetching admin family data: $e');
      return null;
    }
  }

  Future<void> deleteAdminFamily(String adminEmail) async {
    try {
      final existing = await _familiesCollection
          .where('adminEmail', isEqualTo: adminEmail)
          .where('isDeleted', isEqualTo: false)
          .get();
      if (existing.docs.isEmpty) {
        throw Exception('No family found for this admin.');
      }

      final familyDoc = existing.docs.first;
      final familyCode = familyDoc.id;

      await _familiesCollection.doc(familyCode).update({'isDeleted': true});
      await UserService().addOrRemoveUserFamilies(
        userEmail: adminEmail,
        familyCode: familyCode,
        add: false,
      );

      print("✅ Family marked as deleted and removed from all members.");
    } catch (e) {
      print("❌ Error deleting family as admin: $e");
      rethrow;
    }
  }

  Future<void> updateDailyMenu({
    required String familyCode,
    required String day,
    required List<String> lunchItems,
    required List<String> dinnerItems,
  }) async {
    try {
      final docRef = _familiesCollection.doc(familyCode);

      final updateData = {
        'foodMenu.$day.lunch': lunchItems,
        'foodMenu.$day.dinner': dinnerItems,
      };

      await docRef.update(updateData);

      print('✅ Successfully updated lunch and dinner for $day');
    } catch (e) {
      print('❌ Error updating daily menu for $day: $e');
      rethrow;
    }
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:eatit/models/familyModel.dart';
// import 'package:eatit/services/userService.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class FamilyService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final CollectionReference _familiesCollection =
//       FirebaseFirestore.instance.collection('families_collection');
//
//   Future<void> createAndStoreFamilyInFirebase(FamilyModel family) async {
//     try {
//       final existing = await _firestore
//           .collection('families_collection')
//           .where('adminEmail', isEqualTo: family.adminEmail)
//           .get();
//
//       final hasActiveFamily = existing.docs.any((doc) {
//         final data = doc.data();
//         return data['isDeleted'] != true;
//       });
//
//       if (hasActiveFamily) {
//         throw Exception('You have already created a family.');
//       }
//
//       DocumentReference docRef =
//           _firestore.collection('families_collection').doc();
//       final updatedFamily = family.copyWith(familyCode: docRef.id);
//
//       await docRef.set(updatedFamily.toJson());
//
//       await UserService().addOrRemoveUserFamilies(
//         userEmail: family.adminEmail,
//         familyCode: docRef.id,
//         add: true,
//       );
//
//       print("✅ Family created with code: ${docRef.id}");
//     } catch (e) {
//       print("❌ Error creating family: $e");
//       rethrow;
//     }
//   }
//
//   Future<FamilyModel?> fetchFamilyDataFromFirebase() async {
//     try {
//       String? userEmail = FirebaseAuth.instance.currentUser?.email;
//       if (userEmail == null) throw Exception("User not authenticated.");
//
//       DocumentSnapshot userSnapshot =
//           await _firestore.collection('users').doc(userEmail).get();
//       if (!userSnapshot.exists) throw Exception("User document not found.");
//
//       List<String> families =
//           List<String>.from(userSnapshot.get('families') ?? []);
//       if (families.isEmpty)
//         throw Exception("User does not belong to any family.");
//
//       return await getFamilyByCodeFromFirebase(families.first);
//     } catch (e) {
//       print("❌ Error fetching family data: $e");
//       return null;
//     }
//   }
//
//   Future<FamilyModel?> getFamilyByCodeFromFirebase(String familyCode) async {
//     try {
//       DocumentSnapshot familySnapshot =
//           await _familiesCollection.doc(familyCode).get();
//       if (!familySnapshot.exists) throw Exception("Family not found.");
//
//       return FamilyModel.fromJson(
//           familySnapshot.data() as Map<String, dynamic>);
//     } catch (e) {
//       print("❌ Error fetching family by ID: $e");
//       return null;
//     }
//   }
//
//   Future<FamilyModel?> getAdminFamily(String adminEmail) async {
//     try {
//       QuerySnapshot query = await _familiesCollection
//           .where('adminEmail', isEqualTo: adminEmail)
//           .limit(1)
//           .get();
//       return query.docs.isNotEmpty
//           ? FamilyModel.fromJson(
//               query.docs.first.data() as Map<String, dynamic>)
//           : null;
//     } catch (e) {
//       print("❌ Error fetching admin family: $e");
//       return null;
//     }
//   }
//
//   /// Toggles the cook for a family: assigns if different, clears if the same
//   Future<void> toggleFamilyCook({
//     required String familyCode,
//     required String memberEmail,
//   }) async {
//     final docRef = _familiesCollection.doc(familyCode);
//     final snap = await docRef.get();
//     if (!snap.exists) throw Exception('Family not found.');
//
//     final currentCook = snap.get('cook') as String?;
//     final newCook = (currentCook == memberEmail) ? null : memberEmail;
//
//     await docRef.update({
//       'cook': newCook,
//     });
//
//     print("✅ Cook updated for $familyCode: $newCook");
//   }
//
//   Future<void> addOrRemoveFamilyMembers({
//     required String familyCode,
//     required Map<String, String> member,
//     required bool add,
//   }) async {
//     final DocumentReference familyDoc =
//         _firestore.collection('families_collection').doc(familyCode);
//     final snapshot = await familyDoc.get();
//     final isDeleted = snapshot.get('isDeleted') as bool;
//     if (!isDeleted) {
//       try {
//         if (add) {
//           await familyDoc.update({
//             'members': FieldValue.arrayUnion([member]),
//           });
//           print("✅ Member added: $member");
//         } else {
//           await familyDoc.update({
//             'members': FieldValue.arrayRemove([member]),
//           });
//           print("✅ Member removed: $member");
//         }
//         // Also update user->families mapping when removing
//         if (!add) {
//           await UserService().addOrRemoveUserFamilies(
//             userEmail: member['email']!,
//             familyCode: familyCode,
//             add: false,
//           );
//         }
//       } catch (e) {
//         print("❌ Error updating family members: $e");
//         rethrow;
//       }
//     } else {
//       throw Exception("🚫 This family has been deleted.");
//     }
//   }
//
//   Future<void> updateFamilyCook(String familyCode, String cookEmail) async {
//     try {
//       await _familiesCollection.doc(familyCode).update({'cook': cookEmail});
//       print("✅ Assigned cook $cookEmail to family $familyCode.");
//     } catch (e) {
//       print("❌ Error assigning cook: $e");
//     }
//   }
//
//   Future<Map<String, dynamic>?> getWeeklyMenu(String familyCode) async {
//     try {
//       DocumentSnapshot familySnapshot =
//           await _familiesCollection.doc(familyCode).get();
//       if (!familySnapshot.exists) throw Exception("Family does not exist.");
//
//       var menuData = familySnapshot.get('foodMenu');
//
//       if (menuData is Map<String, dynamic>) {
//         return menuData;
//       } else if (menuData is List) {
//         return {for (var item in menuData) item['day']: item};
//       } else {
//         throw Exception("Invalid data format for foodMenu.");
//       }
//     } catch (e) {
//       print("❌ Error fetching weekly menu: $e");
//       return null;
//     }
//   }
//
//   Future<void> createWeeklyMenu(String familyCode) async {
//     try {
//       Map<String, List<String>> emptyMenu = {
//         'monday': [],
//         'tuesday': [],
//         'wednesday': [],
//         'thursday': [],
//         'friday': [],
//         'saturday': [],
//         'sunday': [],
//       };
//
//       await _familiesCollection.doc(familyCode).update({'foodMenu': emptyMenu});
//       print("✅ Weekly menu created for family $familyCode.");
//     } catch (e) {
//       print("❌ Error creating weekly menu: $e");
//     }
//   }
//
//   Future<void> updateWeeklyMenu(
//     String familyCode,
//     String day,
//     List<String> lunchItems,
//     List<String> dinnerItems,
//   ) async {
//     try {
//       DocumentSnapshot familySnapshot =
//           await _familiesCollection.doc(familyCode).get();
//       if (!familySnapshot.exists) throw Exception("Family does not exist.");
//
//       Map<String, dynamic> currentMenu =
//           Map<String, dynamic>.from(familySnapshot.get('foodMenu') ?? {});
//
//       currentMenu[day] = {
//         'lunchItems': lunchItems,
//         'dinnerItems': dinnerItems,
//       };
//
//       await _familiesCollection
//           .doc(familyCode)
//           .update({'foodMenu': currentMenu});
//       print("✅ Menu updated for $day in family $familyCode.");
//     } catch (e) {
//       print("❌ Error updating weekly menu: $e");
//     }
//   }
//
//   Future<FamilyModel?> getAdminFamilyData(String adminEmail) async {
//     try {
//       QuerySnapshot query = await _familiesCollection
//           .where('adminEmail', isEqualTo: adminEmail)
//           .limit(1)
//           .get();
//
//       if (query.docs.isNotEmpty) {
//         return FamilyModel.fromJson(
//             query.docs.first.data() as Map<String, dynamic>);
//       }
//       return null;
//     } catch (e) {
//       print('Error fetching admin family data: $e');
//       return null;
//     }
//   }
//
//   Future<void> deleteAdminFamily(String adminEmail) async {
//     try {
//       final existing = await _firestore
//           .collection('families_collection')
//           .where('adminEmail', isEqualTo: adminEmail)
//           .where('isDeleted', isEqualTo: false)
//           .get();
//
//       if (existing.docs.isEmpty) {
//         throw Exception('No family found for this admin.');
//       }
//
//       final familyDoc = existing.docs.first;
//       final familyCode = familyDoc.id;
//       final familyData = familyDoc.data();
//
//       final List<dynamic> members = familyData['members'] ?? [];
//
//       await _firestore
//           .collection('families_collection')
//           .doc(familyCode)
//           .update({
//         'isDeleted': true,
//       });
//
//       await UserService().addOrRemoveUserFamilies(
//         userEmail: adminEmail,
//         familyCode: familyCode,
//         add: false,
//       );
//
//       // for (var member in members) {
//       //   final email = member['email'];
//       //   if (email != adminEmail) {
//       //     await UserService().addOrRemoveUserFamilies(
//       //       userEmail: email,
//       //       familyCode: familyCode,
//       //       add: false,
//       //     );
//       //   }
//       // }
//
//       print("✅ Family marked as deleted and removed from all members.");
//     } catch (e) {
//       print("❌ Error deleting family as admin: $e");
//       rethrow;
//     }
//   }
// }
