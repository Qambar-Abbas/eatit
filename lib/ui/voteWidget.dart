// lib/ui/vote_widget.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class FoodItem {
  final String name;
  final int votes;
  final Color color;
  const FoodItem(this.name, this.votes, this.color);
}

class VotingMenuChart extends StatefulWidget {
  final List<FoodItem> items;
  final String title;
  final String subtitle;
  final ValueChanged<String> onSendVote;
  final bool isVotingOpen;
  final double? width;
  final double? height;

  VotingMenuChart({
    super.key,
    required this.items,
    required this.onSendVote,
    this.title = 'Voting Results',
    this.subtitle = 'Number of votes per item',
    this.isVotingOpen = false,
    this.width,
    this.height,
  }) : assert(items.isNotEmpty, 'Items list must not be empty.');

  @override
  _VotingMenuChartState createState() => _VotingMenuChartState();
}

class _VotingMenuChartState extends State<VotingMenuChart> {
  late String selectedItem;
  @override
  void initState() {
    super.initState();
    selectedItem = widget.items.first.name;
  }

  @override
  Widget build(BuildContext context) {
    final maxY =
        widget.items.map((e) => e.votes).fold(0, (a, b) => a > b ? a : b) * 1.2;
    Widget card = SizedBox(
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
              _buildMenuList(context),
              const SizedBox(height: 16),
              _buildTitles(context),
              const SizedBox(height: 16),
              _buildChartSection(maxY.ceilToDouble()),
              const SizedBox(height: 16),
              _buildActionButton(context),
            ],
          ),
        ),
      ),
    );

    if (!widget.isVotingOpen) {
      card = Opacity(opacity: 0.5, child: AbsorbPointer(child: card));
    }
    return card;
  }

  Widget _buildMenuList(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
          maxHeight: widget.height != null ? widget.height! * 0.3 : 200),
      child: ListView(
        children: widget.items
            .map((item) => InkWell(
                  onTap: () => setState(() => selectedItem = item.name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    color:
                        item.name == selectedItem ? Colors.blue.shade100 : null,
                    child: Text(item.name,
                        style: Theme.of(context).textTheme.bodyLarge),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildTitles(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(widget.subtitle, style: Theme.of(context).textTheme.titleMedium),
        ],
      );

  Widget _buildChartSection(double maxY) {
    final chart = BarChart(BarChartData(
      maxY: maxY,
      barTouchData: BarTouchData(enabled: true),
      gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= widget.items.length) return const SizedBox();
                return SideTitleWidget(
                  meta: meta,
                  angle: -pi / 4,
                  fitInside: const SideTitleFitInsideData(
                      enabled: true,
                      distanceFromEdge: 4,
                      parentAxisSize: 60,
                      axisPosition: 0),
                  child: Text(widget.items[i].name,
                      style: Theme.of(context).textTheme.bodySmall),
                );
              }),
        ),
        leftTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                    meta: meta,
                    space: 4,
                    child: Text(v.toInt().toString(),
                        style: Theme.of(context).textTheme.bodySmall)))),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      barGroups: widget.items.asMap().entries.map((e) {
        final item = e.value;
        final isSel = item.name == selectedItem;
        return BarChartGroupData(x: e.key, barRods: [
          BarChartRodData(
            toY: item.votes.toDouble(),
            color: isSel ? Theme.of(context).colorScheme.primary : item.color,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          )
        ]);
      }).toList(),
      alignment: BarChartAlignment.spaceAround,
    ));
    return widget.height != null
        ? SizedBox(height: widget.height! * 0.6, child: chart)
        : AspectRatio(aspectRatio: 1.7, child: chart);
  }

  Widget _buildActionButton(BuildContext context) => Center(
        child: ElevatedButton(
          onPressed: () => widget.onSendVote(selectedItem),
          style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          child: const Text('Send Vote'),
        ),
      );
}
