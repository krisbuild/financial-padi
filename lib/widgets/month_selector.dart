import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_formatter.dart';
import '../providers/transaction_provider.dart';

class MonthSelector extends ConsumerWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            ref.read(selectedMonthProvider.notifier).state =
                DateTime(month.year, month.month - 1);
          },
        ),
        SizedBox(
          width: 120,
          child: Text(
            formatMonthYear(month),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: isCurrentMonth
              ? null
              : () {
                  ref.read(selectedMonthProvider.notifier).state =
                      DateTime(month.year, month.month + 1);
                },
        ),
      ],
    );
  }
}
