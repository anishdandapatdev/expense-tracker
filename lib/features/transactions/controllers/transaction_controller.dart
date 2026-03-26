import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:expense_tracker/features/transactions/models/transaction_model.dart';
import 'package:expense_tracker/features/transactions/repositories/transaction_repository.dart';

// 1. Stream Provider: This automatically listens to Firestore and updates the UI instantly.
final transactionsStreamProvider =
    StreamProvider.family<List<TransactionModel>, String>((ref, userId) {
      final repository = ref.watch(transactionRepositoryProvider);
      return repository.getUserTransactions(userId);
    });

// 2. Controller Provider: This exposes our functions to the UI.
final transactionControllerProvider = Provider<TransactionController>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionController(repository);
});

class TransactionController {
  final TransactionRepository _repository;

  TransactionController(this._repository);

  // Function to save a new transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _repository.addTransaction(transaction);
    } catch (e) {
      debugPrint('Error adding transaction: $e');
      rethrow;
    }
  }

  // Function to update an existing transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _repository.updateTransaction(transaction); 
    } catch (e) {
      debugPrint('Error updating transaction: $e');
      rethrow;
    }
  }

  // Function to delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _repository.deleteTransaction(transactionId);
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      rethrow;
    }
  }
}