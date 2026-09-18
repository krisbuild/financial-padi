import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/goal_model.dart';
import '../../../providers/settings_provider.dart';

class GoalCard extends ConsumerWidget {
  const GoalCard({super.key, required this.goal, this.onTap, this.onAddFunds});

  final GoalModel goal;
  final VoidCallback? onTap;
  final VoidCallback? onAddFunds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(currencyCodeProvider);

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
                  Expanded(
                    child: Text(goal.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  if (goal.isCompleted)
                    const Icon(Icons.check_circle, color: AppColors.primary)
                  else if (onAddFunds != null)
                    TextButton(onPressed: onAddFunds, child: const Text('Add funds')),
                ],
              ),
              if (goal.targetDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Target: ${formatShortDate(goal.targetDate!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: goal.progress.toDouble(),
                  minHeight: 10,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${formatCurrency(goal.savedAmount, currencyCode)} of ${formatCurrency(goal.targetAmount, currencyCode)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
