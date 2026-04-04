//expense_tracker\lib\features\budgets\views\budgets_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/utils/category_utils.dart';
import 'package:expense_tracker/features/auth/repositories/auth_repository.dart';
import 'package:expense_tracker/features/settings/controllers/currency_controller.dart';
import 'package:expense_tracker/features/budgets/controllers/budget_controller.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  // A simple bottom sheet dialog to set/edit a budget limit
  void _showSetBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    String? existingCategory,
    double? existingAmount,
  ) {
    final amountController = TextEditingController(
      text: existingAmount?.toStringAsFixed(0) ?? '',
    );
    String selectedCategory = existingCategory ?? 'Food & Drink';
    final user = ref.read(authStateProvider).value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existingCategory == null ? 'Create Budget' : 'Edit Budget',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              if (existingCategory == null) ...[
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      [
                            'Food & Drink',
                            'Transport',
                            'Shopping',
                            'Entertainment',
                            'Utilities',
                          ]
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                  onChanged: (val) => selectedCategory = val!,
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Limit',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    final amount =
                        double.tryParse(amountController.text) ?? 0.0;
                    if (amount > 0 && user != null) {
                      ref
                          .read(budgetControllerProvider)
                          .setBudgetLimit(user.uid, selectedCategory, amount);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save Budget'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final progressAsync = ref.watch(budgetProgressProvider);
    final moneyFormat = NumberFormat(
      '#,##0',
      'en_US',
    ); // No decimals to match mockup

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Dynamic Colors based on theme
    final titleColor = isDarkMode ? Colors.white : const Color(0xFF2E3A59);
    final cardBgColor = isDarkMode ? Theme.of(context).cardColor : Colors.white;
    final progressBgColor = isDarkMode
        ? Colors.grey.shade800
        : Colors.grey.shade200;
    final subTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey;
    final shadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.03);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budgets',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                  onPressed: () =>
                      _showSetBudgetDialog(context, ref, null, null),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: progressAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (progressList) {
                  if (progressList.isEmpty) {
                    return Center(
                      child: TextButton(
                        onPressed: () =>
                            _showSetBudgetDialog(context, ref, null, null),
                        child: Text(
                          'No budgets set. Tap + to add one.',
                          style: TextStyle(color: subTextColor),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: progressList.length,
                    itemBuilder: (context, index) {
                      final bp = progressList[index];
                      final catColor = CategoryUtils.getColor(
                        bp.budget.category,
                      );

                      // Calculate progress bar color
                      Color progressColor = Colors.green;
                      if (bp.percentUsed >= 0.90) {
                        progressColor = Colors.red;
                      } else if (bp.percentUsed >= 0.60) {
                        progressColor = Colors.orange;
                      }

                      // Ensure progress bar doesn't overflow past 1.0 (100%)
                      final safePercent = bp.percentUsed > 1.0
                          ? 1.0
                          : bp.percentUsed;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: shadowColor,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: catColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        CategoryUtils.getIcon(
                                          bp.budget.category,
                                        ),
                                        color: catColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bp.budget.category,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: titleColor,
                                          ),
                                        ),
                                        Text(
                                          DateFormat(
                                            'MMM yyyy',
                                          ).format(DateTime.now()),
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: subTextColor,
                                    size: 20,
                                  ),
                                  onPressed: () => _showSetBudgetDialog(
                                    context,
                                    ref,
                                    bp.budget.category,
                                    bp.budget.limitAmount,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Amount Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Spent',
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(fontSize: 14),
                                    children: [
                                      TextSpan(
                                        text:
                                            '${currency.symbol}${moneyFormat.format(bp.spentAmount)} ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: titleColor,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            'of ${currency.symbol}${moneyFormat.format(bp.budget.limitAmount)}',
                                        style: TextStyle(color: subTextColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: safePercent,
                                backgroundColor: progressBgColor,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progressColor,
                                ),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Footer Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${(bp.percentUsed * 100).toStringAsFixed(0)}% used',
                                  style: TextStyle(
                                    color: progressColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  bp.amountLeft < 0
                                      ? 'Overspent by ${currency.symbol}${moneyFormat.format(bp.amountLeft.abs())}'
                                      : '${currency.symbol}${moneyFormat.format(bp.amountLeft)} left',
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
