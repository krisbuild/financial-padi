import 'dart:math';

import '../core/utils/currency_formatter.dart';
import '../models/financial_snapshot.dart';
import 'ai_coach_service.dart';

/// A rule-based stand-in for a real LLM-backed coach. It reasons only over
/// the [FinancialSnapshot] it's given — never a fixed income, category set,
/// or currency — so its output is personalized to whoever's data it sees.
/// Swap this out for a service that calls a real model once one is wired
/// up on a backend; nothing else in the app needs to change.
class MockAiCoachService implements AiCoachService {
  @override
  List<String> insights(FinancialSnapshot s) {
    final name = _fmt(s);
    final ideas = <String>[];

    final overBudget = s.overBudget;
    if (overBudget.isNotEmpty) {
      final b = overBudget.first;
      ideas.add(
        "Heads up — you're ${name(b.spent - b.limit)} over your ${b.categoryName} budget this month. "
        "Want to trim it back for the rest of the month?",
      );
    }

    final nearLimit = s.budgets.where((b) => !b.isOverBudget && b.percent >= 0.8).toList();
    if (nearLimit.isNotEmpty) {
      final b = nearLimit.first;
      ideas.add(
        "You've used ${(b.percent * 100).round()}% of your ${b.categoryName} budget already. "
        "${name(b.limit - b.spent)} left for the rest of the month.",
      );
    }

    if (s.topCategories.isNotEmpty) {
      final top = s.topCategories.first;
      final share = s.monthExpense > 0 ? (top.amount / s.monthExpense * 100).round() : 0;
      ideas.add(
        "${top.categoryName} is your biggest expense this month at ${name(top.amount)} ($share% of spending).",
      );
    }

    final change = s.expenseChangePercent;
    if (change != null && change.abs() >= 5) {
      final direction = change > 0 ? 'up' : 'down';
      ideas.add(
        "Your spending is $direction ${change.abs().round()}% vs. last month "
        "(${name(s.monthExpense)} so far).",
      );
    }

    if (s.monthNet > 0) {
      ideas.add(
        "You're ${name(s.monthNet)} ahead this month (income minus expenses). "
        "Consider moving some of that into a goal before it gets spent.",
      );
    } else if (s.monthNet < 0 && s.monthIncome > 0) {
      ideas.add(
        "You've spent ${name(-s.monthNet)} more than you've brought in this month — "
        "worth a look at where it's going.",
      );
    }

    for (final goal in s.goals) {
      if (goal.percent >= 1) continue;
      if (goal.percent >= 0.5) {
        ideas.add(
          "You're ${(goal.percent * 100).round()}% of the way to '${goal.name}' — "
          "just ${name(goal.remaining)} to go!",
        );
      }
    }

    if (s.upcomingBillCount > 0) {
      ideas.add(
        "You have ${s.upcomingBillCount} bill${s.upcomingBillCount == 1 ? '' : 's'} due soon "
        "totaling ${name(s.upcomingBillsTotal)}. Make sure that's covered.",
      );
    }

    if (ideas.isEmpty) {
      ideas.add(
        "Log a few transactions and I'll start spotting patterns in your spending — "
        "trends, budget risks, and ways to hit your goals faster.",
      );
    }

    return ideas;
  }

  @override
  Future<String> ask(String question, FinancialSnapshot s) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final q = question.toLowerCase();
    final name = _fmt(s);

    if (q.contains('budget')) {
      if (s.budgets.isEmpty) {
        return "You don't have any budgets set up yet. Head to Budgets to set a monthly limit "
            "for a category you want to watch closely.";
      }
      final over = s.overBudget;
      if (over.isNotEmpty) {
        return "You're over budget on: ${over.map((b) => b.categoryName).join(', ')}. "
            "Everything else is on track.";
      }
      return "Your budgets look healthy right now — nothing's over its limit this month.";
    }

    if (q.contains('goal') || q.contains('save') || q.contains('saving')) {
      if (s.goals.isEmpty) {
        return "You don't have a savings goal yet — setting even a small one (like "
            "${name(50)}/month) makes it a lot easier to stay motivated.";
      }
      final lines = s.goals.map(
        (g) => "${g.name}: ${(g.percent * 100).round()}% there (${name(g.saved)} of ${name(g.target)})",
      );
      return "Here's where your goals stand:\n${lines.join('\n')}";
    }

    if (q.contains('spend') || q.contains('spent') || q.contains('expense')) {
      if (s.topCategories.isEmpty) {
        return "No expenses logged yet this month — once you add some I can break down where it's going.";
      }
      final top3 = s.topCategories.take(3).map((c) => "${c.categoryName} (${name(c.amount)})").join(', ');
      return "This month you've spent ${name(s.monthExpense)} total. Top categories: $top3.";
    }

    if (q.contains('bill')) {
      if (s.upcomingBillCount == 0) return "No bills due in the next 30 days. You're clear for now.";
      return "You have ${s.upcomingBillCount} bill${s.upcomingBillCount == 1 ? '' : 's'} coming up, "
          "totaling ${name(s.upcomingBillsTotal)}.";
    }

    if (q.contains('income') || q.contains('earn')) {
      return "You've brought in ${name(s.monthIncome)} this month.";
    }

    if (q.contains('balance') || q.contains('net worth') || q.contains('total')) {
      return "Your overall balance across everything you've logged is ${name(s.totalBalance)}.";
    }

    // Fallback: surface a relevant insight instead of a dead end.
    final ideas = insights(s);
    final pick = ideas[Random(question.hashCode).nextInt(ideas.length)];
    return "I'm a lightweight coach for now (no live AI model connected yet), but here's something "
        "from your data:\n\n$pick";
  }

  String Function(double) _fmt(FinancialSnapshot s) {
    return (amount) => formatCurrency(amount, s.currencyCode);
  }
}
