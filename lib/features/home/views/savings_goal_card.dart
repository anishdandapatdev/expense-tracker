import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/features/settings/controllers/currency_controller.dart';
import 'package:expense_tracker/features/savings_goal/controllers/savings_goal_controller.dart';
import 'package:expense_tracker/features/auth/repositories/auth_repository.dart';

class SavingsGoalCard extends ConsumerWidget {
  const SavingsGoalCard({super.key});

  void _showSetGoalDialog(BuildContext context, WidgetRef ref, double currentTarget) {
    final amountController = TextEditingController(
      text: currentTarget > 0 ? currentTarget.toStringAsFixed(0) : '',
    );
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
              const Text(
                'Set Monthly Savings Goal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.savings_outlined),
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
                    final amount = double.tryParse(amountController.text) ?? 0.0;
                    if (amount > 0 && user != null) {
                      ref
                          .read(savingsGoalControllerProvider)
                          .setGoalTarget(user.uid, amount);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save Goal'),
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
    final progressAsync = ref.watch(savingsProgressProvider);
    final moneyFormat = NumberFormat('#,##0', 'en_US');

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Dynamic Colors based on theme
    final titleColor = isDarkMode ? Colors.white : const Color(0xFF2E3A59);
    final cardColor = isDarkMode ? Theme.of(context).cardColor : Colors.white;
    final borderColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;
    final shadowColor = isDarkMode ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.05);
    final iconBgColor = isDarkMode ? Colors.green.withOpacity(0.15) : const Color(0xFFE8F5E9);
    final iconColor = isDarkMode ? Colors.greenAccent : const Color(0xFF2A7865);
    final subTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    final buttonBgColor = isDarkMode ? Colors.grey.shade800 : const Color(0xFFF3F4F6);
    final progressBgColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    final feedbackTextColor = isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Monthly Savings Goal',
               style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: progressAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator())),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (progress) {
              final hasGoal = progress.goal != null;
              final currentSavings = progress.currentSavings;
              final targetAmount = progress.targetAmount;
              final percentCompleted = progress.percentCompleted;

              Color progressColor = Colors.green;
              String feedbackText = "Great job! You are on track 🎉";

              if (hasGoal) {
                if (currentSavings < 0) {
                   progressColor = Colors.red;
                   feedbackText = "You are overspending this month 📉";
                } else if (percentCompleted >= 1.0) {
                   progressColor = Colors.blue;
                   feedbackText = "Goal achieved! Keep it up 🚀";
                } else if (percentCompleted < 0.3) {
                   progressColor = Colors.orange;
                   feedbackText = "A slow start, but you can do it! 💪";
                } else if (percentCompleted < 0.7) {
                   progressColor = Colors.blueAccent;
                   feedbackText = "Doing good! Keep saving. 📈";
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.track_changes, color: iconColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasGoal ? 'Target: ${currency.symbol}${moneyFormat.format(targetAmount)}' : 'No Goal Set',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: titleColor),
                              ),
                              Text(
                                'Saved: ${currency.symbol}${moneyFormat.format(currentSavings)}',
                                style: TextStyle(color: subTextColor, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _showSetGoalDialog(context, ref, targetAmount),
                        style: TextButton.styleFrom(
                           backgroundColor: buttonBgColor,
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                           minimumSize: Size.zero,
                           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          hasGoal ? 'Update' : 'Set Goal',
                          style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white : Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (hasGoal) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percentCompleted,
                        backgroundColor: progressBgColor,
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          feedbackText,
                          style: TextStyle(color: feedbackTextColor, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                         Text(
                          '${(percentCompleted * 100).toStringAsFixed(0)}%',
                          style: TextStyle(color: progressColor, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ] else ...[
                     const SizedBox(height: 16),
                     Text(
                       "Set a savings goal to stay motivated!",
                       style: TextStyle(color: subTextColor, fontSize: 13, fontStyle: FontStyle.italic),
                     )
                  ]
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
