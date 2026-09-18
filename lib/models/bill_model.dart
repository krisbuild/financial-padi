import 'package:cloud_firestore/cloud_firestore.dart';

enum BillFrequency { weekly, monthly, yearly }

class BillModel {
  final String id;
  final String name;
  final String categoryId;
  final double amount;
  final BillFrequency frequency;
  final DateTime nextDueDate;
  final int reminderDaysBefore;
  final bool isActive;
  final DateTime createdAt;

  const BillModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.amount,
    required this.frequency,
    required this.nextDueDate,
    required this.createdAt,
    this.reminderDaysBefore = 2,
    this.isActive = true,
  });

  /// Notification id must be a stable 32-bit int derived from the bill id.
  int get notificationId => id.hashCode & 0x7fffffff;

  DateTime get reminderDate =>
      nextDueDate.subtract(Duration(days: reminderDaysBefore));

  DateTime computeNextDueDate() {
    switch (frequency) {
      case BillFrequency.weekly:
        return DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day + 7);
      case BillFrequency.monthly:
        final month = nextDueDate.month == 12 ? 1 : nextDueDate.month + 1;
        final year = nextDueDate.month == 12 ? nextDueDate.year + 1 : nextDueDate.year;
        final lastDayOfNextMonth = DateTime(year, month + 1, 0).day;
        final day = nextDueDate.day > lastDayOfNextMonth ? lastDayOfNextMonth : nextDueDate.day;
        return DateTime(year, month, day);
      case BillFrequency.yearly:
        return DateTime(nextDueDate.year + 1, nextDueDate.month, nextDueDate.day);
    }
  }

  BillModel copyWith({
    String? name,
    String? categoryId,
    double? amount,
    BillFrequency? frequency,
    DateTime? nextDueDate,
    int? reminderDaysBefore,
    bool? isActive,
  }) {
    return BillModel(
      id: id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'categoryId': categoryId,
      'amount': amount,
      'frequency': frequency.name,
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'reminderDaysBefore': reminderDaysBefore,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory BillModel.fromMap(String id, Map<String, dynamic> map) {
    return BillModel(
      id: id,
      name: map['name'] as String? ?? 'Bill',
      categoryId: map['categoryId'] as String? ?? 'bills',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      frequency: BillFrequency.values.firstWhere(
        (f) => f.name == map['frequency'],
        orElse: () => BillFrequency.monthly,
      ),
      nextDueDate: (map['nextDueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reminderDaysBefore: map['reminderDaysBefore'] as int? ?? 2,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory BillModel.fromSnapshot(DocumentSnapshot doc) {
    return BillModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}
