import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/settings_provider.dart';

class TransactionTile extends ConsumerWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDismissed,
  });

  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(transaction.categoryId));
    final currencyCode = ref.watch(currencyCodeProvider);
    final isIncome = transaction.type == CategoryType.income;
    final color = category?.color ?? Colors.grey;

    final tile = ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(category?.icon ?? Icons.category, color: color),
      ),
      title: Text(category?.name ?? 'Uncategorized'),
      subtitle: Text(
        transaction.note.isNotEmpty
            ? '${transaction.note} · ${formatShortDate(transaction.date)}'
            : formatShortDate(transaction.date),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${isIncome ? '+' : '-'}${formatCurrency(transaction.amount, currencyCode)}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    );

    if (onDismissed == null) return tile;

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDismissed?.call(),
      child: tile,
    );
  }
}
