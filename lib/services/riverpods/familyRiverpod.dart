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
    if (family != null && family.isDeleted == false) {
      families.add(family);
    }
  }

  return families;
});

/// Emits the `foodMenu` map whenever the family doc changes.
final weeklyMenuProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, familyCode) {
  final col = FirebaseFirestore.instance.collection('families_collection');
  return col
      .doc(familyCode)
      .snapshots()
      .map((snap) => (snap.data()?['foodMenu'] as Map<String, dynamic>));
});

/// Emits the `selectedMeal` string whenever the family doc changes.
final selectedMealProvider =
    StreamProvider.family<String, String>((ref, familyCode) {
  final col = FirebaseFirestore.instance.collection('families_collection');
  return col
      .doc(familyCode)
      .snapshots()
      .map((snap) => (snap.data()?['selectedMeal'] ?? '') as String);
});
