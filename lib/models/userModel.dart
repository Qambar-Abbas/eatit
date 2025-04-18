import 'dart:core';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  String? uid;
  String? displayName;
  String? email;
  String? photoURL;
  List<String> families;
  bool isDeleted;

  UserModel({
    this.uid,
    this.displayName,
    this.email,
    this.photoURL,
    List<String>? families,
    bool? isDeleted,
  })  : families = families ?? [],
        isDeleted = isDeleted ?? false;

  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoURL: user.photoURL,
      families: [],
      isDeleted: false,
    );
  }

  static UserModel fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String?,
      displayName: map['displayName'] as String?,
      email: map['email'] as String?,
      photoURL: map['photoURL'] as String?,
      families: (map['families'] as List<dynamic>? ?? []).cast<String>(),
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'families': families,
      'isDeleted': isDeleted,
    };
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
      isDeleted: isDeleted ?? this.isDeleted,
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
    return 'UserModel(displayName: $displayName, email: $email, families: $families, isDeleted: $isDeleted)';
  }
}


// import 'dart:core';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class UserModel {
//   String? uid;
//   String? displayName;
//   String? email;
//   String? photoURL;
//   List<String> families;
//   bool isDeleted;
//
//   UserModel({
//     this.uid,
//     this.displayName,
//     this.email,
//     this.photoURL,
//     List<String>? families,
//     bool? isDeleted,
//   })  : families = families ?? [],
//         isDeleted = isDeleted ?? false;
//
//   Map<String, dynamic> toJson() {
//     return {
//       'uid': uid,
//       'displayName': displayName,
//       'email': email,
//       'photoURL': photoURL,
//       'families': families,
//       'isDeleted': isDeleted,
//     };
//   }
//
//   factory UserModel.fromFirebaseUser(User user) {
//     return UserModel(
//       uid: user.uid,
//       displayName: user.displayName,
//       email: user.email,
//       photoURL: user.photoURL,
//       families: [],
//       isDeleted: false,
//     );
//   }
//
//   factory UserModel.fromJson(Map<String, dynamic> json) {
//     return UserModel(
//       uid: json['uid'] as String?,
//       displayName: json['displayName'] as String?,
//       email: json['email'] as String?,
//       photoURL: json['photoURL'] as String?,
//       families: (json['families'] as List<dynamic>? ?? []).cast<String>(),
//       isDeleted: json['isDeleted'] as bool? ?? false,
//     );
//   }
//
//   UserModel copyWith({
//     String? uid,
//     String? displayName,
//     String? email,
//     String? photoURL,
//     List<String>? families,
//     bool? isDeleted,
//   }) {
//     return UserModel(
//       uid: uid ?? this.uid,
//       displayName: displayName ?? this.displayName,
//       email: email ?? this.email,
//       photoURL: photoURL ?? this.photoURL,
//       families: families ?? this.families,
//       isDeleted: isDeleted ?? this.isDeleted,
//     );
//   }
//
//   UserModel addFamily(String familyCode) {
//     if (!families.contains(familyCode)) {
//       return copyWith(families: [...families, familyCode]);
//     }
//     return this;
//   }
//
//   UserModel removeFamily(String familyCode) {
//     return copyWith(families: families.where((f) => f != familyCode).toList());
//   }
//
//   @override
//   String toString() {
//     return 'UserModel(displayName: $displayName, email: $email, families: $families, isDeleted: $isDeleted)';
//   }
// }
