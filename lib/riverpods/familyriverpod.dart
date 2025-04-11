import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eatit/models/familyModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userFamiliesProvider =
    FutureProvider.family<List<FamilyModel>, String>((ref, userEmail) async {
  final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userEmail).get();

  final List<String> codes = (userDoc.data()?['families'] ?? []).cast<String>();

  List<FamilyModel> families = [];

  for (final code in codes) {
    final doc =
        await FirebaseFirestore.instance.collection('families').doc(code).get();
    if (doc.exists) {
      families.add(FamilyModel.fromJson(doc.data()!));
    }
  }

  return families;
});
