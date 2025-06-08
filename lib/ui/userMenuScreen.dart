import 'package:flutter/material.dart';
import 'package:eatit/models/familyModel.dart';
import 'package:eatit/services/familyService.dart';

import 'Widgets/vote_widget/voting_status_builder.dart';

//
class UserMenuScreen extends StatefulWidget {
  final void Function(int) onSwitchScreen;
  final List<FamilyModel> families;
  final String selectedFamilyCode;
  final void Function(String) onFamilyChange;

  const UserMenuScreen({
    super.key,
    required this.onSwitchScreen,
    required this.families,
    required this.selectedFamilyCode,
    required this.onFamilyChange,
  });

  @override
  State<UserMenuScreen> createState() => _UserMenuScreenState();
}

class _UserMenuScreenState extends State<UserMenuScreen> {
  late Future<List<String>> _menuItemsFuture;
  late Future<bool> _votingStatusFuture;
  String _confirmedSelection = 'Nothing yet';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    final familyCode = widget.selectedFamilyCode;
    _menuItemsFuture = FamilyService().getFoodMenuByTime(familyCode);
    _votingStatusFuture = FamilyService().getVotingStatus(familyCode);
  }

  void _handleVote(String selectedFood) async {
    try {
      await FamilyService().submitVote(
        familyCode: widget.selectedFamilyCode,
        selectedItem: selectedFood,
      );
      setState(() => _confirmedSelection = selectedFood);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your vote for $selectedFood is recorded!')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to submit vote. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "It's Lunch time",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('You are going to eat:'),
            const SizedBox(height: 4),
            Text(
              _confirmedSelection,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            VotingStatusBuilder(
              votingStatusFuture: _votingStatusFuture,
              menuItemsFuture: _menuItemsFuture,
              onVote: _handleVote,
              familyCode: widget.selectedFamilyCode,
            ),
          ],
        ),
      ),
    );
  }
}
