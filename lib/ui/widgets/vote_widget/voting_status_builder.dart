import 'package:flutter/material.dart';
import 'menu_list_builder.dart';

class VotingStatusBuilder extends StatelessWidget {
  final Future<bool> votingStatusFuture;
  final Future<List<String>> menuItemsFuture;
  final void Function(String) onVote;
  final String familyCode;

  const VotingStatusBuilder({
    super.key,
    required this.votingStatusFuture,
    required this.menuItemsFuture,
    required this.onVote,
    required this.familyCode,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: votingStatusFuture,
      builder: (context, voteSnap) {
        if (voteSnap.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (voteSnap.hasError) {
          return Text('Error loading voting status: ${voteSnap.error}', style: const TextStyle(color: Colors.red));
        }

        return MenuListBuilder(
          menuItemsFuture: menuItemsFuture,
          isVotingOpen: voteSnap.data ?? false,
          onVote: onVote,
          familyCode: familyCode,
        );
      },
    );
  }
}
