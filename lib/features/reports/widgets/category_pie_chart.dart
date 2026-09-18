import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/settings_provider.dart';

class CategoryPieChart extends ConsumerStatefulWidget {
  const CategoryPieChart({super.key, required this.spendingByCategory});

  final Map<String, double> spendingByCategory;

  @override
  ConsumerState<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends ConsumerState<CategoryPieChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final currencyCode = ref.watch(currencyCodeProvider);
    final entries = widget.spendingByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold(0.0, (sum, e) => sum + e.value);

    if (entries.isEmpty || total <= 0) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('No expenses recorded this month yet.')),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 56,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response?.touchedSection == null) {
                      _touchedIndex = null;
                      return;
                    }
                    _touchedIndex = response!.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: List.generate(entries.length, (index) {
                final entry = entries[index];
                final category = ref.watch(categoryByIdProvider(entry.key));
                final isTouched = index == _touchedIndex;
                final percent = entry.value / total * 100;
                return PieChartSectionData(
                  color: category?.color ?? Colors.grey,
                  value: entry.value,
                  title: '${percent.toStringAsFixed(0)}%',
                  radius: isTouched ? 64 : 56,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: entries.map((entry) {
            final category = ref.watch(categoryByIdProvider(entry.key));
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: category?.color ?? Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${category?.name ?? 'Other'} · ${formatCurrency(entry.value, currencyCode)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
