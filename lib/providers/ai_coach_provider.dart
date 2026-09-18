import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/category_model.dart';
import '../models/chat_message.dart';
import '../models/financial_snapshot.dart';
import '../services/ai_coach_service.dart';
import '../services/mock_ai_coach_service.dart';
import 'auth_provider.dart';
import 'bill_provider.dart';
import 'budget_provider.dart';
import 'category_provider.dart';
import 'goal_provider.dart';
import 'transaction_provider.dart';

final aiCoachServiceProvider = Provider<AiCoachService>((ref) => MockAiCoachService());

/// A fresh, fully data-driven picture of the signed-in user's finances for
/// the coach to reason over — built from real Firestore data, reflecting
/// whatever currency, categories, and habits are actually theirs.
final financialSnapshotProvider = Provider<FinancialSnapshot>((ref) {
  final appUser = ref.watch(appUserProvider).value;
  final categories = ref.watch(categoriesProvider).value ?? [];
  final allTransactions = ref.watch(transactionsProvider).value ?? [];
  final now = DateTime.now();
  final previousMonth = DateTime(now.year, now.month - 1);

  String categoryName(String id) {
    for (final c in categories) {
      if (c.id == id) return c.name;
    }
    return 'Uncategorized';
  }

  double sumForMonth(DateTime month, {required CategoryType type}) {
    return allTransactions
        .where((t) =>
            t.type == type && t.date.year == month.year && t.date.month == month.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  final monthIncome = sumForMonth(now, type: CategoryType.income);
  final monthExpense = sumForMonth(now, type: CategoryType.expense);
  final previousMonthExpense = sumForMonth(previousMonth, type: CategoryType.expense);

  final spendByCategory = <String, double>{};
  for (final t in allTransactions) {
    if (t.type != CategoryType.expense) continue;
    if (t.date.year != now.year || t.date.month != now.month) continue;
    spendByCategory[t.categoryId] = (spendByCategory[t.categoryId] ?? 0) + t.amount;
  }
  final topCategories = spendByCategory.entries
      .map((e) => CategorySpend(categoryName: categoryName(e.key), amount: e.value))
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  final budgets = ref.watch(currentMonthBudgetsProvider).value ?? [];
  final budgetInsights = budgets
      .map((b) => BudgetInsight(
            categoryName: categoryName(b.categoryId),
            limit: b.limit,
            spent: spendByCategory[b.categoryId] ?? 0,
          ))
      .toList();

  final goals = ref.watch(goalsProvider).value ?? [];
  final goalInsights = goals
      .map((g) => GoalInsight(name: g.name, target: g.targetAmount, saved: g.savedAmount))
      .toList();

  final upcomingBills = ref.watch(upcomingBillsProvider);
  final upcomingBillsTotal = upcomingBills.fold(0.0, (sum, b) => sum + b.amount);

  double balance = 0;
  for (final t in allTransactions) {
    balance += t.type == CategoryType.income ? t.amount : -t.amount;
  }

  return FinancialSnapshot(
    currencyCode: (appUser?.currencyCode.isNotEmpty ?? false) ? appUser!.currencyCode : 'USD',
    displayName: appUser?.displayName ?? '',
    monthIncome: monthIncome,
    monthExpense: monthExpense,
    totalBalance: balance,
    topCategories: topCategories,
    budgets: budgetInsights,
    goals: goalInsights,
    upcomingBillCount: upcomingBills.length,
    upcomingBillsTotal: upcomingBillsTotal,
    previousMonthExpense: previousMonthExpense,
  );
});

/// One relevant insight for a given moment — stable across rebuilds within
/// the same minute so the home card doesn't flicker between options.
final dailyInsightProvider = Provider<String>((ref) {
  final snapshot = ref.watch(financialSnapshotProvider);
  final insights = ref.watch(aiCoachServiceProvider).insights(snapshot);
  final index = DateTime.now().day % insights.length;
  return insights[index];
});

/// Whether the coach is "typing" a reply — separate from the message list
/// so the UI can show a typing indicator without it being just another
/// message in the transcript.
final chatSendingProvider = StateProvider<bool>((ref) => false);

class ChatNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() => [];

  Future<void> send(String text) async {
    if (text.trim().isEmpty || ref.read(chatSendingProvider)) return;
    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      role: ChatRole.user,
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    state = [...state, userMessage];
    ref.read(chatSendingProvider.notifier).state = true;

    final snapshot = ref.read(financialSnapshotProvider);
    final reply = await ref.read(aiCoachServiceProvider).ask(text, snapshot);

    final coachMessage = ChatMessage(
      id: const Uuid().v4(),
      role: ChatRole.coach,
      text: reply,
      createdAt: DateTime.now(),
    );
    ref.read(chatSendingProvider.notifier).state = false;
    state = [...state, coachMessage];
  }
}

final chatMessagesProvider = NotifierProvider<ChatNotifier, List<ChatMessage>>(ChatNotifier.new);
