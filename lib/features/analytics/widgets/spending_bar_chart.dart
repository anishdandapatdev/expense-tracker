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
    List<String> labels = monthlyTrend.keys.toList();
    double maxY = 0;

    // Rod width adapts to data density
    double rodWidth = labels.length > 15 ? 6 : (labels.length > 7 ? 8 : 12);

    for (int i = 0; i < labels.length; i++) {
      final data = monthlyTrend[labels[i]]!;
      final income = data['income'] ?? 0.0;
      final expense = data['expense'] ?? 0.0;
      final balance = (income - expense).abs();

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
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
            BarChartRodData(
              toY: expense,
              color: expenseColor,
              width: rodWidth,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
            BarChartRodData(
              toY: balance,
              color: balanceColor,
              width: rodWidth,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
          ],
          barsSpace: 2,
        ),
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
      return value.toStringAsFixed(1);
    }

    // Calculate chart width for horizontal scroll
    // Each bar group needs ~80px minimum, more if few items
    final double groupWidth = labels.length <= 7 ? 80.0 : 65.0;
    final double screenWidth = MediaQuery.of(context).size.width - 80; // Account for padding + Y-axis
    final double chartWidth = (labels.length * groupWidth).clamp(screenWidth, double.infinity);
    final bool needsScroll = chartWidth > screenWidth;

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Income vs Expense vs Balance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 20),

          // Chart area
          SizedBox(
            height: 280,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed Y-axis on the left
                SizedBox(
                  width: 50,
                  height: 280,
                  child: BarChart(
                    BarChartData(
                      maxY: maxY * 1.2,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: [],
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (_, _) => const SizedBox.shrink(),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            interval: interval,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  formatYLabel(value),
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white70 : Colors.black54,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Scrollable chart body
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: needsScroll
                        ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      width: needsScroll ? chartWidth : null,
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
                            ),
                          ),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx >= 0 && idx < labels.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        labels[idx],
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.white70 : Colors.black54,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom: BorderSide(
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                                width: 1.5,
                              ),
                              left: BorderSide(
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                                width: 1.5,
                              ),
                            ),
                          ),
                          barGroups: barGroups,
                          alignment: BarChartAlignment.spaceEvenly,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final label = rodIndex == 0
                                    ? 'Income'
                                    : rodIndex == 1
                                        ? 'Expense'
                                        : 'Balance';
                                return BarTooltipItem(
                                  '$label\n${formatYLabel(rod.toY)}',
                                  TextStyle(
                                    color: rod.color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          CustomLegend(
            items: {
              'Income': incomeColor,
              'Expense': expenseColor,
              'Balance': balanceColor,
            },
          ),
        ],
      ),
    );
  }
}
