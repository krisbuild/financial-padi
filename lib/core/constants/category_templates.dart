import 'package:flutter/material.dart';

import '../../models/category_model.dart';

/// A suggested starting point for a category, offered during onboarding
/// and in "add category" flows. Picking one creates a normal, fully
/// editable [CategoryModel] with a fresh id — nothing in the app treats
/// these names or ids as special or required.
class CategoryTemplate {
  final String name;
  final String iconKey;
  final Color color;
  final CategoryType type;

  const CategoryTemplate({
    required this.name,
    required this.iconKey,
    required this.color,
    required this.type,
  });
}

const List<CategoryTemplate> starterCategoryTemplates = [
  CategoryTemplate(name: 'Salary', iconKey: 'payments', color: Color(0xFF2E7D32), type: CategoryType.income),
  CategoryTemplate(name: 'Side hustle', iconKey: 'storefront', color: Color(0xFF1565C0), type: CategoryType.income),
  CategoryTemplate(name: 'Allowance / Gifts', iconKey: 'card_giftcard', color: Color(0xFF6A1B9A), type: CategoryType.income),
  CategoryTemplate(name: 'Other income', iconKey: 'attach_money', color: Color(0xFF00838F), type: CategoryType.income),
  CategoryTemplate(name: 'Food & Drinks', iconKey: 'restaurant', color: Color(0xFFEF6C00), type: CategoryType.expense),
  CategoryTemplate(name: 'Transport', iconKey: 'directions_car', color: Color(0xFF283593), type: CategoryType.expense),
  CategoryTemplate(name: 'Shopping', iconKey: 'shopping_bag', color: Color(0xFFAD1457), type: CategoryType.expense),
  CategoryTemplate(name: 'Bills & Subscriptions', iconKey: 'receipt_long', color: Color(0xFFC62828), type: CategoryType.expense),
  CategoryTemplate(name: 'Health & Fitness', iconKey: 'fitness_center', color: Color(0xFF00695C), type: CategoryType.expense),
  CategoryTemplate(name: 'Fun & Entertainment', iconKey: 'movie', color: Color(0xFF4527A0), type: CategoryType.expense),
  CategoryTemplate(name: 'Education', iconKey: 'school', color: Color(0xFF2962FF), type: CategoryType.expense),
  CategoryTemplate(name: 'Rent / Housing', iconKey: 'home', color: Color(0xFF37474F), type: CategoryType.expense),
  CategoryTemplate(name: 'Savings', iconKey: 'flag', color: Color(0xFF0F9D58), type: CategoryType.expense),
  CategoryTemplate(name: 'Travel', iconKey: 'flight', color: Color(0xFF00838F), type: CategoryType.expense),
  CategoryTemplate(name: 'Pets', iconKey: 'pets', color: Color(0xFF6D4C41), type: CategoryType.expense),
  CategoryTemplate(name: 'Tech & Subscriptions', iconKey: 'phone_iphone', color: Color(0xFF5E35B1), type: CategoryType.expense),
  CategoryTemplate(name: 'Family & Kids', iconKey: 'child_care', color: Color(0xFFD81B60), type: CategoryType.expense),
  CategoryTemplate(name: 'Other', iconKey: 'more_horiz', color: Color(0xFF616161), type: CategoryType.expense),
];
