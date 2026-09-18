import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/bill_model.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/settings_provider.dart';

class BillTile extends ConsumerWidget {
  const BillTile({super.key, required this.bill, this.onTap, this.trailing});

  final BillModel bill;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(bill.categoryId));
    final currencyCode = ref.watch(currencyCodeProvider);
    final color = category?.color ?? Colors.grey;
    final isOverdue = bill.nextDueDate.isBefore(DateTime.now());

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(category?.icon ?? Icons.receipt_long, color: color),
      ),
      title: Text(bill.name),
      subtitle: Text(
        formatRelativeDueDate(bill.nextDueDate),
        style: TextStyle(color: isOverdue ? Colors.red : null),
      ),
      trailing: trailing ??
          Text(
            formatCurrency(bill.amount, currencyCode),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
    );
  }
}
