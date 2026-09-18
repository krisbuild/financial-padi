import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/firestore_provider.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/primary_button.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  const AddEditTransactionScreen({super.key, this.existing});

  final TransactionModel? existing;

  @override
  ConsumerState<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends ConsumerState<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late CategoryType _type;
  String? _categoryId;
  late DateTime _date;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = existing?.type ?? CategoryType.expense;
    _categoryId = existing?.categoryId;
    _date = existing?.date ?? DateTime.now();
    if (existing != null) {
      _amountController.text = existing.amount.toStringAsFixed(2);
      _noteController.text = existing.note;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    setState(() => _isSaving = true);

    final amount = double.parse(_amountController.text);
    final service = ref.read(firestoreServiceProvider);

    try {
      if (_isEditing) {
        final updated = widget.existing!.copyWith(
          categoryId: _categoryId,
          amount: amount,
          type: _type,
          note: _noteController.text.trim(),
          date: _date,
        );
        await service.updateTransaction(updated);
      } else {
        final transaction = TransactionModel(
          id: const Uuid().v4(),
          categoryId: _categoryId!,
          amount: amount,
          type: _type,
          note: _noteController.text.trim(),
          date: _date,
          createdAt: DateTime.now(),
        );
        await service.addTransaction(transaction);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesByTypeProvider(_type));

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<CategoryType>(
                  segments: const [
                    ButtonSegment(value: CategoryType.expense, label: Text('Expense'), icon: Icon(Icons.arrow_upward)),
                    ButtonSegment(value: CategoryType.income, label: Text('Income'), icon: Icon(Icons.arrow_downward)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _type = selection.first;
                      _categoryId = null;
                    });
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Amount',
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.attach_money,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter an amount';
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text('Category', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: categories.map((category) {
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Date'),
                  trailing: Text(formatShortDate(_date)),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Note (optional)',
                  controller: _noteController,
                  prefixIcon: Icons.notes,
                  maxLines: 2,
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: _isEditing ? 'Save Changes' : 'Add Transaction',
                  isLoading: _isSaving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
