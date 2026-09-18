import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import 'firestore_provider.dart';

final transactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  return ref.watch(firestoreServiceProvider).watchTransactions();
});

/// The month currently selected for dashboard/report views, defaulting to
/// the current month. Stored as the first day of the month at midnight.
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final transactionsForSelectedMonthProvider =
    Provider<List<TransactionModel>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final all = ref.watch(transactionsProvider).value ?? [];
  return all
      .where((t) => t.date.year == month.year && t.date.month == month.month)
      .toList();
});

final monthlyIncomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsForSelectedMonthProvider);
  return transactions
      .where((t) => t.type == CategoryType.income)
      .fold(0.0, (sum, t) => sum + t.amount);
});

final monthlyExpenseProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsForSelectedMonthProvider);
  return transactions
      .where((t) => t.type == CategoryType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);
});

final monthlyBalanceProvider = Provider<double>((ref) {
  return ref.watch(monthlyIncomeProvider) - ref.watch(monthlyExpenseProvider);
});

final totalBalanceProvider = Provider<double>((ref) {
  final all = ref.watch(transactionsProvider).value ?? [];
  double balance = 0;
  for (final t in all) {
    balance += t.type == CategoryType.income ? t.amount : -t.amount;
  }
  return balance;
});

/// Total spent per category for the currently selected month, used by the
/// budgets screen and the reports pie chart.
final categorySpendingProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(transactionsForSelectedMonthProvider);
  final spending = <String, double>{};
  for (final t in transactions) {
    if (t.type != CategoryType.expense) continue;
    spending[t.categoryId] = (spending[t.categoryId] ?? 0) + t.amount;
  }
  return spending;
});

class MonthlyTotal {
  final DateTime month;
  final double income;
  final double expense;

  const MonthlyTotal({required this.month, required this.income, required this.expense});
}

/// Income vs. expense totals for the 6 months ending at [selectedMonthProvider],
/// used to render the reports trend chart.
final monthlyTrendProvider = Provider<List<MonthlyTotal>>((ref) {
  final selected = ref.watch(selectedMonthProvider);
  final all = ref.watch(transactionsProvider).value ?? [];

  final months = List.generate(
    6,
    (i) => DateTime(selected.year, selected.month - (5 - i)),
  );

  return months.map((month) {
    double income = 0;
    double expense = 0;
    for (final t in all) {
      if (t.date.year == month.year && t.date.month == month.month) {
        if (t.type == CategoryType.income) {
          income += t.amount;
        } else {
          expense += t.amount;
        }
      }
    }
    return MonthlyTotal(month: month, income: income, expense: expense);
  }).toList();
});
