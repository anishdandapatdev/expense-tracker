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

  // Helper method to format large numbers compactly (e.g., 10,000 -> 10K)
  String _formatAmount(double amount) {
    // If the amount is 10k or more (or -10k or less), use compact format
    if (amount >= 10000 || amount <= -10000) {
      return NumberFormat.compact(locale: 'en_US').format(amount);
    }
    // Otherwise, use the standard format with two decimal places
    return NumberFormat('#,##0.00', 'en_US').format(amount);
  }

  Widget _buildIncomeExpenseBox(
    BuildContext context,
    String title,
    double amount,
    String symbol,
    IconData icon,
    Color bgColor,
    bool isSmallScreen,
  ) {
    return Expanded( // Ensures the box doesn't push past the screen bounds
      child: Container(
        // Reduce padding dynamically for small screens
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 16, 
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: Colors.white70, 
              size: isSmallScreen ? 14 : 16 // Smaller icon on small screens
            ),
            SizedBox(width: isSmallScreen ? 4 : 8),
            
            // Use Expanded here to prevent the text from overflowing inside the box
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white70, 
                      fontSize: isSmallScreen ? 10 : 12, // Smaller title
                    ),
                    overflow: TextOverflow.ellipsis, // Add ellipsis just in case
                  ),
                  Text(
                    '$symbol${_formatAmount(amount)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 14 : 16, // Smaller amount font
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Detect screen width to determine if it's a small device
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmallScreen = screenWidth < 360; 
    
    final moneyFormat = NumberFormat('#,##0.00', 'en_US');

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 18), // Adjust outer padding
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
          Text(
            'TOTAL BALANCE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: isSmallScreen ? 10 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            // Keeping the total balance full-sized as it's the main focus,
            // but you could apply _formatAmount here too if you prefer!
            '$currencySymbol${moneyFormat.format(totalBalance)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 28 : 36, // Adjust main balance text size
              fontWeight: FontWeight.bold,
            ),
            // FittedBox ensures if the balance is huge, it scales down instead of wrapping
            maxLines: 1, 
          ),
          const SizedBox(height: 2),
          if (totalBalance < 0)
            Text(
              'You overspent $currencySymbol${moneyFormat.format(-totalBalance)} this month',
              style: TextStyle(
                color: Colors.white70, 
                fontSize: isSmallScreen ? 12 : 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildIncomeExpenseBox(
                context,
                'Income',
                totalIncome,
                currencySymbol,
                Icons.arrow_upward,
                Colors.white24,
                isSmallScreen,
              ),
              // Dynamic gap between the two boxes
              SizedBox(width: isSmallScreen ? 8 : 16), 
              _buildIncomeExpenseBox(
                context,
                'Expenses',
                totalExpense,
                currencySymbol,
                Icons.arrow_downward,
                Colors.white24,
                isSmallScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}