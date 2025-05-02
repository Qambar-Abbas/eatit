import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;
  final List<String> families;
  final bool isDeleted;

  UserModel({
    required this.uid,
    this.displayName,
    this.email,
    this.photoURL,
    List<String>? families,
    this.isDeleted = false,
  }) : families = families ?? const [];

  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoURL: user.photoURL,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      displayName: map['displayName'] as String?,
      email: map['email'] as String?,
      photoURL: map['photoURL'] as String?,
      families: List<String>.from(map['families'] as List? ?? const []),
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'photoURL': photoURL,
        'families': families,
        'isDeleted': isDeleted,
      };

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

  UserModel addFamily(String code) {
    if (!families.contains(code)) {
      return copyWith(families: [...families, code]);
    }
    return this;
  }

  UserModel removeFamily(String code) {
    return copyWith(families: families.where((f) => f != code).toList());
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, displayName: $displayName, email: $email, families: $families, isDeleted: $isDeleted)';
  }
}
