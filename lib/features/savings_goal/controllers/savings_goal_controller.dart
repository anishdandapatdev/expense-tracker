import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/savings_goal/models/savings_goal_model.dart';
import 'package:expense_tracker/features/savings_goal/repositories/savings_goal_repository.dart';
import 'package:expense_tracker/features/transactions/controllers/transaction_controller.dart';
import 'package:expense_tracker/features/auth/repositories/auth_repository.dart';
import 'package:expense_tracker/features/notifications/controllers/notification_controller.dart';

class SavingsProgress {
  final SavingsGoalModel? goal;
  final double currentSavings;
  final double targetAmount;

  SavingsProgress({
    required this.goal,
    required this.currentSavings,
    required this.targetAmount,
  });

  double get percentCompleted {
    if (targetAmount <= 0) return 0.0;
    if (currentSavings <= 0) return 0.0;
    double percent = currentSavings / targetAmount;
    return percent > 1.0 ? 1.0 : percent;
  }
}

final savingsGoalStreamProvider =
    StreamProvider.family<SavingsGoalModel?, String>((ref, userId) {
  return ref.watch(savingsGoalRepositoryProvider).getUserGoal(userId);
});

final savingsProgressProvider =
    Provider<AsyncValue<SavingsProgress>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const AsyncValue.loading();

  final transactionsAsync = ref.watch(transactionsStreamProvider(user.uid));
  final goalAsync = ref.watch(savingsGoalStreamProvider(user.uid));

  if (transactionsAsync is AsyncLoading || goalAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }

  if (transactionsAsync.hasError) {
    return AsyncValue.error(transactionsAsync.error!, transactionsAsync.stackTrace!);
  }
  if (goalAsync.hasError) {
    return AsyncValue.error(goalAsync.error!, goalAsync.stackTrace!);
  }

  final transactions = transactionsAsync.value ?? [];
  final goal = goalAsync.value;

  final now = DateTime.now();
  double totalIncome = 0;
  double totalExpense = 0;

  for (var t in transactions) {
    if (t.date.month == now.month && t.date.year == now.year) {
      if (t.type == 'income') {
        totalIncome += t.amount;
      } else if (t.type == 'expense') {
        totalExpense += t.amount;
      }
    }
  }

  final currentSavings = totalIncome - totalExpense;

  // Trigger savings goal milestone notifications if goal exists
  if (goal != null && currentSavings > 0 && goal.targetAmount > 0) {
    // Use Future.microtask to avoid modifying providers during build
    Future.microtask(() {
      try {
        ref.read(notificationSettingsProvider.notifier).checkSavingsGoalMilestone(
          goalName: 'Monthly Savings',
          savedAmount: currentSavings,
          targetAmount: goal.targetAmount,
        );
      } catch (_) {
        // Silently ignore if notification controller not ready
      }
    });
  }

  return AsyncValue.data(SavingsProgress(
    goal: goal,
    currentSavings: currentSavings,
    targetAmount: goal?.targetAmount ?? 0,
  ));
});

final savingsGoalControllerProvider = Provider<SavingsGoalController>((ref) {
  return SavingsGoalController(ref.watch(savingsGoalRepositoryProvider));
});

class SavingsGoalController {
  final SavingsGoalRepository _repository;
  SavingsGoalController(this._repository);

  Future<void> setGoalTarget(String userId, double amount) async {
    final goal = SavingsGoalModel(
      id: userId, // One global goal per user per month
      userId: userId,
      targetAmount: amount,
      createdAt: DateTime.now(),
    );
    await _repository.setGoal(goal);
  }
}
