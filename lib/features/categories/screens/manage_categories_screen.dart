import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/category_model.dart';
import '../../../providers/bill_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/firestore_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../widgets/empty_state.dart';
import 'add_edit_category_screen.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, CategoryModel category) async {
    final usedByTransactions = (ref.read(transactionsProvider).value ?? [])
        .where((t) => t.categoryId == category.id)
        .length;
    final usedByBills = (ref.read(billsProvider).value ?? [])
        .where((b) => b.categoryId == category.id)
        .length;
    final inUse = usedByTransactions + usedByBills;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${category.name}"?'),
        content: Text(
          inUse > 0
              ? 'This category is used by $inUse existing entr${inUse == 1 ? 'y' : 'ies'}. They\'ll keep showing but without a category.'
              : 'This can\'t be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(firestoreServiceProvider).deleteCategory(category.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(categoriesByTypeProvider(CategoryType.income));
    final expense = ref.watch(categoriesByTypeProvider(CategoryType.expense));

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: (income.isEmpty && expense.isEmpty)
          ? EmptyState(
              icon: Icons.category_outlined,
              title: 'No categories yet',
              message: 'Add categories that match how you actually spend and earn.',
              actionLabel: 'Add category',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddEditCategoryScreen()),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 88, top: 8),
              children: [
                if (income.isNotEmpty) ...[
                  _SectionLabel('Income'),
                  ...income.map((c) => _CategoryTile(
                        category: c,
                        onEdit: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => AddEditCategoryScreen(existing: c)),
                        ),
                        onDelete: () => _confirmDelete(context, ref, c),
                      )),
                ],
                if (expense.isNotEmpty) ...[
                  _SectionLabel('Expense'),
                  ...expense.map((c) => _CategoryTile(
                        category: c,
                        onEdit: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => AddEditCategoryScreen(existing: c)),
                        ),
                        onDelete: () => _confirmDelete(context, ref, c),
                      )),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditCategoryScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onEdit, required this.onDelete});

  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onEdit,
      leading: CircleAvatar(
        backgroundColor: category.color.withValues(alpha: 0.15),
        child: Icon(category.icon, color: category.color),
      ),
      title: Text(category.name),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
    );
  }
}
