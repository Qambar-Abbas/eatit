import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyModel {
  String familyName;
  String adminEmail;
  String familyCode;
  Map<String, String> members;
  String? cook;
  Map<String, List<String>> foodMenu;

  FamilyModel({
    required this.familyName,
    required this.adminEmail,
    required this.familyCode,
    required this.members,
    this.cook,
    required this.foodMenu,
  });

factory FamilyModel.fromDocument(DocumentSnapshot doc) {
  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

  return FamilyModel(
    familyName: data['familyName'] ?? '',
    adminEmail: data['adminEmail'] ?? '',
    familyCode: doc.id,
    members: Map<String, String>.from(data['members'] ?? {}),
    cook: data['cook'],
    foodMenu: (data['foodMenu'] ?? {}).map<String, List<String>>(
      (key, value) => MapEntry(
        key as String,
        List<String>.from(value is List<dynamic> ? value : []),
      ),
    ),
  );
}


  Map<String, dynamic> toMap() {
    return {
      'familyName': familyName,
      'adminEmail': adminEmail,
      'familyCode': familyCode,
      'members': members,
      'cook': cook,
      'foodMenu': foodMenu.map((key, value) => MapEntry(key, value)),
    };
  }
}
