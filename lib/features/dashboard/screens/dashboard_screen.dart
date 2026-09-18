import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/bill_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/section_header.dart';
import '../../bills/widgets/bill_tile.dart';
import '../../transactions/screens/add_edit_transaction_screen.dart';
import '../../transactions/widgets/transaction_tile.dart';
import '../widgets/balance_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(appUserProvider).value;
    final totalBalance = ref.watch(totalBalanceProvider);
    final income = ref.watch(monthlyIncomeProvider);
    final expense = ref.watch(monthlyExpenseProvider);
    final currencyCode = ref.watch(currencyCodeProvider);
    final recentTransactions = ref.watch(transactionsProvider).value ?? [];
    final upcomingBills = ref.watch(upcomingBillsProvider);
    final budgetProgress = ref.watch(budgetProgressListProvider);

    final firstName = (appUser?.displayName ?? '').split(' ').firstOrNull ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(firstName.isEmpty ? 'Financial Padi' : 'Hi, $firstName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            BalanceCard(
              balance: totalBalance,
              income: income,
              expense: expense,
              currencyCode: currencyCode,
            ),
            const SizedBox(height: 24),
            if (budgetProgress.isNotEmpty) ...[
              SectionHeader(
                title: 'Budgets this month',
                actionLabel: 'See all',
                onAction: () => context.go('/budgets'),
              ),
              const SizedBox(height: 8),
              ...budgetProgress.take(3).map(
                    (progress) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MiniBudgetBar(progress: progress.percent, isOver: progress.isOverBudget),
                    ),
                  ),
              const SizedBox(height: 16),
            ],
            if (upcomingBills.isNotEmpty) ...[
              SectionHeader(
                title: 'Upcoming bills',
                actionLabel: 'See all',
                onAction: () => context.go('/bills'),
              ),
              const SizedBox(height: 4),
              Card(
                child: Column(
                  children: upcomingBills.take(3).map((bill) => BillTile(bill: bill)).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            SectionHeader(
              title: 'Recent transactions',
              actionLabel: 'See all',
              onAction: () => context.go('/transactions'),
            ),
            const SizedBox(height: 4),
            if (recentTransactions.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No transactions yet',
                  message: 'Add your first transaction to see it here.',
                ),
              )
            else
              Card(
                child: Column(
                  children: recentTransactions
                      .take(5)
                      .map((t) => TransactionTile(transaction: t))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

class _MiniBudgetBar extends StatelessWidget {
  const _MiniBudgetBar({required this.progress, required this.isOver});

  final double progress;
  final bool isOver;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: progress.clamp(0, 1),
        minHeight: 8,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        color: isOver ? Colors.red : Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
