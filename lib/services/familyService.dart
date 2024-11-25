import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/familyModel.dart';

class FamilyService {
  final CollectionReference _familiesCollection =
      FirebaseFirestore.instance.collection('families');
  Future<void> createFamily(FamilyModel family) async {
    DocumentReference docRef =
        await _familiesCollection.add(family.toMap()); // Create document
    String generatedFamilyCode = docRef.id;
    await docRef.update({'familyCode': generatedFamilyCode});
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

  Future<void> joinFamily(String familyCode, String userEmail) async {
    try {
      DocumentReference familyRef = _familiesCollection.doc(familyCode);
      DocumentSnapshot familySnapshot = await familyRef.get();
      if (familySnapshot.exists) {
        List currentMembers = List.from(familySnapshot['members'] ?? []);
        if (!currentMembers.contains(userEmail)) {
          currentMembers.add(userEmail);
          await familyRef.update({
            'members': currentMembers,
          });
        } else {
          print('User is already a member of this family.');
        }
      } else {
        print('Family does not exist.');
      }
    } catch (e) {
      print('Error joining family: $e');
    }
  }
}
