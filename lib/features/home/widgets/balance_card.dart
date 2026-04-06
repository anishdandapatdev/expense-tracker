import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/features/transactions/views/add_transaction_screen.dart';

// ─── Balance Card ─────
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

  String _formatAmount(double amount) {
    if (amount >= 10000 || amount <= -10000) {
      return NumberFormat.compact(locale: 'en_US').format(amount);
    }
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
    return Expanded(
      child: Container(
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
            Icon(icon, color: Colors.white70, size: isSmallScreen ? 14 : 16),
            SizedBox(width: isSmallScreen ? 4 : 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isSmallScreen ? 10 : 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$symbol${_formatAmount(amount)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 14 : 16,
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmallScreen = screenWidth < 360;
    final moneyFormat = NumberFormat('#,##0.00', 'en_US');
    final isEmpty = totalBalance == 0 && totalIncome == 0;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
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
          // ── Label row: "TOTAL BALANCE" + "Add Balance" badge ──────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              // Show badge only when completely empty
              if (isEmpty)
                _buildAddIncomeButton(context),
            ],
          ),
          const SizedBox(height: 3),

          // ── Balance amount ──────────
          Text(
            '$currencySymbol${moneyFormat.format(totalBalance)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 28 : 36,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (totalBalance < 0) ...[
            const SizedBox(height: 2),
            Text(
              'You overspent $currencySymbol${moneyFormat.format(-totalBalance)} this month',
              style: TextStyle(
                color: Colors.white70,
                fontSize: isSmallScreen ? 12 : 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 8),
          Row(
            children: [
              _buildIncomeExpenseBox(
                context, 'Income', totalIncome,
                currencySymbol, Icons.arrow_upward,
                Colors.white24, isSmallScreen,
              ),
              SizedBox(width: isSmallScreen ? 8 : 16),
              _buildIncomeExpenseBox(
                context, 'Expenses', totalExpense,
                currencySymbol, Icons.arrow_downward,
                Colors.white24, isSmallScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  
  Widget _buildAddIncomeButton(BuildContext context) {
    return _PulseBtn(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AddTransactionScreen(initialType: 'Income'),
          ),
        );
      },
    );
  }
}
// ─── Static "Add Balance" Badge ───────
class _PulseBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _PulseBtn({required this.onTap});

  static const _green = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_green, _green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 5),
            Text(
              'Add Balance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}