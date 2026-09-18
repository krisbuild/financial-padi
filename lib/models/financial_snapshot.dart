/// A point-in-time summary of one user's finances, built fresh from their
/// real data on every request. The AI coach only ever sees this shape —
/// never a hardcoded income, category list, or currency — so its answers
/// scale to whoever is asking.
class CategorySpend {
  final String categoryName;
  final double amount;

  const CategorySpend({required this.categoryName, required this.amount});
}

class BudgetInsight {
  final String categoryName;
  final double limit;
  final double spent;

  const BudgetInsight({required this.categoryName, required this.limit, required this.spent});

  double get percent => limit <= 0 ? 0 : spent / limit;
  bool get isOverBudget => spent > limit;
}

class GoalInsight {
  final String name;
  final double target;
  final double saved;

  const GoalInsight({required this.name, required this.target, required this.saved});

  double get percent => target <= 0 ? 0 : (saved / target).clamp(0, 1);
  double get remaining => (target - saved).clamp(0, double.infinity);
}

class FinancialSnapshot {
  final String currencyCode;
  final String displayName;
  final double monthIncome;
  final double monthExpense;
  final double totalBalance;
  final List<CategorySpend> topCategories;
  final List<BudgetInsight> budgets;
  final List<GoalInsight> goals;
  final int upcomingBillCount;
  final double upcomingBillsTotal;
  final double previousMonthExpense;

  const FinancialSnapshot({
    required this.currencyCode,
    required this.displayName,
    required this.monthIncome,
    required this.monthExpense,
    required this.totalBalance,
    required this.topCategories,
    required this.budgets,
    required this.goals,
    required this.upcomingBillCount,
    required this.upcomingBillsTotal,
    required this.previousMonthExpense,
  });

  double get monthNet => monthIncome - monthExpense;

  double? get expenseChangePercent {
    if (previousMonthExpense <= 0) return null;
    return ((monthExpense - previousMonthExpense) / previousMonthExpense) * 100;
  }

  List<BudgetInsight> get overBudget => budgets.where((b) => b.isOverBudget).toList();
}
