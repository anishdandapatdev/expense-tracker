import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// EXACT IMPORT PATH - This tells Dart where to find the model
import 'package:expense_tracker/features/transactions/models/transaction_model.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(FirebaseFirestore.instance);
});

class TransactionRepository {
  final FirebaseFirestore _firestore;

  TransactionRepository(this._firestore);

  CollectionReference get _transactions => _firestore.collection('transactions');

  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _transactions.doc(transaction.id).set(transaction.toMap());
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }
  // Function to update an existing transaction in Firestore
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      // Find the specific document by its ID and update it with the new data
      await _firestore
          .collection('users')
          .doc(transaction.userId)
          .collection('transactions')
          .doc(transaction.id)
          .update(transaction.toMap()); // Make sure you have a toMap() or toJson() in your model!
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  Stream<List<TransactionModel>> getUserTransactions(String userId) {
    return _transactions
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _transactions.doc(transactionId).delete();
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }
}