//expense_tracker\lib\features\budgets\repositories\budget_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/budgets/models/budget_model.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(FirebaseFirestore.instance);
});

class BudgetRepository {
  final FirebaseFirestore _firestore;

  BudgetRepository(this._firestore);

  CollectionReference get _budgets => _firestore.collection('budgets');

  // Save or update a budget limit
  Future<void> setBudget(BudgetModel budget) async {
    // We use the category name + userId as the document ID so each user only has one budget per category
    final docId = '${budget.userId}_${budget.category}';
    await _budgets.doc(docId).set(budget.toMap());
  }

  // Stream user's budgets
  Stream<List<BudgetModel>> getUserBudgets(String userId) {
    return _budgets
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BudgetModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }
}