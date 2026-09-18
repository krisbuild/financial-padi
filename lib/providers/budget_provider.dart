import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget_model.dart';
import 'firestore_provider.dart';
import 'transaction_provider.dart';

final selectedMonthKeyProvider = Provider<String>((ref) {
  return BudgetModel.monthKey(ref.watch(selectedMonthProvider));
});

final budgetsProvider = StreamProvider<List<BudgetModel>>((ref) {
  final month = ref.watch(selectedMonthKeyProvider);
  return ref.watch(firestoreServiceProvider).watchBudgetsForMonth(month);
});

class BudgetProgress {
  final BudgetModel budget;
  final double spent;

  const BudgetProgress({required this.budget, required this.spent});

  double get percent => budget.limit <= 0 ? 0 : (spent / budget.limit).clamp(0, 2);
  double get remaining => budget.limit - spent;
  bool get isOverBudget => spent > budget.limit;
}

final budgetProgressListProvider = Provider<List<BudgetProgress>>((ref) {
  final budgets = ref.watch(budgetsProvider).value ?? [];
  final spending = ref.watch(categorySpendingProvider);
  return budgets
      .map((b) => BudgetProgress(budget: b, spent: spending[b.categoryId] ?? 0))
      .toList();
});
