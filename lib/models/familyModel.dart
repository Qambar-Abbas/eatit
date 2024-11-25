import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyModel {
  final String familyName;
  final String adminEmail;
  final String familyCode;
  final List members;

  FamilyModel({
    required this.familyName,
    required this.adminEmail,
    required this.familyCode,
    required this.members,
  });

  factory FamilyModel.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FamilyModel(
      familyName: data['familyName'] ?? '',
      adminEmail: data['adminEmail'] ?? '',
      familyCode: doc.id,
      members: List.from(data['members'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyName': familyName,
      'adminEmail': adminEmail,
      'familyCode': familyCode,
      'members': members,
    };
  }
}
