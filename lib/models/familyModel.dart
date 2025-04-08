class FamilyModel {
  final String familyName;
  final String adminEmail;
  final String familyCode;
  final List<Map<String, String>> members;
  final String? cook;
  final List<Map<String, dynamic>> foodMenu;
  bool? isDeleted;

  FamilyModel({
    required this.familyName,
    required this.adminEmail,
    required this.familyCode,
    required this.members,
    this.cook,
    required this.foodMenu,
    required this.isDeleted,
  });

  factory FamilyModel.fromJson(Map<String, dynamic> json) {
    return FamilyModel(
      familyName: json['familyName'] ?? '',
      adminEmail: json['adminEmail'] ?? '',
      familyCode: json['familyCode'] ?? '',
      members: (json['members'] as List<dynamic>? ?? [])
          .map((e) => Map<String, String>.from(e as Map))
          .toList(),
      cook: json['cook'] as String?,
      foodMenu: (json['foodMenu'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'familyName': familyName,
      'adminEmail': adminEmail,
      'familyCode': familyCode,
      'members': members,
      'cook': cook,
      'foodMenu': foodMenu,
      'isDeleted': isDeleted,
    };
  }

  FamilyModel copyWith({
    String? familyName,
    String? adminEmail,
    String? familyCode,
    List<Map<String, String>>? members,
    String? cook,
    List<Map<String, dynamic>>? foodMenu,
    bool? isDeleted,
  }) {
    return FamilyModel(
      familyName: familyName ?? this.familyName,
      adminEmail: adminEmail ?? this.adminEmail,
      familyCode: familyCode ?? this.familyCode,
      members: members ?? this.members,
      cook: cook ?? this.cook,
      foodMenu: foodMenu ?? this.foodMenu,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  String toString() {
    return 'FamilyModel(familyName: $familyName, adminEmail: $adminEmail, familyCode: $familyCode, members: $members, cook: $cook, foodMenu: $foodMenu), isDeleted: $isDeleted';
  }
}
