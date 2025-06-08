import 'package:flutter/material.dart';
import 'voting_menu_chart.dart';

class MenuListBuilder extends StatelessWidget {
  final Future<List<String>> menuItemsFuture;
  final bool isVotingOpen;
  final void Function(String) onVote;
  final String familyCode;

  const MenuListBuilder({
    super.key,
    required this.menuItemsFuture,
    required this.isVotingOpen,
    required this.onVote,
    required this.familyCode,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: menuItemsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snap.hasError) {
          return Text('Error loading menu: ${snap.error}', style: const TextStyle(color: Colors.red));
        }

        final foodItems = snap.data!.map((name) => {
          'name': name,
          'votes': 0,
          'color': Colors.blueAccent,
        }).toList();

        return VotingMenuChart(
          familyCode: familyCode,
          items: foodItems,
          isVotingOpen: isVotingOpen,
          onSendVote: onVote,
          title: 'Live Voting Results',
          subtitle: 'Votes by family members',
        );
      },
    );
  }
}
