import 'package:flutter/material.dart';

class SummaryCardsRow extends StatelessWidget {
  final double income;
  final double expense;
  final double net;
  final String currencySymbol;

  const SummaryCardsRow({
    super.key,
    required this.income,
    required this.expense,
    required this.net,
    required this.currencySymbol,
  });

  String _formatCompact(double val) {
    final isNegative = val < 0;
    final absVal = val.abs();
    final prefix = isNegative ? '-' : '';

    if (absVal >= 1000000) {
      return '$prefix${(absVal / 1000000).toStringAsFixed(1)}M';
    } else if (absVal >= 1000) {
      return '$prefix${(absVal / 1000).toStringAsFixed(1)}k'.replaceAll('.0k', 'k');
    }
    return '$prefix${absVal.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final incomeBg = isDarkMode ? Colors.green.withValues(alpha: 0.15) : Colors.green.shade50;
    final incomeText = isDarkMode ? Colors.greenAccent.shade400 : Colors.green;

    final expenseBg = isDarkMode ? Colors.red.withValues(alpha: 0.15) : Colors.red.shade50;
    final expenseText = isDarkMode ? Colors.redAccent.shade400 : Colors.red;

    final netBg = isDarkMode ? Colors.orange.withValues(alpha: 0.15) : Colors.orange.shade50;
    final netText = isDarkMode ? Colors.orangeAccent.shade400 : Colors.orange;

    return Row(
      children: [
        _buildCard('INCOME', '$currencySymbol${_formatCompact(income)}', incomeBg, incomeText),
        const SizedBox(width: 12),
        _buildCard('EXPENSE', '$currencySymbol${_formatCompact(expense)}', expenseBg, expenseText),
        const SizedBox(width: 12),
        _buildCard('BALANCE', '$currencySymbol${_formatCompact(net)}', netBg, netText),
      ],
    );
  }

  Widget _buildCard(String title, String amount, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
