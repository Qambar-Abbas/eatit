import 'package:eatit/services/familyService.dart';
import 'package:eatit/services/riverpods/familyRiverpod.dart';
import 'package:eatit/services/riverpods/userStateRiverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VotingStatus extends ChangeNotifier {
  bool _isVotingOpen = false;

  bool get isVotingOpen => _isVotingOpen;

  void setVotingOpen(bool value) {
    if (_isVotingOpen != value) {
      _isVotingOpen = value;
      notifyListeners();
    }
  }

  void toggleVotingStatus() {
    _isVotingOpen = !_isVotingOpen;
    notifyListeners();
  }
}

// Create a global instance (singleton-style)
final votingStatus = VotingStatus();

Future<void> refreshAll(
  WidgetRef ref, {
  String? familyCode,
  String? userEmail,
}) async {
  // 1. Reload logged-in user data from cache or remote
  final userNotifier = ref.read(userStateProvider.notifier);
  await userNotifier.loadUserData();

  // Determine userEmail if not explicitly provided
  final email = userEmail ?? ref.read(userStateProvider)?.email;
  if (email != null && email.isNotEmpty) {
    // 2. Refresh the list of families for the user
    ref.refresh(userFamiliesProvider(email));
  }

  // 3. If a familyCode is provided, refresh its scoped providers
  if (familyCode != null && familyCode.isNotEmpty) {
    ref.refresh(weeklyMenuProvider(familyCode));
    ref.refresh(selectedMealProvider(familyCode));
    ref.refresh(votesProvider(familyCode));

    // 4. Optionally, re-sync voting status from Firestore
    final fs = FamilyService();
    try {
      final isOpen = await fs.getVotingStatus(familyCode);
      await fs.setVotingStatus(familyCode: familyCode, isOpen: isOpen);
    } catch (_) {
      // ignore errors in status sync
    }
  }


}
