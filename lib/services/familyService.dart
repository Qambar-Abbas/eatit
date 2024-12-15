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

      // Update the user's family list after creating the family
      await UserService().updateFamilyList(user.email!, generatedFamilyCode);
    } catch (e) {
      print('Error creating family: $e');
      throw e;
    }
  }

  Future<FamilyModel?> getFamilyData(String familyEmail) async {
    QuerySnapshot query = await _familiesCollection
        .where('adminEmail', isEqualTo: familyEmail)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return FamilyModel.fromDocument(query.docs.first);
    }
    return null;
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

          // Update the user's family list after joining the family
          await UserService().updateFamilyList(userEmail, familyCode);
        } else {
          print('User is already a member of this family.');
        }
      } else {
        print('Family does not exist.');
      }
    } catch (e) {
      print('Error joining family: $e');
      throw e;
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
    throw e;
  }
  return families;
}

 Future<void> removeMember(String familyCode, String userEmail) async {
  try {
    DocumentSnapshot familySnapshot =
        await _familiesCollection.doc(familyCode).get();
    if (familySnapshot.exists) {
      FamilyModel family = FamilyModel.fromDocument(familySnapshot);

      if (family.members.containsKey(userEmail)) {
        family.members.remove(userEmail);

        // If no members remain, optionally delete the family
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
    }
  } catch (e) {
    print('Error removing member: $e');
    throw e;
  }
}

}
