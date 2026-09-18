import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/category_templates.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/category_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/primary_button.dart';

/// A short, adaptive setup flow every account goes through once. Nothing
/// here assumes a currency, income level, or spending habits — the user
/// picks all of it, so the same flow works whether they're a student
/// tracking allowance or a freelancer juggling multiple income streams.
class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

// A sensible starting subset — still fully optional, just saves new users
// a few taps. Everything else in starterCategoryTemplates is opt-in.
const _preselectedNames = {'Salary', 'Food & Drinks', 'Transport', 'Bills & Subscriptions', 'Other'};

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _currencySearchController = TextEditingController();
  int _pageIndex = 0;
  String? _currencyCode;
  final Set<String> _selectedTemplateNames = {..._preselectedNames};
  final List<CategoryTemplate> _customTemplates = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final displayName = ref.read(currentFirebaseUserProvider)?.displayName ?? '';
    _nameController.text = displayName;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _currencySearchController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    switch (_pageIndex) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _currencyCode != null;
      case 2:
        return _selectedTemplateNames.isNotEmpty || _customTemplates.isNotEmpty;
      default:
        return true;
    }
  }

  void _goNext() {
    if (_pageIndex == 2) {
      _finish();
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  void _goBack() {
    _pageController.previousPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  Future<void> _addCustomCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add your own category'),
        content: CustomTextField(label: 'Category name', controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    setState(() {
      _customTemplates.add(CategoryTemplate(
        name: name,
        iconKey: 'category',
        color: const Color(0xFF0F9D58),
        type: CategoryType.expense,
      ));
    });
  }

  Future<void> _finish() async {
    final uid = ref.read(currentFirebaseUserProvider)?.uid;
    if (uid == null || _currencyCode == null) return;
    setState(() => _isSaving = true);

    final chosen = <CategoryTemplate>[
      ...starterCategoryTemplates.where((t) => _selectedTemplateNames.contains(t.name)),
      ..._customTemplates,
    ];
    final categories = chosen
        .map((t) => CategoryModel(
              id: const Uuid().v4(),
              name: t.name,
              iconKey: t.iconKey,
              color: t.color,
              type: t.type,
            ))
        .toList();

    try {
      await ref.read(authServiceProvider).completeOnboarding(
            uid: uid,
            displayName: _nameController.text.trim(),
            currencyCode: _currencyCode!,
            categories: categories,
          );
      ref.invalidate(appUserProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final active = i == _pageIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _pageIndex = i),
                children: [
                  _NamePage(controller: _nameController, onChanged: () => setState(() {})),
                  _CurrencyPage(
                    searchController: _currencySearchController,
                    selected: _currencyCode,
                    onSelect: (code) => setState(() => _currencyCode = code),
                  ),
                  _CategoriesPage(
                    selectedNames: _selectedTemplateNames,
                    customTemplates: _customTemplates,
                    onToggle: (name) => setState(() {
                      if (_selectedTemplateNames.contains(name)) {
                        _selectedTemplateNames.remove(name);
                      } else {
                        _selectedTemplateNames.add(name);
                      }
                    }),
                    onAddCustom: _addCustomCategory,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  if (_pageIndex > 0)
                    TextButton(onPressed: _isSaving ? null : _goBack, child: const Text('Back')),
                  const Spacer(),
                  SizedBox(
                    width: 160,
                    child: PrimaryButton(
                      label: _pageIndex == 2 ? "Let's go" : 'Continue',
                      isLoading: _isSaving,
                      onPressed: _canContinue ? _goNext : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NamePage extends StatelessWidget {
  const _NamePage({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text('What should we call you?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            "We'll use this to personalize your dashboard and coach.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'Your name',
            controller: controller,
            prefixIcon: Icons.person_outline,
            onChanged: (_) => onChanged(),
          ),
        ],
      ),
    );
  }
}

class _CurrencyPage extends StatelessWidget {
  const _CurrencyPage({
    required this.searchController,
    required this.selected,
    required this.onSelect,
  });

  final TextEditingController searchController;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: searchController,
      builder: (context, _) {
        final query = searchController.text.trim().toUpperCase();
        final entries = supportedCurrencies.entries
            .where((e) => query.isEmpty || e.key.contains(query))
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('What currency do you use?', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Every amount in the app will show in this currency.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Search currency code',
                    controller: searchController,
                    prefixIcon: Icons.search,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final isSelected = entry.key == selected;
                  return ListTile(
                    onTap: () => onSelect(entry.key),
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? AppColors.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Text(
                        entry.value,
                        style: TextStyle(color: isSelected ? Colors.white : null, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(entry.key),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoriesPage extends StatelessWidget {
  const _CategoriesPage({
    required this.selectedNames,
    required this.customTemplates,
    required this.onToggle,
    required this.onAddCustom,
  });

  final Set<String> selectedNames;
  final List<CategoryTemplate> customTemplates;
  final ValueChanged<String> onToggle;
  final VoidCallback onAddCustom;

  @override
  Widget build(BuildContext context) {
    final income = starterCategoryTemplates.where((t) => t.type == CategoryType.income).toList();
    final expense = starterCategoryTemplates.where((t) => t.type == CategoryType.expense).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('What applies to you?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Pick as many as you like — you can always add, rename, or remove later.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text('Income', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: income.map((t) => _templateChip(context, t)).toList(),
          ),
          const SizedBox(height: 20),
          Text('Spending', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...expense.map((t) => _templateChip(context, t)),
              ...customTemplates.map(
                (t) => Chip(
                  avatar: const Icon(Icons.category, size: 16),
                  label: Text(t.name),
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Add your own'),
                onPressed: onAddCustom,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _templateChip(BuildContext context, CategoryTemplate template) {
    final selected = selectedNames.contains(template.name);
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onToggle(template.name),
      avatar: Icon(iconForKeyOf(template), size: 18, color: selected ? Colors.white : template.color),
      label: Text(template.name),
      selectedColor: template.color,
      labelStyle: TextStyle(color: selected ? Colors.white : null),
    );
  }
}

IconData iconForKeyOf(CategoryTemplate template) {
  return CategoryModel(
    id: '_',
    name: template.name,
    iconKey: template.iconKey,
    color: template.color,
    type: template.type,
  ).icon;
}
