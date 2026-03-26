import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/utils/category_utils.dart';
import 'package:expense_tracker/features/auth/repositories/auth_repository.dart';
import 'package:expense_tracker/features/settings/controllers/currency_controller.dart';
import 'package:expense_tracker/features/transactions/controllers/transaction_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    Text(
                      user?.email?.split('@').first.toUpperCase() ?? 'USER 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.black,
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

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

                // Formatter for money (adds commas)
                final moneyFormat = NumberFormat('#,##0.00', 'en_US');

                return Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL BALANCE',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${currency.symbol}${moneyFormat.format(totalBalance)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildIncomeExpenseBox(
                                  context,
                                  'Income',
                                  totalIncome,
                                  currency.symbol,
                                  Icons.arrow_outward,
                                  Colors.white24,
                                ),
                                _buildIncomeExpenseBox(
                                  context,
                                  'Expenses',
                                  totalExpense,
                                  currency.symbol,
                                  Icons.call_received,
                                  Colors.white24,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Recent Transactions Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('See all'),
                          ),
                        ],
                      ),

                      // Transactions List
                      Expanded(
                        child: transactions.isEmpty
                            ? const Center(
                                child: Text('No transactions yet. Add one!'),
                              )
                            : ListView.builder(
                                itemCount: transactions.length,
                                itemBuilder: (context, index) {
                                  final t = transactions[index];
                                  final isIncome = t.type == 'income';
                                  final catColor = CategoryUtils.getColor(
                                    t.category,
                                  );

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                      leading: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: catColor.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          CategoryUtils.getIcon(t.category),
                                          color: catColor,
                                        ),
                                      ),
                                      title: Text(
                                        t.category,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        t.note ??
                                            DateFormat('MMM dd').format(t.date),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: Text(
                                        '${isIncome ? '+' : '-'}${currency.symbol}${moneyFormat.format(t.amount)}',
                                        style: TextStyle(
                                          color: isIncome
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for the Income/Expense mini boxes
  Widget _buildIncomeExpenseBox(
    BuildContext context,
    String title,
    double amount,
    String symbol,
    IconData icon,
    Color bgColor,
  ) {
    final moneyFormat = NumberFormat('#,##0.00', 'en_US');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '$symbol${moneyFormat.format(amount)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
