import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eatit/models/familyModel.dart';
import 'package:eatit/services/userService.dart';
import 'package:eatit/util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class FamilyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _familiesCollection =
      FirebaseFirestore.instance.collection('families_collection');

  FamilyModel _mapToFamilyModel(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return FamilyModel.fromMap(data, snap.id);
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

      await docRef.set(updated.toMap());

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
    required String mealType,
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

  Future<List<String>> getFoodMenuByTime(String familyCode) async {
    try {
      final family = await getFamilyByCodeFromFirebase(familyCode);
      if (family?.foodMenu == null) {
        return [];
      }

      final now = DateTime.now();
      final dayOfWeek = DateFormat('EEEE').format(now);
      final hour = now.hour;

      final dailyMenu = family!.foodMenu[dayOfWeek];

      if (dailyMenu != null && dailyMenu is Map<String, dynamic>) {
        if (hour < 17 && dailyMenu.containsKey('lunch')) {
          return List<String>.from(dailyMenu['lunch'] ?? []);
        } else if (hour >= 17 && dailyMenu.containsKey('dinner')) {
          return List<String>.from(dailyMenu['dinner'] ?? []);
        }
      }

      return []; // Return empty list if no menu for the current time
    } catch (e) {
      print("❌ Error getting food menu by time: $e");
      return [];
    }
  }

  Future<String> updateSelectedMeal({
    required String familyCode,
    required String selectedMeal,
  }) async {
    final docRef = _familiesCollection.doc(familyCode);

    try {
      await docRef.update({'selectedMeal': selectedMeal});
      return selectedMeal.isEmpty
          ? "Meal selection reset."
          : "✅ Meal updated to: $selectedMeal";
    } catch (e) {
      print("❌ Error updating selectedMeal: $e");
      rethrow;
    }
  }

  Future<void> setVotingStatus({
    required String familyCode,
    required bool isOpen,
  }) async {
    try {
      await _familiesCollection.doc(familyCode).update({
        'isVotingOpen': isOpen,
      });
      if (kDebugMode) {
        print("✅ Voting status set to $isOpen");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error updating voting status: $e");
      }
      rethrow;
    }
  }

  Future<bool> getVotingStatus(String familyCode) async {
    try {
      final snap = await _familiesCollection.doc(familyCode).get();
      if (!snap.exists) return false;

      final data = snap.data() as Map<String, dynamic>;
      return data['isVotingOpen'] as bool? ?? false;
    } catch (e) {
      print("❌ Error fetching voting status: $e");
      return false;
    }
  }

  Future<void> submitVote({
    required String familyCode,
    required String selectedItem,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No authenticated user with an email found.');
    }
    final userEmail = user.email!;
    final path = FieldPath(['votes', userEmail]);
    // Update the single map entry without overwriting the rest:
    await _familiesCollection.doc(familyCode).update({
      path: selectedItem,
    });
  }

  Future<void> syncVotingStatusWithGlobal(String familyCode) async {
    try {
      final isOpen = await getVotingStatus(familyCode);
      votingStatus.setVotingOpen(isOpen); // ✅ update global
      if (kDebugMode) {
        print("🔄 Synced global voting status to: $isOpen");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error syncing voting status: $e");
      }
    }
  }
}
