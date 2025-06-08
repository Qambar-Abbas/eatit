import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/riverpods/familyRiverpod.dart';
import 'voting_menu_list.dart';
import 'voting_titles.dart';
import 'voting_chart.dart';
import 'voting_action_button.dart';

class VotingMenuChart extends ConsumerStatefulWidget {
  final String familyCode;
  final List<Map<String, dynamic>> items;
  final String title;
  final String subtitle;
  final ValueChanged<String> onSendVote;
  final bool isVotingOpen;
  final double? width;
  final double? height;

  const VotingMenuChart({
    super.key,
    required this.items,
    required this.onSendVote,
    this.title = 'Voting Results',
    this.subtitle = 'Number of votes per item',
    this.isVotingOpen = false,
    this.width,
    this.height,
    required this.familyCode,
  });

  @override
  ConsumerState<VotingMenuChart> createState() => _VotingMenuChartState();
}

class _VotingMenuChartState extends ConsumerState<VotingMenuChart> {
  late String selectedItem;

  @override
  void initState() {
    super.initState();
    selectedItem = widget.items.first['name'];
  }

  Map<String, int> countVotesByValue(Map<String, String> emailToVoteMap) {
    final Map<String, int> valueCounts = {};
    for (final vote in emailToVoteMap.values) {
      valueCounts[vote] = (valueCounts[vote] ?? 0) + 1;
    }
    return valueCounts;
  }

  @override
  Widget build(BuildContext context) {
    final votesAsyncValue = ref.watch(votesProvider(widget.familyCode));
    final voteCounts = votesAsyncValue.maybeWhen(
      data: (map) => countVotesByValue(Map<String, String>.from(map)),
      orElse: () => <String, int>{},
    );

    final maxVotes = voteCounts.values.isEmpty ? 1 : voteCounts.values.reduce((a, b) => a > b ? a : b);
    final maxY = maxVotes * 1.2;

    Widget content = SizedBox(
      width: widget.width,
      height: widget.height,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VotingMenuList(
                items: widget.items,
                selectedItem: selectedItem,
                onItemSelected: (name) => setState(() => selectedItem = name),
                height: widget.height,
              ),
              const SizedBox(height: 16),
              VotingTitles(title: widget.title, subtitle: widget.subtitle),
              const SizedBox(height: 16),
              VotingChart(
                items: widget.items,
                voteCounts: voteCounts,
                selectedItem: selectedItem,
                maxY: maxY,
                height: widget.height,
              ),
              const SizedBox(height: 16),
              VotingActionButton(
                onPressed: () => widget.onSendVote(selectedItem),
              ),
            ],
          ),
        ),
      ),
    );

    return widget.isVotingOpen ? content : Opacity(opacity: 0.5, child: AbsorbPointer(child: content));
  }
}
