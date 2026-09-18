import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../models/goal_model.dart';
import '../../../providers/firestore_provider.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/primary_button.dart';

class AddGoalScreen extends ConsumerStatefulWidget {
  const AddGoalScreen({super.key});

  @override
  ConsumerState<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends ConsumerState<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _savedController = TextEditingController(text: '0');
  DateTime? _targetDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final goal = GoalModel(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      targetAmount: double.parse(_targetController.text),
      savedAmount: double.tryParse(_savedController.text) ?? 0,
      targetDate: _targetDate,
      createdAt: DateTime.now(),
    );
    try {
      await ref.read(firestoreServiceProvider).addGoal(goal);
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
    return Scaffold(
      appBar: AppBar(title: const Text('New Savings Goal')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  label: 'Goal name',
                  controller: _nameController,
                  prefixIcon: Icons.flag_outlined,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Enter a name' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Target amount',
                  controller: _targetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.attach_money,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter a target';
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Already saved (optional)',
                  controller: _savedController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.savings_outlined,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Target date (optional)'),
                  trailing: Text(_targetDate != null ? formatShortDate(_targetDate!) : 'None'),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 24),
                PrimaryButton(label: 'Save Goal', isLoading: _isSaving, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
