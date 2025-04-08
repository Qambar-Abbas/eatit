import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eatit/models/familyModel.dart';
import 'package:eatit/services/userService.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FamilyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _familiesCollection =
      FirebaseFirestore.instance.collection('families');

  Future<void> createFamily(FamilyModel family) async {
    try {
      final existing = await _firestore
          .collection('families')
          .where('adminEmail', isEqualTo: family.adminEmail)
          .get();

      final hasActiveFamily = existing.docs.any((doc) {
        final data = doc.data();
        return data['isDeleted'] != true;
      });

      if (hasActiveFamily) {
        throw Exception('You have already created a family.');
      }

      DocumentReference docRef = _firestore.collection('families').doc();
      final updatedFamily = family.copyWith(familyCode: docRef.id);

      await docRef.set(updatedFamily.toJson());

      await UserService().updateUserFamilies(
        userEmail: family.adminEmail,
        familyCode: docRef.id,
        add: true,
      );

      print("✅ Family created with code: ${docRef.id}");
    } catch (e) {
      print("❌ Error creating family: $e");
      rethrow;
    }
  }

  Future<void> updateFamilyMembers({
    required String familyDocId,
    required Map<String, String> member,
    required bool add,
  }) async {
    final DocumentReference familyDoc =
        _firestore.collection('families').doc(familyDocId);
    final snapshot = await familyDoc.get();
    final isDeleted = snapshot.get('isDeleted') as bool;
    if (!isDeleted) {
      try {
        if (add) {
          await familyDoc.update({
            'members': FieldValue.arrayUnion([member]),
          });
          print("✅ Member added: $member");
        } else {
          await familyDoc.update({
            'members': FieldValue.arrayRemove([member]),
          });
          print("✅ Member removed: $member");
        }
      } catch (e) {
        print("❌ Error updating family members: $e");
        rethrow;
      }
    } else {
      throw Exception("🚫 This family has been deleted.");
    }
  }

  Future<FamilyModel?> fetchFamilyData() async {
    try {
      String? userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) throw Exception("User not authenticated.");

      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(userEmail).get();
      if (!userSnapshot.exists) throw Exception("User document not found.");

      List<String> families =
          List<String>.from(userSnapshot.get('families') ?? []);
      if (families.isEmpty)
        throw Exception("User does not belong to any family.");

      return await getFamilyById(families.first);
    } catch (e) {
      print("❌ Error fetching family data: $e");
      return null;
    }
  }

  Future<FamilyModel?> getFamilyById(String familyCode) async {
    try {
      DocumentSnapshot familySnapshot =
          await _familiesCollection.doc(familyCode).get();
      if (!familySnapshot.exists) throw Exception("Family not found.");

      return FamilyModel.fromJson(
          familySnapshot.data() as Map<String, dynamic>);
    } catch (e) {
      print("❌ Error fetching family by ID: $e");
      return null;
    }
  }

  Future<FamilyModel?> getAdminFamily(String adminEmail) async {
    try {
      QuerySnapshot query = await _familiesCollection
          .where('adminEmail', isEqualTo: adminEmail)
          .limit(1)
          .get();
      return query.docs.isNotEmpty
          ? FamilyModel.fromJson(
              query.docs.first.data() as Map<String, dynamic>)
          : null;
    } catch (e) {
      print("❌ Error fetching admin family: $e");
      return null;
    }
  }

  Future<void> removeMember(String familyCode, String userEmail) async {
    try {
      FamilyModel? family = await getFamilyById(familyCode);
      if (family == null) throw Exception("Family does not exist.");

      FamilyModel updatedFamily = family.copyWith(
        members: family.members.where((m) => m['email'] != userEmail).toList(),
      );

      if (updatedFamily.members.isEmpty) {
        await _familiesCollection.doc(familyCode).delete();
        print("✅ Family $familyCode deleted (no members left).");
      } else {
        await _familiesCollection
            .doc(familyCode)
            .update(updatedFamily.toJson());
        print("✅ Removed user $userEmail from family $familyCode.");
      }
    } catch (e) {
      print("❌ Error removing member: $e");
    }
  }

  Future<void> updateFamilyCook(String familyCode, String cookEmail) async {
    try {
      await _familiesCollection.doc(familyCode).update({'cook': cookEmail});
      print("✅ Assigned cook $cookEmail to family $familyCode.");
    } catch (e) {
      print("❌ Error assigning cook: $e");
    }
  }

  Future<Map<String, dynamic>?> getWeeklyMenu(String familyCode) async {
    try {
      DocumentSnapshot familySnapshot =
          await _familiesCollection.doc(familyCode).get();
      if (!familySnapshot.exists) throw Exception("Family does not exist.");

      var menuData = familySnapshot.get('foodMenu');

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

  Future<void> createWeeklyMenu(String familyCode) async {
    try {
      Map<String, List<String>> emptyMenu = {
        'monday': [],
        'tuesday': [],
        'wednesday': [],
        'thursday': [],
        'friday': [],
        'saturday': [],
        'sunday': [],
      };

      await _familiesCollection.doc(familyCode).update({'foodMenu': emptyMenu});
      print("✅ Weekly menu created for family $familyCode.");
    } catch (e) {
      print("❌ Error creating weekly menu: $e");
    }
  }

  Future<void> updateWeeklyMenu(
    String familyCode,
    String day,
    List<String> lunchItems,
    List<String> dinnerItems,
  ) async {
    try {
      DocumentSnapshot familySnapshot =
          await _familiesCollection.doc(familyCode).get();
      if (!familySnapshot.exists) throw Exception("Family does not exist.");

      Map<String, dynamic> currentMenu =
          Map<String, dynamic>.from(familySnapshot.get('foodMenu') ?? {});

      currentMenu[day] = {
        'lunchItems': lunchItems,
        'dinnerItems': dinnerItems,
      };

      await _familiesCollection
          .doc(familyCode)
          .update({'foodMenu': currentMenu});
      print("✅ Menu updated for $day in family $familyCode.");
    } catch (e) {
      print("❌ Error updating weekly menu: $e");
    }
  }

  Future<FamilyModel?> getAdminFamilyData(String adminEmail) async {
    try {
      QuerySnapshot query = await _familiesCollection
          .where('adminEmail', isEqualTo: adminEmail)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return FamilyModel.fromJson(
            query.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching admin family data: $e');
      return null;
    }
  }

  Future<void> deleteFamilyAsAdmin(String adminEmail) async {
    try {
      final existing = await _firestore
          .collection('families')
          .where('adminEmail', isEqualTo: adminEmail)
          .get();

      if (existing.docs.isEmpty) {
        throw Exception('No family found for this admin.');
      }

      final familyDoc = existing.docs.first;
      final familyCode = familyDoc.id;
      final familyData = familyDoc.data();

      final List<dynamic> members = familyData['members'] ?? [];

      await _firestore.collection('families').doc(familyCode).update({
        'isDeleted': true,
      });

      await UserService().updateUserFamilies(
        userEmail: adminEmail,
        familyCode: familyCode,
        add: false,
      );

      for (var member in members) {
        final email = member['email'];
        if (email != adminEmail) {
          await UserService().updateUserFamilies(
            userEmail: email,
            familyCode: familyCode,
            add: false,
          );

          await removeMember(familyCode, email);
        }
      }

      print("✅ Family marked as deleted and removed from all members.");
    } catch (e) {
      print("❌ Error deleting family as admin: $e");
      rethrow;
    }
  }
}
