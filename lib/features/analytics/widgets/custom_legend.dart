import 'package:flutter/material.dart';

class CustomLegend extends StatelessWidget {
  final Map<String, Color> items;

  const CustomLegend({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: entry.value.withValues(alpha: isDarkMode ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  entry.key == 'Income'
                      ? Icons.monetization_on
                      : entry.key == 'Expense'
                          ? Icons.money_off
                          : Icons.account_balance_wallet,
                  color: entry.value,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                entry.key,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
