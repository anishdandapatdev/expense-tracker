import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/auth/repositories/auth_repository.dart';
import 'package:expense_tracker/features/settings/controllers/currency_controller.dart';
import 'package:expense_tracker/features/transactions/controllers/transaction_controller.dart';
import 'package:expense_tracker/features/home/views/transactions_list.dart';

class FullTransactionsScreen extends ConsumerWidget {
  const FullTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final currency = ref.watch(currencyProvider);
    final transactionsAsyncValue = ref.watch(
      transactionsStreamProvider(user?.uid ?? ''),
    );

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Theme.of(context).scaffoldBackgroundColor : Colors.grey[100],
      appBar: AppBar(
        title: const Text('All Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF007A3D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: transactionsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (transactions) {
          // Filter out historically hidden transactions 
          final visibleTransactions = transactions.where((t) => !t.isHidden).toList();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: TransactionsList(
                transactions: visibleTransactions,
                currencySymbol: currency.symbol,
                isPreview: false,
              ),
            ),
          );
        },
      ),
    );
  }
}
