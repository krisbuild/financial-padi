import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bill_model.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/goal_model.dart';
import '../models/transaction_model.dart';

/// Central data-access layer for all user-scoped Firestore collections.
/// Every collection lives under `users/{uid}/...` so security rules can
/// enforce per-user isolation with a single rule.
class FirestoreService {
  FirestoreService(this.uid, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _userDoc.collection('transactions');

  CollectionReference<Map<String, dynamic>> get _categories =>
      _userDoc.collection('categories');

  CollectionReference<Map<String, dynamic>> get _budgets =>
      _userDoc.collection('budgets');

  CollectionReference<Map<String, dynamic>> get _goals =>
      _userDoc.collection('goals');

  CollectionReference<Map<String, dynamic>> get _bills =>
      _userDoc.collection('bills');

  // ---------------- Transactions ----------------

  Stream<List<TransactionModel>> watchTransactions() {
    return _transactions.orderBy('date', descending: true).snapshots().map(
          (snap) => snap.docs.map(TransactionModel.fromSnapshot).toList(),
        );
  }

  Future<void> addTransaction(TransactionModel transaction) {
    return _transactions.doc(transaction.id).set(transaction.toMap());
  }

  Future<void> updateTransaction(TransactionModel transaction) {
    return _transactions.doc(transaction.id).update(transaction.toMap());
  }

  Future<void> deleteTransaction(String id) {
    return _transactions.doc(id).delete();
  }

  // ---------------- Categories ----------------

  Stream<List<CategoryModel>> watchCategories() {
    return _categories.snapshots().map(
          (snap) => snap.docs.map(CategoryModel.fromSnapshot).toList(),
        );
  }

  Future<void> addCategory(CategoryModel category) {
    return _categories.doc(category.id).set(category.toMap());
  }

  Future<void> deleteCategory(String id) {
    return _categories.doc(id).delete();
  }

  // ---------------- Budgets ----------------

  Stream<List<BudgetModel>> watchBudgetsForMonth(String month) {
    return _budgets.where('month', isEqualTo: month).snapshots().map(
          (snap) => snap.docs.map(BudgetModel.fromSnapshot).toList(),
        );
  }

  Future<void> setBudget(BudgetModel budget) {
    return _budgets.doc(budget.id).set(budget.toMap());
  }

  Future<void> deleteBudget(String id) {
    return _budgets.doc(id).delete();
  }

  // ---------------- Goals ----------------

  Stream<List<GoalModel>> watchGoals() {
    return _goals.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map(GoalModel.fromSnapshot).toList(),
        );
  }

  Future<void> addGoal(GoalModel goal) {
    return _goals.doc(goal.id).set(goal.toMap());
  }

  Future<void> updateGoal(GoalModel goal) {
    return _goals.doc(goal.id).update(goal.toMap());
  }

  Future<void> deleteGoal(String id) {
    return _goals.doc(id).delete();
  }

  // ---------------- Bills ----------------

  Stream<List<BillModel>> watchBills() {
    return _bills.orderBy('nextDueDate').snapshots().map(
          (snap) => snap.docs.map(BillModel.fromSnapshot).toList(),
        );
  }

  Future<void> addBill(BillModel bill) {
    return _bills.doc(bill.id).set(bill.toMap());
  }

  Future<void> updateBill(BillModel bill) {
    return _bills.doc(bill.id).update(bill.toMap());
  }

  Future<void> deleteBill(String id) {
    return _bills.doc(id).delete();
  }
}
