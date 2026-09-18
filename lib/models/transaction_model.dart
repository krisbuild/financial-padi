import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_model.dart';

class TransactionModel {
  final String id;
  final String categoryId;
  final double amount;
  final CategoryType type;
  final String note;
  final DateTime date;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.type,
    required this.date,
    required this.createdAt,
    this.note = '',
  });

  TransactionModel copyWith({
    String? categoryId,
    double? amount,
    CategoryType? type,
    String? note,
    DateTime? date,
  }) {
    return TransactionModel(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'amount': amount,
      'type': type.name,
      'note': note,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      categoryId: map['categoryId'] as String? ?? 'other_expense',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: CategoryType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => CategoryType.expense,
      ),
      note: map['note'] as String? ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory TransactionModel.fromSnapshot(DocumentSnapshot doc) {
    return TransactionModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}
