import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expense_tracker/core/utils/category_utils.dart';

class SpendingDonutChart extends StatelessWidget {
  final Map<String, double> categorySpending;

  const SpendingDonutChart({super.key, required this.categorySpending});

  @override
  Widget build(BuildContext context) {
    if (categorySpending.isEmpty) {
      return const Center(child: Text('No expense data yet.'));
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    List<PieChartSectionData> sections = [];
    List<Widget> legendItems = [];

    categorySpending.forEach((category, amount) {
      final color = CategoryUtils.getColor(category);
      sections.add(
        PieChartSectionData(color: color, value: amount, title: '', radius: 55),
      );
      legendItems.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              category,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.grey[800],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    });

    return Container(
      height: 380,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Spending by Category', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 65,
                sectionsSpace: 3,
              ),
              duration: const Duration(milliseconds: 800),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: legendItems,
          ),
        ],
      ),
    );
  }
}
