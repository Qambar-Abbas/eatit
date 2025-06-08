import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class VotingChart extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Map<String, int> voteCounts;
  final String selectedItem;
  final double maxY;
  final double? height;

  const VotingChart({
    super.key,
    required this.items,
    required this.voteCounts,
    required this.selectedItem,
    required this.maxY,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final chart = BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(enabled: true),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= items.length) return const SizedBox();
                return SideTitleWidget(
                  meta: meta,
                  angle: -pi / 4,
                  child: Text(
                    items[i]['name'],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                child: Text(v.toInt().toString(), style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: items.asMap().entries.map((entry) {
          final item = entry.value;
          final index = entry.key;
          final name = item['name'];
          final count = voteCounts[name] ?? 0;
          final isSel = name == selectedItem;

          return BarChartGroupData(x: index, barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: isSel ? Theme.of(context).colorScheme.primary : item['color'],
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ]);
        }).toList(),
        alignment: BarChartAlignment.spaceAround,
      ),
    );

    return height != null ? SizedBox(height: height! * 0.6, child: chart) : AspectRatio(aspectRatio: 1.7, child: chart);
  }
}
