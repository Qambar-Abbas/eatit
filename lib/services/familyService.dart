import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eatit/models/userModel.dart';
import 'package:eatit/services/userService.dart';
import '../models/familyModel.dart';

class FamilyService {
  final CollectionReference _familiesCollection =
      FirebaseFirestore.instance.collection('families');

  Future<void> createFamily(FamilyModel family, UserModel user) async {
    QuerySnapshot existingFamilies = await _familiesCollection
        .where('adminEmail', isEqualTo: family.adminEmail)
        .limit(1)
        .get();

    if (existingFamilies.docs.isNotEmpty) {
      throw Exception("A family already exists for this admin.");
    }

    try {
      DocumentReference docRef = await _familiesCollection.add(family.toMap());
      String generatedFamilyCode = docRef.id;

      await docRef.update({'familyCode': generatedFamilyCode});

      await UserService().updateUserInFireBase(generatedFamilyCode, user);

      await UserService().updateFamilyList(user.email!, generatedFamilyCode);
    } catch (e) {
      print('Error creating family: $e');
      rethrow;
    }
  }

  Future<FamilyModel?> getFamilyData(String familyEmail) async {
    try {
      QuerySnapshot query = await _familiesCollection
          .where('adminEmail', isEqualTo: familyEmail)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return FamilyModel.fromDocument(query.docs.first);
      }
      return null;
    } catch (e) {
      print('Error fetching family data: $e');
      rethrow;
    }
  }

  Future<void> joinFamily(
      String familyCode, String userEmail, String userName) async {
    try {
      DocumentReference familyRef = _familiesCollection.doc(familyCode);
      DocumentSnapshot familySnapshot = await familyRef.get();

      if (familySnapshot.exists) {
        FamilyModel family = FamilyModel.fromDocument(familySnapshot);

        if (!family.members.containsKey(userEmail)) {
          family.members[userEmail] = userName;

          await familyRef.update({
            'members': family.members,
          });

          await UserService().updateFamilyList(userEmail, familyCode);
        } else {
          print('User is already a member of this family.');
        }
      } else {
        print('Family does not exist.');
        throw Exception('Family with the provided code does not exist.');
      }
    } catch (e) {
      print('Error joining family: $e');
      rethrow;
    }
  }

  Future<List<FamilyModel>> getUserFamilies(List<String> familyCodes) async {
    List<FamilyModel> families = [];
    try {
      for (String code in familyCodes) {
        DocumentSnapshot familySnapshot =
            await _familiesCollection.doc(code).get();
        if (familySnapshot.exists) {
          families.add(FamilyModel.fromDocument(familySnapshot));
        }
      }
    } catch (e) {
      print('Error fetching user families: $e');
      rethrow;
    }
    return families;
  }

  Future<void> assignCook(String familyCode, String cookEmail) async {
    try {
      await _familiesCollection.doc(familyCode).update({'cook': cookEmail});
    } catch (e) {
      throw Exception('Failed to assign cook: $e');
    }
  }

  Future<void> updateFamilyCook(String familyCode, String cookEmail) async {
    await assignCook(familyCode, cookEmail);
  }

  Future<String> getFamilyCode(String familyCode) async {
    try {
      DocumentSnapshot familyDoc =
          await _familiesCollection.doc(familyCode).get();
      if (familyDoc.exists) {
        return familyDoc['familyCode'];
      }
      throw Exception('Family not found');
    } catch (e) {
      throw Exception('Failed to get family code: $e');
    }
  }

  Future<void> removeMember(String familyCode, String userEmail) async {
    try {
      DocumentSnapshot familySnapshot =
          await _familiesCollection.doc(familyCode).get();

      if (familySnapshot.exists) {
        FamilyModel family = FamilyModel.fromDocument(familySnapshot);

        if (family.members.containsKey(userEmail)) {
          family.members.remove(userEmail);

          if (family.members.isEmpty) {
            await _familiesCollection.doc(familyCode).delete();
            print('Family $familyCode deleted as it has no members.');
          } else {
            await _familiesCollection.doc(familyCode).update({
              'members': family.members,
            });
            print('User $userEmail removed from family $familyCode.');
          }
        } else {
          print('User is not a member of this family.');
        }
      } else {
        print('Family does not exist.');
        throw Exception('Family with the provided code does not exist.');
      }
    } catch (e) {
      print('Error removing member: $e');
      rethrow;
    }
  }


// food service

Future<void> createWeeklyMenu(String familyCode) async {
  try {
    // Create an empty weekly menu structure
    Map<String, List<String>> emptyMenu = {
      'Monday': [],
      'Tuesday': [],
      'Wednesday': [],
      'Thursday': [],
      'Friday': [],
      'Saturday': [],
      'Sunday': [],
    };

    // Update the family document in Firebase with the new menu
    await _familiesCollection.doc(familyCode).update({
      'foodMenu': emptyMenu,
    });

    print('Weekly menu created successfully for family $familyCode.');
  } catch (e) {
    print('Error creating weekly menu: $e');
    rethrow;
  }
}
Future<void> updateWeeklyMenu(
  String familyCode,
  String day,
  List<String> lunchItems,
  List<String> dinnerItems,
) async {
  try {
    // Fetch the current family document
    DocumentSnapshot familySnapshot = await _familiesCollection.doc(familyCode).get();

    if (familySnapshot.exists) {
      // Get the current foodMenu from the document
      Map<String, dynamic>? currentMenu = familySnapshot['foodMenu'];

      // If no menu exists, initialize an empty one
      currentMenu ??= {
          'Monday': [],
          'Tuesday': [],
          'Wednesday': [],
          'Thursday': [],
          'Friday': [],
          'Saturday': [],
          'Sunday': [],
        };

      // Update the menu for the specified day
      currentMenu[day] = {
        'lunchItems': lunchItems,
        'dinnerItems': dinnerItems,
      };

      // Update the family document in Firebase
      await _familiesCollection.doc(familyCode).update({
        'foodMenu': currentMenu,
      });

      print('Weekly menu updated successfully for family $familyCode on $day.');
    } else {
      throw Exception('Family with the provided code does not exist.');
    }
  } catch (e) {
    print('Error updating weekly menu: $e');
    rethrow;
  }
}

Future<Map<String, dynamic>?> getWeeklyMenu(String familyCode) async {
  try {
    DocumentSnapshot familySnapshot = await _familiesCollection.doc(familyCode).get();

    if (familySnapshot.exists) {
      // Get the foodMenu from the document
      Map<String, dynamic>? menu = familySnapshot['foodMenu'];
      return menu;
    } else {
      throw Exception('Family with the provided code does not exist.');
    }
  } catch (e) {
    print('Error fetching weekly menu: $e');
    rethrow;
  }
}

}
