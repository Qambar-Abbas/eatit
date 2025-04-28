class FamilyModel {
  final String familyName;
  final String adminEmail;
  final String familyCode;
  final List<String> members;
  final String? cook;
  final Map<String, dynamic> foodMenu;
  final bool isDeleted;

  FamilyModel({
    required this.familyName,
    required this.adminEmail,
    required this.familyCode,
    List<String>? members,
    this.cook,
    Map<String, dynamic>? foodMenu,
    this.isDeleted = false,
  })  : members = members ?? const [],
        foodMenu = foodMenu ?? {};

  factory FamilyModel.fromMap(Map<String, dynamic> map) {
    return FamilyModel(
      familyName: map['familyName'] as String,
      adminEmail: map['adminEmail'] as String,
      familyCode: map['familyCode'] as String,
      members: List<String>.from(map['members'] as List? ?? const []),
      cook: map['cook'] as String?,
      foodMenu: Map<String, dynamic>.from(map['foodMenu']),
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'familyName': familyName,
        'adminEmail': adminEmail,
        'familyCode': familyCode,
        'members': members,
        'cook': cook,
        'foodMenu': foodMenu,
        'isDeleted': isDeleted,
      };

  FamilyModel copyWith({
    String? familyName,
    String? adminEmail,
    String? familyCode,
    List<String>? members,
    String? cook,
    Map<String, dynamic>? foodMenu,
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
    return 'FamilyModel(familyName: $familyName, adminEmail: $adminEmail, familyCode: $familyCode, members: $members, cook: $cook, foodMenu: $foodMenu, isDeleted: $isDeleted)';
  }
}

// class FamilyModel {
//   final String familyName;
//   final String adminEmail;
//   final String familyCode;
//   final List<Map<String, String>> members;
//   final String? cook;
//   final List<Map<String, dynamic>> foodMenu;
//   bool? isDeleted;
//
//   FamilyModel({
//     required this.familyName,
//     required this.adminEmail,
//     required this.familyCode,
//     required this.members,
//     this.cook,
//     required this.foodMenu,
//     required this.isDeleted,
//   });
//
//   factory FamilyModel.fromJson(Map<String, dynamic> json) {
//     return FamilyModel(
//       familyName: json['familyName'] ?? '',
//       adminEmail: json['adminEmail'] ?? '',
//       familyCode: json['familyCode'] ?? '',
//       members: (json['members'] as List<dynamic>? ?? [])
//           .map((e) => Map<String, String>.from(e as Map))
//           .toList(),
//       cook: json['cook'] as String?,
//       foodMenu: (json['foodMenu'] as List<dynamic>? ?? [])
//           .map((e) => Map<String, dynamic>.from(e as Map))
//           .toList(),
//       isDeleted: json['isDeleted'] ?? false,
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'familyName': familyName,
//       'adminEmail': adminEmail,
//       'familyCode': familyCode,
//       'members': members,
//       'cook': cook,
//       'foodMenu': foodMenu,
//       'isDeleted': isDeleted,
//     };
//   }
//
//   FamilyModel copyWith({
//     String? familyName,
//     String? adminEmail,
//     String? familyCode,
//     List<Map<String, String>>? members,
//     String? cook,
//     List<Map<String, dynamic>>? foodMenu,
//     bool? isDeleted,
//   }) {
//     return FamilyModel(
//       familyName: familyName ?? this.familyName,
//       adminEmail: adminEmail ?? this.adminEmail,
//       familyCode: familyCode ?? this.familyCode,
//       members: members ?? this.members,
//       cook: cook ?? this.cook,
//       foodMenu: foodMenu ?? this.foodMenu,
//       isDeleted: isDeleted ?? this.isDeleted,
//     );
//   }
//
//   @override
//   String toString() {
//     return 'FamilyModel(familyName: $familyName, adminEmail: $adminEmail, familyCode: $familyCode, members: $members, cook: $cook, foodMenu: $foodMenu), isDeleted: $isDeleted';
//   }
// }
