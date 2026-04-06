// lib/features/home/views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expense_tracker/features/auth/repositories/auth_repository.dart';
import 'package:expense_tracker/features/settings/controllers/currency_controller.dart';
import 'package:expense_tracker/features/transactions/controllers/transaction_controller.dart';

import '../widgets/home_header.dart';
import '../widgets/balance_card.dart';
import '../widgets/savings_goal_card.dart';
import '../widgets/weekly_chart.dart';
import '../widgets/friends_money.dart';
import '../widgets/transactions_list.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Get current user and currency
    final user = ref.watch(authStateProvider).value;
    final currency = ref.watch(currencyProvider);

    // 2. Fetch transactions stream (safely check if user is logged in)
    final transactionsAsyncValue = ref.watch(
      transactionsStreamProvider(user?.uid ?? ''),
    );

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
            
            //Externalized Header Component
            HeaderHomescreen(email: user?.email),
            
            const SizedBox(height: 14),

            // Handle Data State (Loading, Error, Success)
            transactionsAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (transactions) {
                // Calculate Totals dynamically
                double totalIncome = 0;
                double totalExpense = 0;
                for (var t in transactions) {
                  if (t.type == 'income') {
                    totalIncome += t.amount;
                  } else {
                    totalExpense += t.amount;
                  }
                }
                final totalBalance = totalIncome - totalExpense;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      //Externalized Balance Card Component
                      BalanceCardScreen(
                        totalBalance: totalBalance,
                        totalIncome: totalIncome,
                        totalExpense: totalExpense,
                        currencySymbol: currency.symbol,
                      ),
                      
                      const SizedBox(height: 16),

                      // Savings Goal Component
                      const SavingsGoalCard(),
                      
                      const SizedBox(height: 16),

                      // Weekly Expense Chart
                      const WeeklyExpenseChart(),

                      const SizedBox(height: 16),

                      // New Money with Friends Component
                      const MoneyFriendsSection(),
                      const SizedBox(height: 18),

                      // Externalized Transactions List Component
                      TransactionsList(
                        transactions: transactions.where((t) => !t.isHidden).toList(),
                        currencySymbol: currency.symbol,
                        isPreview: true,
                      ),
                      const SizedBox(height: 20), // Bottom padding
                    ],
                  );
              },
            ),
          ],
        ),
      ),
    ));
  }
}
