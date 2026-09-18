import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../models/bill_model.dart';
import '../../../models/category_model.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/firestore_provider.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/primary_button.dart';

class AddEditBillScreen extends ConsumerStatefulWidget {
  const AddEditBillScreen({super.key, this.existing});

  final BillModel? existing;

  @override
  ConsumerState<AddEditBillScreen> createState() => _AddEditBillScreenState();
}

class _AddEditBillScreenState extends ConsumerState<AddEditBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String? _categoryId;
  BillFrequency _frequency = BillFrequency.monthly;
  late DateTime _dueDate;
  int _reminderDays = 2;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _dueDate = existing?.nextDueDate ?? DateTime.now().add(const Duration(days: 7));
    _categoryId = existing?.categoryId;
    _frequency = existing?.frequency ?? BillFrequency.monthly;
    _reminderDays = existing?.reminderDaysBefore ?? 2;
    if (existing != null) {
      _nameController.text = existing.name;
      _amountController.text = existing.amount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _dueDate = picked);
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

    final bill = BillModel(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      categoryId: _categoryId!,
      amount: double.parse(_amountController.text),
      frequency: _frequency,
      nextDueDate: _dueDate,
      reminderDaysBefore: _reminderDays,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    try {
      final service = ref.read(firestoreServiceProvider);
      if (_isEditing) {
        await service.updateBill(bill);
      } else {
        await service.addBill(bill);
      }
      await NotificationService.instance.scheduleBillReminder(bill);
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
    final categories = ref.watch(categoriesByTypeProvider(CategoryType.expense));

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Bill' : 'New Bill')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  label: 'Bill name',
                  controller: _nameController,
                  prefixIcon: Icons.receipt_long_outlined,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Enter a name' : null,
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                SegmentedButton<BillFrequency>(
                  segments: const [
                    ButtonSegment(value: BillFrequency.weekly, label: Text('Weekly')),
                    ButtonSegment(value: BillFrequency.monthly, label: Text('Monthly')),
                    ButtonSegment(value: BillFrequency.yearly, label: Text('Yearly')),
                  ],
                  selected: {_frequency},
                  onSelectionChanged: (s) => setState(() => _frequency = s.first),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Next due date'),
                  trailing: Text(formatShortDate(_dueDate)),
                  onTap: _pickDate,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Remind me before'),
                  trailing: DropdownButton<int>(
                    value: _reminderDays,
                    items: const [0, 1, 2, 3, 5, 7]
                        .map((d) => DropdownMenuItem(value: d, child: Text(d == 0 ? 'On due date' : '$d days')))
                        .toList(),
                    onChanged: (value) => setState(() => _reminderDays = value ?? 2),
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _isEditing ? 'Save Changes' : 'Add Bill',
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
