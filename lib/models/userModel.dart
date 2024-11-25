class UserModel {
  String? displayName;
  String? email;
  String? profilePhoto;

  UserModel({
    this.displayName,
    this.email,
    this.profilePhoto,
  });

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'profilePhoto': profilePhoto,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      displayName: map['displayName'],
      email: map['email'],
      profilePhoto: map['profilePhoto'],
    );
  }
}
