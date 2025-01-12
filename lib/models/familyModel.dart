import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyModel {
  String familyName;
  String adminEmail;
  String familyCode;
  Map<String, String> members; 
  String? cook; 

  FamilyModel({
    required this.familyName,
    required this.adminEmail,
    required this.familyCode,
    required this.members,
    this.cook, 
  });

  
  factory FamilyModel.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FamilyModel(
      familyName: data['familyName'] ?? '',
      adminEmail: data['adminEmail'] ?? '',
      familyCode: doc.id, 
      members: Map<String, String>.from(data['members'] ?? {}),
      cook: data['cook'], 
    );
  }

  
  Map<String, dynamic> toMap() {
    return {
      'familyName': familyName,
      'adminEmail': adminEmail,
      'familyCode': familyCode,
      'members': members,
      'cook': cook, 
    };
  }
}