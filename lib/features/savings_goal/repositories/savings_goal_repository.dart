import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/savings_goal/models/savings_goal_model.dart';

final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>((ref) {
  return SavingsGoalRepository(FirebaseFirestore.instance);
});

class SavingsGoalRepository {
  final FirebaseFirestore _firestore;

  SavingsGoalRepository(this._firestore);

  CollectionReference get _goals => _firestore.collection('savings_goals');

  Future<void> setGoal(SavingsGoalModel goal) async {
    await _goals.doc(goal.id).set(goal.toMap());
  }

  Stream<SavingsGoalModel?> getUserGoal(String userId) {
    return _goals
        .where('userId', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return SavingsGoalModel.fromMap(
            snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    });
  }
}
