import 'package:cloud_firestore/cloud_firestore.dart';

/// A monthly spending limit for a given category.
/// [month] is stored as 'YYYY-MM' so budgets reset each month while
/// history of past months' budgets is preserved.
class BudgetModel {
  final String id;
  final String categoryId;
  final double limit;
  final String month;
  final DateTime createdAt;

  const BudgetModel({
    required this.id,
    required this.categoryId,
    required this.limit,
    required this.month,
    required this.createdAt,
  });

  static String monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  BudgetModel copyWith({double? limit}) {
    return BudgetModel(
      id: id,
      categoryId: categoryId,
      limit: limit ?? this.limit,
      month: month,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'limit': limit,
      'month': month,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory BudgetModel.fromMap(String id, Map<String, dynamic> map) {
    return BudgetModel(
      id: id,
      categoryId: map['categoryId'] as String? ?? '',
      limit: (map['limit'] as num?)?.toDouble() ?? 0.0,
      month: map['month'] as String? ?? monthKey(DateTime.now()),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory BudgetModel.fromSnapshot(DocumentSnapshot doc) {
    return BudgetModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}
