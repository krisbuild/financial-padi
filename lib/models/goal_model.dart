import 'package:cloud_firestore/cloud_firestore.dart';

class GoalModel {
  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime? targetDate;
  final DateTime createdAt;

  const GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.createdAt,
    this.savedAmount = 0,
    this.targetDate,
  });

  double get progress =>
      targetAmount <= 0 ? 0 : (savedAmount / targetAmount).clamp(0, 1);

  bool get isCompleted => savedAmount >= targetAmount;

  GoalModel copyWith({
    String? name,
    double? targetAmount,
    double? savedAmount,
    DateTime? targetDate,
  }) {
    return GoalModel(
      id: id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'targetDate': targetDate != null ? Timestamp.fromDate(targetDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory GoalModel.fromMap(String id, Map<String, dynamic> map) {
    return GoalModel(
      id: id,
      name: map['name'] as String? ?? 'Goal',
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
      savedAmount: (map['savedAmount'] as num?)?.toDouble() ?? 0.0,
      targetDate: (map['targetDate'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory GoalModel.fromSnapshot(DocumentSnapshot doc) {
    return GoalModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}
