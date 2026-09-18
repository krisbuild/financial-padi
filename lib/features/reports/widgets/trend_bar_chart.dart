import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../providers/transaction_provider.dart';

class TrendBarChart extends StatelessWidget {
  const TrendBarChart({super.key, required this.data});

  final List<MonthlyTotal> data;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.fold<double>(
      0,
      (max, t) => [max, t.income, t.expense].reduce((a, b) => a > b ? a : b),
    );
    final maxY = maxValue <= 0 ? 100.0 : maxValue * 1.2;

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('MMM').format(data[index].month),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(data.length, (index) {
            final item = data[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item.income,
                  color: Colors.green.shade400,
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: item.expense,
                  color: Colors.red.shade400,
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
              barsSpace: 4,
            );
          }),
        ),
      ),
    );
  }
}
