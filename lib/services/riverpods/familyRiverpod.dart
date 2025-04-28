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

