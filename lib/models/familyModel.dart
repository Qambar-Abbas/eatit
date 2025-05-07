class FamilyModel {
  final String familyName;
  final String adminEmail;
  final String familyCode;
  final List<String> members;
  final String? cook;
  final Map<String, dynamic> foodMenu;
  final bool isDeleted;
  final String selectedMeal;
  final Map<String, String> votes;
  final bool isVotingOpen;

  FamilyModel({
    required this.familyName,
    required this.adminEmail,
    required this.familyCode,
    List<String>? members,
    this.cook,
    Map<String, dynamic>? foodMenu,
    this.isDeleted = false,
    this.selectedMeal = '',
    Map<String, String>? votes,
    this.isVotingOpen = false,
  })  : members = members ?? const [],
        foodMenu = foodMenu ?? {},
        votes = votes ?? {};

  factory FamilyModel.fromMap(Map<String, dynamic> map, String docId) {
    return FamilyModel(
      familyName: map['familyName'] as String? ?? '',
      adminEmail: map['adminEmail'] as String? ?? '',
      familyCode: docId,
      members: List<String>.from(map['members'] as List? ?? []),
      cook: map['cook'] as String?,
      foodMenu: Map<String, dynamic>.from(map['foodMenu'] ?? {}),
      isDeleted: map['isDeleted'] as bool? ?? false,
      selectedMeal: map['selectedMeal'] as String? ?? '',
      votes: (map['votes'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, value as String)),
      isVotingOpen: map['isVotingOpen'] as bool? ?? false,
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
        'selectedMeal': selectedMeal,
        'votes': votes,
        'isVotingOpen': isVotingOpen,
      };

  FamilyModel copyWith({
    String? familyName,
    String? adminEmail,
    String? familyCode,
    List<String>? members,
    String? cook,
    Map<String, dynamic>? foodMenu,
    bool? isDeleted,
    String? selectedMeal,
    Map<String, String>? votes,
    bool? isVotingOpen,
  }) {
    return FamilyModel(
      familyName: familyName ?? this.familyName,
      adminEmail: adminEmail ?? this.adminEmail,
      familyCode: familyCode ?? this.familyCode,
      members: members ?? this.members,
      cook: cook ?? this.cook,
      foodMenu: foodMenu ?? this.foodMenu,
      isDeleted: isDeleted ?? this.isDeleted,
      selectedMeal: selectedMeal ?? this.selectedMeal,
      votes: votes ?? this.votes,
      isVotingOpen: isVotingOpen ?? this.isVotingOpen,
    );
  }

  @override
  String toString() {
    return 'FamilyModel(familyName: $familyName, adminEmail: $adminEmail, familyCode: $familyCode, members: $members, cook: $cook, foodMenu: $foodMenu, isDeleted: $isDeleted, selectedMeal: $selectedMeal, votes: $votes, isVotingOpen: $isVotingOpen)';
  }
}

// class FamilyModel {
//   final String familyName;
//   final String adminEmail;
//   final String familyCode;
//   final List<String> members;
//   final String? cook;
//   final Map<String, dynamic> foodMenu;
//   final bool isDeleted;
//   final String selectedMeal;
//   final Map<String, List<String>> votes;
//   final bool isVotingOpen;

//   FamilyModel({
//     required this.familyName,
//     required this.adminEmail,
//     required this.familyCode,
//     List<String>? members,
//     this.cook,
//     Map<String, dynamic>? foodMenu,
//     this.isDeleted = false,
//     this.selectedMeal = '',
//     Map<String, List<String>>? votes,
//     this.isVotingOpen = false,
//   })  : members = members ?? const [],
//         foodMenu = foodMenu ?? {},
//         votes = votes ?? {};

//   factory FamilyModel.fromMap(Map<String, dynamic> map) {
//     return FamilyModel(
//       familyName: map['familyName'] as String,
//       adminEmail: map['adminEmail'] as String,
//       familyCode: map['familyCode'] as String,
//       members: List<String>.from(map['members'] as List? ?? const []),
//       cook: map['cook'] as String?,
//       foodMenu: Map<String, dynamic>.from(map['foodMenu'] ?? {}),
//       isDeleted: map['isDeleted'] as bool? ?? false,
//       selectedMeal: map['selectedMeal'] as String? ?? '',
//       votes: (map['votes'] as Map<String, dynamic>? ?? {})
//           .map((key, value) => MapEntry(key, List<String>.from(value as List))),
//       isVotingOpen: map['isVotingOpen'] as bool? ?? false,
//     );
//   }

//   Map<String, dynamic> toMap() => {
//         'familyName': familyName,
//         'adminEmail': adminEmail,
//         'familyCode': familyCode,
//         'members': members,
//         'cook': cook,
//         'foodMenu': foodMenu,
//         'isDeleted': isDeleted,
//         'selectedMeal': selectedMeal,
//         'votes': votes,
//         'isVotingOpen': isVotingOpen,
//       };

//   FamilyModel copyWith({
//     String? familyName,
//     String? adminEmail,
//     String? familyCode,
//     List<String>? members,
//     String? cook,
//     Map<String, dynamic>? foodMenu,
//     bool? isDeleted,
//     String? selectedMeal,
//     Map<String, List<String>>? votes,
//     bool? isVotingOpen,
//   }) {
//     return FamilyModel(
//       familyName: familyName ?? this.familyName,
//       adminEmail: adminEmail ?? this.adminEmail,
//       familyCode: familyCode ?? this.familyCode,
//       members: members ?? this.members,
//       cook: cook ?? this.cook,
//       foodMenu: foodMenu ?? this.foodMenu,
//       isDeleted: isDeleted ?? this.isDeleted,
//       selectedMeal: selectedMeal ?? this.selectedMeal,
//       votes: votes ?? this.votes,
//       isVotingOpen: isVotingOpen ?? this.isVotingOpen,
//     );
//   }

//   @override
//   String toString() {
//     return 'FamilyModel(familyName: $familyName, adminEmail: $adminEmail, familyCode: $familyCode, members: $members, cook: $cook, foodMenu: $foodMenu, isDeleted: $isDeleted, selectedMeal: $selectedMeal, votes: $votes, isVotingOpen: $isVotingOpen)';
//   }
// }
