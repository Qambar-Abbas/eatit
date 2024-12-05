import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyModel {
  String familyName;
  String adminEmail;
  String familyCode;
  Map<String, String> members; // Updated to use a Map for email-name pairs

  FamilyModel({
    required this.familyName,
    required this.adminEmail,
    required this.familyCode,
    required this.members,
  });

  // Factory constructor to create FamilyModel from Firestore document
  factory FamilyModel.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FamilyModel(
      familyName: data['familyName'] ?? '',
      adminEmail: data['adminEmail'] ?? '',
      familyCode: doc.id,
      members: Map<String, String>.from(data['members'] ?? {}), // Parse Map from Firestore data
    );
  }

  // Convert FamilyModel to Map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'familyName': familyName,
      'adminEmail': adminEmail,
      'familyCode': familyCode,
      'members': members, // Save as Map<String, String>
    };
  }
}
