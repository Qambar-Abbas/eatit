import 'dart:convert';

class UserModel {
  String? displayName;
  String? email;
  String? profileImageBase64;
  List<String>? familyList; // Added familyList property

  UserModel({
    this.displayName,
    this.email,
    this.profileImageBase64,
    this.familyList, // Include in the constructor
  });

  // Convert the UserModel to a Map for JSON encoding
  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'email': email,
      'profileImageBase64': profileImageBase64,
      'familyList': familyList, // Include familyList in JSON conversion
    };
  }

  // Create a UserModel instance from a JSON Map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      displayName: json['displayName'],
      email: json['email'],
      profileImageBase64: json['profileImageBase64'],
      familyList: json['familyList'] != null
          ? List<String>.from(json['familyList']) // Convert list from JSON
          : [], // Default to an empty list if null
    );
  }

  // Add a method to update the family list
  void addFamily(String familyCode) {
    familyList ??= []; // Initialize if null
    if (!familyList!.contains(familyCode)) {
      familyList!.add(familyCode);
    }
  }

  // Remove a family from the list
  void removeFamily(String familyCode) {
    familyList?.remove(familyCode);
  }
}
