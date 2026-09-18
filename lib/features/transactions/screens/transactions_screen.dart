import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../providers/firestore_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/month_selector.dart';
import '../widgets/transaction_tile.dart';
import 'add_edit_transaction_screen.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsForSelectedMonthProvider);
    final income = ref.watch(monthlyIncomeProvider);
    final expense = ref.watch(monthlyExpenseProvider);
    final currencyCode = ref.watch(currencyCodeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: const [Padding(padding: EdgeInsets.only(right: 8), child: MonthSelector())],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryChip(
                    label: 'Income',
                    value: formatCurrency(income, currencyCode),
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryChip(
                    label: 'Expense',
                    value: formatCurrency(expense, currencyCode),
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: transactions.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No transactions yet',
                    message: 'Tap the + button to log your first income or expense.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: transactions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return TransactionTile(
                        transaction: transaction,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddEditTransactionScreen(existing: transaction),
                          ),
                        ),
                        onDismissed: () => ref
                            .read(firestoreServiceProvider)
                            .deleteTransaction(transaction.id),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
