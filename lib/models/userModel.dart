import 'dart:core';

import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  String? uid;
  String? displayName;
  String? email;
  String? photoURL;
  List<String> families;
  bool? isDeleted;

  UserModel({
    this.uid,
    this.displayName,
    this.email,
    this.photoURL,
    List<String>? families,
    this.isDeleted,
  }) : families = families ?? [];

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'families': families,
      'isDeleted': isDeleted,
    };
  }

  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoURL: user.photoURL,
      families: [],
      isDeleted: null,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String?,
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      photoURL: json['photoURL'] as String?,
      families: (json['families'] as List<dynamic>? ?? []).cast<String>(),
      isDeleted: null,
    );
  }

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoURL,
    List<String>? families,
    bool? isDeleted,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      families: families ?? this.families,
      isDeleted: isDeleted,
    );
  }

  UserModel addFamily(String familyCode) {
    if (!families.contains(familyCode)) {
      return copyWith(families: [...families, familyCode]);
    }
    return this;
  }

  UserModel removeFamily(String familyCode) {
    return copyWith(families: families.where((f) => f != familyCode).toList());
  }

  @override
  String toString() {
    return 'UserModel(displayName: $displayName, email: $email, families: $families)';
  }
}
