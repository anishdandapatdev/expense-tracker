import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expense_tracker/features/analytics/controllers/analytics_controller.dart';
import 'custom_legend.dart';

class WeeklyComparisonChart extends StatelessWidget {
  final WeeklyComparison data;

  const WeeklyComparisonChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final incomeColor = isDarkMode ? Colors.greenAccent.shade400 : Colors.green;
    final expenseColor = isDarkMode ? Colors.redAccent.shade400 : Colors.red;

    final maxVal = [
      data.lastWeekIncome,
      data.lastWeekExpense,
      data.thisWeekIncome,
      data.thisWeekExpense,
    ].reduce((a, b) => a > b ? a : b);
    
    double maxY = maxVal == 0 ? 1000 : maxVal;
    
    double interval = maxY / 4;
    if (interval < 100) interval = 100;

    String formatYLabel(double value) {
      if (value == 0) return '0';
      if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
      if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(1)}K'.replaceAll('.0K', 'K');
      }
      return value.toInt().toString();
    }

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
            'This Week vs Last Week', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: isDarkMode ? 0.3 : 0.15),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  )
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            value.toInt() == 0 ? 'Last Week' : 'This Week',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black87, 
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }
                    )
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          formatYLabel(value),
                          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 11),
                        );
                      }
                    )
                  )
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(bottom: BorderSide(color: isDarkMode ? Colors.white70 : Colors.black54, width: 2))
                ),
                barGroups: [
                  // Last Week Group
                  BarChartGroupData(
                    x: 0,
                    barsSpace: 12,
                    barRods: [
                      BarChartRodData(
                        toY: data.lastWeekIncome,
                        color: incomeColor.withValues(alpha: 0.5), 
                        width: 28,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: data.lastWeekExpense,
                        color: expenseColor.withValues(alpha: 0.5), 
                        width: 28,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                      ),
                    ],
                  ),
                  // This Week Group
                  BarChartGroupData(
                    x: 1,
                    barsSpace: 12,
                    barRods: [
                      BarChartRodData(
                        toY: data.thisWeekIncome,
                        color: incomeColor, 
                        width: 32, // Emphasized
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: data.thisWeekExpense,
                        color: expenseColor,
                        width: 32,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                      ),
                    ],
                  ),
                ],
                alignment: BarChartAlignment.spaceAround,
              ),
            ),
          ),
          const SizedBox(height: 16),
          CustomLegend(
            items: {
              'Income': incomeColor,
              'Expense': expenseColor,
            }
          )
        ],
      ),
    );
  }
}
