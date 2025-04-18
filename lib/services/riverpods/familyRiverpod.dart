import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatit/models/familyModel.dart';
import 'package:eatit/services/familyService.dart';

/// Provides a singleton FamilyService
final familyServiceProvider = Provider<FamilyService>((ref) {
  return FamilyService();
});

/// Fetches all active families for a given user
final userFamiliesProvider =
FutureProvider.family<List<FamilyModel>, String>((ref, userEmail) async {
  // Read the FamilyService instance
  final familyService = ref.read(familyServiceProvider);

  // Retrieve user document to get family codes
  final userDoc = await FirebaseFirestore.instance
      .collection('users_collection')
      .doc(userEmail)
      .get();

  final codes = List<String>.from(userDoc.data()?['families'] ?? []);
  final List<FamilyModel> families = [];

  // Fetch each family by code and filter out deleted ones
  for (final code in codes) {
    final family = await familyService.getFamilyByCodeFromFirebase(code);
    if (family != null && (family.isDeleted ?? false) == false) {
      families.add(family);
    }
  }

  return families;
});


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:eatit/models/familyModel.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// final userFamiliesProvider =
//     FutureProvider.family<List<FamilyModel>, String>((ref, userEmail) async {
//   final userDoc =
//       await FirebaseFirestore.instance.collection('users_collection').doc(userEmail).get();
//
//   final codes = List<String>.from(userDoc.data()?['families'] ?? []);
//
//   final List<FamilyModel> families = [];
//   for (final code in codes) {
//     final doc =
//         await FirebaseFirestore.instance.collection('families_collection').doc(code).get();
//     final data = doc.data();
//     if (doc.exists && (data?['isDeleted'] as bool? ?? false) == false) {
//       families.add(FamilyModel.fromJson(data!));
//     }
//   }
//   return families;
//     });
