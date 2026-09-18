import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants/category_icons.dart';

enum CategoryType { income, expense }

class CategoryModel {
  final String id;
  final String name;
  final String iconKey;
  final Color color;
  final CategoryType type;
  final bool isDefault;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.color,
    required this.type,
    this.isDefault = false,
  });

  IconData get icon => iconForKey(iconKey);

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconKey': iconKey,
      'colorValue': color.toARGB32(),
      'type': type.name,
      'isDefault': isDefault,
    };
  }

  factory CategoryModel.fromMap(String id, Map<String, dynamic> map) {
    return CategoryModel(
      id: id,
      name: map['name'] as String? ?? 'Unnamed',
      iconKey: map['iconKey'] as String? ?? 'category',
      color: Color(map['colorValue'] as int? ?? Colors.grey.toARGB32()),
      type: CategoryType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => CategoryType.expense,
      ),
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  factory CategoryModel.fromSnapshot(DocumentSnapshot doc) {
    return CategoryModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  static List<CategoryModel> defaultCategories() {
    return const [
      CategoryModel(
        id: 'salary',
        name: 'Salary',
        iconKey: 'payments',
        color: Color(0xFF2E7D32),
        type: CategoryType.income,
        isDefault: true,
      ),
      CategoryModel(
        id: 'business',
        name: 'Business',
        iconKey: 'storefront',
        color: Color(0xFF1565C0),
        type: CategoryType.income,
        isDefault: true,
      ),
      CategoryModel(
        id: 'gifts',
        name: 'Gifts',
        iconKey: 'card_giftcard',
        color: Color(0xFF6A1B9A),
        type: CategoryType.income,
        isDefault: true,
      ),
      CategoryModel(
        id: 'other_income',
        name: 'Other Income',
        iconKey: 'attach_money',
        color: Color(0xFF00838F),
        type: CategoryType.income,
        isDefault: true,
      ),
      CategoryModel(
        id: 'food',
        name: 'Food & Dining',
        iconKey: 'restaurant',
        color: Color(0xFFEF6C00),
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryModel(
        id: 'transport',
        name: 'Transport',
        iconKey: 'directions_car',
        color: Color(0xFF283593),
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryModel(
        id: 'shopping',
        name: 'Shopping',
        iconKey: 'shopping_bag',
        color: Color(0xFFAD1457),
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryModel(
        id: 'bills',
        name: 'Bills & Utilities',
        iconKey: 'receipt_long',
        color: Color(0xFFC62828),
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryModel(
        id: 'health',
        name: 'Health',
        iconKey: 'local_hospital',
        color: Color(0xFF00695C),
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryModel(
        id: 'entertainment',
        name: 'Entertainment',
        iconKey: 'movie',
        color: Color(0xFF4527A0),
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryModel(
        id: 'education',
        name: 'Education',
        iconKey: 'school',
        color: Color(0xFF2962FF),
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryModel(
        id: 'rent',
        name: 'Rent & Housing',
        iconKey: 'home',
        color: Color(0xFF37474F),
        type: CategoryType.expense,
        isDefault: true,
      ),
      CategoryModel(
        id: 'other_expense',
        name: 'Other',
        iconKey: 'more_horiz',
        color: Color(0xFF616161),
        type: CategoryType.expense,
        isDefault: true,
      ),
    ];
  }
}
