import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../models/budget_model.dart';
import '../../../models/category_model.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/firestore_provider.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/primary_button.dart';

class AddBudgetScreen extends ConsumerStatefulWidget {
  const AddBudgetScreen({super.key});

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();
  String? _categoryId;
  bool _isSaving = false;

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) {
      if (_categoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
      }
      return;
    }
    setState(() => _isSaving = true);
    final month = ref.read(selectedMonthKeyProvider);
    final budget = BudgetModel(
      id: const Uuid().v4(),
      categoryId: _categoryId!,
      limit: double.parse(_limitController.text),
      month: month,
      createdAt: DateTime.now(),
    );
    try {
      await ref.read(firestoreServiceProvider).setBudget(budget);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseCategories = ref.watch(categoriesByTypeProvider(CategoryType.expense));
    final existingBudgets = ref.watch(budgetsProvider).value ?? [];
    final budgetedCategoryIds = existingBudgets.map((b) => b.categoryId).toSet();
    final availableCategories =
        expenseCategories.where((c) => !budgetedCategoryIds.contains(c.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('New Budget')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Category', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (availableCategories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('All categories already have a budget this month.'),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: availableCategories.map((category) {
                      final selected = category.id == _categoryId;
                      return ChoiceChip(
                        selected: selected,
                        onSelected: (_) => setState(() => _categoryId = category.id),
                        avatar: Icon(category.icon, size: 18, color: selected ? Colors.white : category.color),
                        label: Text(category.name),
                        selectedColor: category.color,
                        labelStyle: TextStyle(color: selected ? Colors.white : null),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Monthly limit',
                  controller: _limitController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.attach_money,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter a limit';
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Save Budget',
                  isLoading: _isSaving,
                  onPressed: availableCategories.isEmpty ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
