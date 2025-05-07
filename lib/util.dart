import 'package:flutter/foundation.dart';

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
