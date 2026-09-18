import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/goal_model.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/firestore_provider.dart';
import '../../../providers/goal_provider.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/month_selector.dart';
import '../../goals/screens/add_goal_screen.dart';
import '../../goals/widgets/goal_card.dart';
import '../widgets/budget_progress_card.dart';
import 'add_budget_screen.dart';

class BudgetsGoalsScreen extends ConsumerStatefulWidget {
  const BudgetsGoalsScreen({super.key});

  @override
  ConsumerState<BudgetsGoalsScreen> createState() => _BudgetsGoalsScreenState();
}

class _BudgetsGoalsScreenState extends ConsumerState<BudgetsGoalsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addFunds(GoalModel goal) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add funds to ${goal.name}'),
        content: CustomTextField(
          label: 'Amount',
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: Icons.attach_money,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;
    final updated = goal.copyWith(savedAmount: goal.savedAmount + amount);
    await ref.read(firestoreServiceProvider).updateGoal(updated);
  }

  @override
  Widget build(BuildContext context) {
    final budgetProgress = ref.watch(budgetProgressListProvider);
    final goals = ref.watch(goalsProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets & Goals'),
        actions: [
          if (_tabController.index == 0) const Padding(padding: EdgeInsets.only(right: 8), child: MonthSelector()),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: const [Tab(text: 'Budgets'), Tab(text: 'Goals')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          budgetProgress.isEmpty
              ? const EmptyState(
                  icon: Icons.pie_chart_outline,
                  title: 'No budgets set',
                  message: 'Create a budget to track spending by category.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: budgetProgress.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final progress = budgetProgress[index];
                    return BudgetProgressCard(
                      progress: progress,
                      onDelete: () => ref
                          .read(firestoreServiceProvider)
                          .deleteBudget(progress.budget.id),
                    );
                  },
                ),
          goals.isEmpty
              ? const EmptyState(
                  icon: Icons.flag_outlined,
                  title: 'No savings goals yet',
                  message: 'Set a goal and track your progress toward it.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: goals.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    return GoalCard(goal: goal, onAddFunds: () => _addFunds(goal));
                  },
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _tabController.index == 0 ? const AddBudgetScreen() : const AddGoalScreen(),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
