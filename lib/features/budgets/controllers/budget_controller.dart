import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/budgets/models/budget_model.dart';
import 'package:expense_tracker/features/budgets/repositories/budget_repository.dart';
import 'package:expense_tracker/features/transactions/controllers/transaction_controller.dart';
import 'package:expense_tracker/features/auth/repositories/auth_repository.dart';
class BudgetProgress {
  final BudgetModel budget;
  final double spentAmount;

  BudgetProgress({required this.budget, required this.spentAmount});
  double get percentUsed => budget.limitAmount > 0 ? (spentAmount / budget.limitAmount) : 0.0;
  double get amountLeft => budget.limitAmount - spentAmount;
}

// Stream of raw budgets from Firebase
final budgetsStreamProvider = StreamProvider.family<List<BudgetModel>, String>((ref, userId) {
  return ref.watch(budgetRepositoryProvider).getUserBudgets(userId);
});

//  provider that calculates progress
final budgetProgressProvider = Provider<AsyncValue<List<BudgetProgress>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const AsyncValue.loading();

  final transactionsAsync = ref.watch(transactionsStreamProvider(user.uid));
  final budgetsAsync = ref.watch(budgetsStreamProvider(user.uid));

  // Wait until both streams have data
  if (transactionsAsync is AsyncLoading || budgetsAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }

  if (transactionsAsync.hasError) return AsyncValue.error(transactionsAsync.error!, transactionsAsync.stackTrace!);
  if (budgetsAsync.hasError) return AsyncValue.error(budgetsAsync.error!, budgetsAsync.stackTrace!);

  final transactions = transactionsAsync.value ?? [];
  final budgets = budgetsAsync.value ?? [];
  final now = DateTime.now();

  List<BudgetProgress> progressList = [];

  for (var budget in budgets) {
    double spent = 0;
    for (var t in transactions) {
      bool isCategoryMatch = (t.category == budget.category) || 
                             (budget.category == 'Food & Drink' && t.category == 'Food');

      // 2. UPDATED IF STATEMENT TO USE isCategoryMatch
      if (t.type == 'expense' && 
          isCategoryMatch && 
          t.date.month == now.month &&
          t.date.year == now.year) {
        spent += t.amount;
      }
    }
    progressList.add(BudgetProgress(budget: budget, spentAmount: spent));
  }

  return AsyncValue.data(progressList);
});

// Controller to handle adding/updating budgets
final budgetControllerProvider = Provider<BudgetController>((ref) {
  return BudgetController(ref.watch(budgetRepositoryProvider));
});

class BudgetController {
  final BudgetRepository _repository;
  BudgetController(this._repository);

  Future<void> setBudgetLimit(String userId, String category, double amount) async {
    final budget = BudgetModel(
      id: '${userId}_$category', 
      userId: userId,
      category: category,
      limitAmount: amount,
    );
    await _repository.setBudget(budget);
  }
}