import 'package:eatit/models/familyModel.dart';
import 'package:eatit/services/familyService.dart';
import 'package:eatit/ui/voteWidget.dart';
import 'package:flutter/material.dart';

class UserMenuScreen extends StatefulWidget {
  final void Function(int) onSwitchScreen;
  final List<FamilyModel> families;
  final String selectedFamilyCode;
  final void Function(String) onFamilyChange;

  const UserMenuScreen({
    Key? key,
    required this.onSwitchScreen,
    required this.families,
    required this.selectedFamilyCode,
    required this.onFamilyChange,
  }) : super(key: key);

  @override
  _UserMenuScreenState createState() => _UserMenuScreenState();
}

class _UserMenuScreenState extends State<UserMenuScreen> {
  late Future<List<String>> _menuItemsFuture;
  late Future<bool> _votingStatusFuture;
  String confirmedSelection = 'Nothing yet';

  @override
  void initState() {
    super.initState();
    _menuItemsFuture =
        FamilyService().getFoodMenuByTime(widget.selectedFamilyCode);
    _votingStatusFuture =
        FamilyService().getVotingStatus(widget.selectedFamilyCode);
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
              confirmedSelection,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<bool>(
              future: _votingStatusFuture,
              builder: (context, voteSnap) {
                if (voteSnap.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (voteSnap.hasError) {
                  return Text(
                    'Error loading voting status: ${voteSnap.error}',
                    style: const TextStyle(color: Colors.red),
                  );
                }

                final isVotingOpen = voteSnap.data ?? false;

                return FutureBuilder<List<String>>(
                  future: _menuItemsFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snap.hasError) {
                      return Text(
                        'Error loading menu: ${snap.error}',
                        style: const TextStyle(color: Colors.red),
                      );
                    }

                    final menuItems = snap.data!;
                    if (menuItems.isEmpty) {
                      return const Text('No menu items available.');
                    }

                    final foodItems = menuItems
                        .map((name) => FoodItem(name, 0, Colors.blueAccent))
                        .toList();

                    return VotingMenuChart(
                      items: foodItems,
                      isVotingOpen: isVotingOpen,
                      title: 'Live Voting Results',
                      subtitle: 'Votes by family members',
                      onSendVote: (selectedFood) async {
                        try {
                          await FamilyService().submitVote(
                            familyCode: widget.selectedFamilyCode,
                            selectedItem: selectedFood,
                          );
                          setState(() => confirmedSelection = selectedFood);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Your vote for $selectedFood is recorded!'),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Failed to submit vote. Please try again.')),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
