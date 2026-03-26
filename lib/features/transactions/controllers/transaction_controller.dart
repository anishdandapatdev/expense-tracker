import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/transactions/models/transaction_model.dart';
// lib\features\transactions\models\transactions_model.dart
import 'package:expense_tracker/features/transactions/repositories/transaction_repository.dart';
import 'package:flutter/foundation.dart';
// 1. Stream Provider: This automatically listens to Firestore and updates the UI instantly.
// We use .family to pass the userId into the stream.
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
      // In a production app, you might want to log this error or show a snackbar
      debugPrint('Error adding transaction: $e');
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
