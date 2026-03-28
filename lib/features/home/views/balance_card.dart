import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BalanceCardScreen extends StatelessWidget {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final String currencySymbol;

  const BalanceCardScreen({
    super.key,
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.currencySymbol,
  });

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

  @override
  Widget build(BuildContext context) {
    final moneyFormat = NumberFormat('#,##0.00', 'en_US');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
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
          const SizedBox(height: 6),
          Text(
            '$currencySymbol${moneyFormat.format(totalBalance)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (totalBalance < 0)
            Text(
              'You overspent $currencySymbol${moneyFormat.format(-totalBalance)} this month',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIncomeExpenseBox(
                context,
                'Income',
                totalIncome,
                currencySymbol,
                Icons.arrow_upward,
                Colors.white24,
              ),
              _buildIncomeExpenseBox(
                context,
                'Expenses',
                totalExpense,
                currencySymbol,
                Icons.arrow_downward,
                Colors.white24,
              ),
            ],
          ),
        ],
      ),
    );
  }
}