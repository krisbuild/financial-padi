import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/settings_provider.dart';

class BudgetProgressCard extends ConsumerWidget {
  const BudgetProgressCard({
    super.key,
    required this.progress,
    this.onTap,
    this.onDelete,
  });

  final BudgetProgress progress;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(progress.budget.categoryId));
    final currencyCode = ref.watch(currencyCodeProvider);
    final color = category?.color ?? Colors.grey;
    final percent = progress.percent.clamp(0, 1).toDouble();

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(category?.icon ?? Icons.category, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(category?.name ?? 'Category', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: onDelete,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 10,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  color: progress.isOverBudget ? Colors.red : color,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${formatCurrency(progress.spent, currencyCode)} of ${formatCurrency(progress.budget.limit, currencyCode)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    progress.isOverBudget
                        ? 'Over by ${formatCurrency(-progress.remaining, currencyCode)}'
                        : '${formatCurrency(progress.remaining, currencyCode)} left',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: progress.isOverBudget ? Colors.red : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
