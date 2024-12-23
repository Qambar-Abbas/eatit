import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyModel {
  String familyName;
  String adminEmail;
  String familyCode;
  Map<String, String> members; // Maps userEmail to userName
  String? cook; // Optional field for assigning the current cook

  FamilyModel({
    required this.familyName,
    required this.adminEmail,
    required this.familyCode,
    required this.members,
    this.cook, // Optional field
  });

  /// Factory constructor to create a FamilyModel from Firestore document
  factory FamilyModel.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FamilyModel(
      familyName: data['familyName'] ?? '',
      adminEmail: data['adminEmail'] ?? '',
      familyCode: doc.id, // Firestore doc ID used as familyCode
      members: Map<String, String>.from(data['members'] ?? {}),
      cook: data['cook'], // Fetching optional cook field
    );
  }

  /// Converts FamilyModel to a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'familyName': familyName,
      'adminEmail': adminEmail,
      'familyCode': familyCode,
      'members': members,
      'cook': cook, // Include cook field if it exists
    };
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';

// class FamilyModel {
//   String familyName;
//   String adminEmail;
//   String familyCode;
//   Map<String, String> members; 

//   FamilyModel({
//     required this.familyName,
//     required this.adminEmail,
//     required this.familyCode,
//     required this.members,
//   });

  
//   factory FamilyModel.fromDocument(DocumentSnapshot doc) {
//     Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//     return FamilyModel(
//       familyName: data['familyName'] ?? '',
//       adminEmail: data['adminEmail'] ?? '',
//       familyCode: doc.id,
//       members: Map<String, String>.from(data['members'] ?? {}), 
//     );
//   }

  
//   Map<String, dynamic> toMap() {
//     return {
//       'familyName': familyName,
//       'adminEmail': adminEmail,
//       'familyCode': familyCode,
//       'members': members, 
//     };
//   }
// }
