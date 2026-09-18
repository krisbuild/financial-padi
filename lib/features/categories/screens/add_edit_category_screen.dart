import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/category_icons.dart';
import '../../../models/category_model.dart';
import '../../../providers/firestore_provider.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/primary_button.dart';

const _colorPalette = <Color>[
  Color(0xFF0F9D58),
  Color(0xFF2E7D32),
  Color(0xFF1565C0),
  Color(0xFF283593),
  Color(0xFF6A1B9A),
  Color(0xFF4527A0),
  Color(0xFFAD1457),
  Color(0xFFD81B60),
  Color(0xFFC62828),
  Color(0xFFEF6C00),
  Color(0xFF00838F),
  Color(0xFF00695C),
  Color(0xFF2962FF),
  Color(0xFF5E35B1),
  Color(0xFF6D4C41),
  Color(0xFF37474F),
  Color(0xFF616161),
];

class AddEditCategoryScreen extends ConsumerStatefulWidget {
  const AddEditCategoryScreen({super.key, this.existing, this.initialType});

  final CategoryModel? existing;
  final CategoryType? initialType;

  @override
  ConsumerState<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends ConsumerState<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late CategoryType _type;
  late String _iconKey;
  late Color _color;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = existing?.type ?? widget.initialType ?? CategoryType.expense;
    _iconKey = existing?.iconKey ?? categoryIcons.keys.first;
    _color = existing?.color ?? _colorPalette.first;
    if (existing != null) _nameController.text = existing.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final service = ref.read(firestoreServiceProvider);
    try {
      if (_isEditing) {
        final updated = widget.existing!.copyWith(
          name: _nameController.text.trim(),
          iconKey: _iconKey,
          color: _color,
        );
        await service.updateCategory(updated);
      } else {
        final category = CategoryModel(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          iconKey: _iconKey,
          color: _color,
          type: _type,
        );
        await service.addCategory(category);
      }
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit category' : 'New category')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: _color.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: Icon(iconForKey(_iconKey), color: _color, size: 34),
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Category name',
                  controller: _nameController,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Enter a name' : null,
                ),
                const SizedBox(height: 20),
                if (!_isEditing) ...[
                  Text('Type', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<CategoryType>(
                    segments: const [
                      ButtonSegment(value: CategoryType.expense, label: Text('Expense')),
                      ButtonSegment(value: CategoryType.income, label: Text('Income')),
                    ],
                    selected: {_type},
                    onSelectionChanged: (s) => setState(() => _type = s.first),
                  ),
                  const SizedBox(height: 20),
                ],
                Text('Icon', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: categoryIcons.entries.map((entry) {
                    final selected = entry.key == _iconKey;
                    return GestureDetector(
                      onTap: () => setState(() => _iconKey = entry.key),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected ? _color : _color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: selected ? Border.all(color: _color, width: 2) : null,
                        ),
                        child: Icon(entry.value, color: selected ? Colors.white : _color, size: 20),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text('Color', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _colorPalette.map((color) {
                    final selected = color.toARGB32() == _color.toARGB32();
                    return GestureDetector(
                      onTap: () => setState(() => _color = color),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selected ? Border.all(color: Colors.black87, width: 2) : null,
                        ),
                        child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: _isEditing ? 'Save Changes' : 'Add Category',
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
