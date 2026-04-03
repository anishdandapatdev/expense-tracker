import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'custom_legend.dart';

class SpendingBarChart extends StatelessWidget {
  final Map<String, Map<String, double>> monthlyTrend;

  const SpendingBarChart({super.key, required this.monthlyTrend});

  @override
  Widget build(BuildContext context) {
    if (monthlyTrend.isEmpty) {
      return const Center(child: Text('Not enough data.'));
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final incomeColor = isDarkMode ? Colors.greenAccent.shade400 : Colors.green;
    final expenseColor = isDarkMode ? Colors.redAccent.shade400 : Colors.red;
    final balanceColor = isDarkMode ? Colors.orangeAccent.shade400 : Colors.orange;

    List<BarChartGroupData> barGroups = [];
    List<String> months = monthlyTrend.keys.toList();
    double maxY = 0;

    // Dynamically downscale bar sizes if mapping a high-density timeline (like 30 days)
    double rodWidth = months.length > 15 ? 4 : 12;

    for (int i = 0; i < months.length; i++) {
        final monthKey = months[i];
        final data = monthlyTrend[monthKey]!;
        final income = data['income'] ?? 0.0;
        final expense = data['expense'] ?? 0.0;
        final balance = income - expense;
        
        final maxVal = [income, expense, balance].reduce((a, b) => a > b ? a : b);
        if (maxVal > maxY) maxY = maxVal;

        barGroups.add(
          BarChartGroupData(
             x: i,
             barRods: [
               BarChartRodData(
                 toY: income,
                 color: incomeColor,
                 width: rodWidth,
                 borderRadius: const BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2)),
               ),
               BarChartRodData(
                 toY: expense,
                 color: expenseColor,
                 width: rodWidth,
                 borderRadius: const BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2)),
               ),
               BarChartRodData(
                 toY: balance,
                 color: balanceColor,
                 width: rodWidth,
                 borderRadius: const BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2)),
               ),
             ],
             barsSpace: months.length > 15 ? 0 : 2, 
          )
        );
    }
    
    if (maxY == 0) maxY = 1000;
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
            'Income vs Expense vs Balance', 
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
                        interval: months.length > 12 ? (months.length / 5).ceilToDouble() : 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < months.length) {
                            if (months.length > 12 && value.toInt() % ((months.length / 5).ceil()) != 0 && value.toInt() != months.length - 1) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                months[value.toInt()],
                                style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
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
                 barGroups: barGroups,
                 alignment: BarChartAlignment.spaceEvenly,
              )
            ),
          ),
          const SizedBox(height: 16),
          CustomLegend(
            items: {
               'Income': incomeColor,
               'Expense': expenseColor,
               'Balance': balanceColor,
            }
          )
        ]
      ),
    );
  }
}
