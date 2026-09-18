import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants/category_icons.dart';

enum CategoryType { income, expense }

/// A user-defined spending or income category. Every category belongs to
/// one user (stored under `users/{uid}/categories`) and is created either
/// during onboarding (from a [CategoryTemplate] suggestion) or later via
/// the category manager — there are no fixed, shared category ids, so the
/// app never assumes what categories a given user has.
class CategoryModel {
  final String id;
  final String name;
  final String iconKey;
  final Color color;
  final CategoryType type;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.color,
    required this.type,
  });

  IconData get icon => iconForKey(iconKey);

  CategoryModel copyWith({String? name, String? iconKey, Color? color}) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      color: color ?? this.color,
      type: type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconKey': iconKey,
      'colorValue': color.toARGB32(),
      'type': type.name,
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
    );
  }

  factory CategoryModel.fromSnapshot(DocumentSnapshot doc) {
    return CategoryModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}
