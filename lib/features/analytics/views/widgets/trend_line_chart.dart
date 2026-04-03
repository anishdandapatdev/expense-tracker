import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'custom_legend.dart';

class TrendLineChart extends StatelessWidget {
  final Map<String, Map<String, double>> monthlyTrend;

  const TrendLineChart({super.key, required this.monthlyTrend});

  @override
  Widget build(BuildContext context) {
    if (monthlyTrend.isEmpty) {
      return const Center(child: Text('Not enough data.'));
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final incomeColor = isDarkMode ? Colors.greenAccent.shade400 : Colors.green;
    final expenseColor = isDarkMode ? Colors.redAccent.shade400 : Colors.red;

    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];
    List<String> months = monthlyTrend.keys.toList();

    double maxY = 0;

    for (int i = 0; i < months.length; i++) {
      final income = monthlyTrend[months[i]]!['income'] ?? 0.0;
      final expense = monthlyTrend[months[i]]!['expense'] ?? 0.0;
      
      if (income > maxY) maxY = income;
      if (expense > maxY) maxY = expense;

      incomeSpots.add(FlSpot(i.toDouble(), income));
      expenseSpots.add(FlSpot(i.toDouble(), expense));
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
            'Income - Expense Trend', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
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
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: months.length > 12 ? (months.length / 5).ceilToDouble() : 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < months.length) {
                          // Ensure we only print roughly 5 or 6 labels at the bottom if > 12 nodes
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
                      },
                    ),
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
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(bottom: BorderSide(color: isDarkMode ? Colors.white70 : Colors.black54, width: 2))
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: incomeSpots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    curveSmoothness: 0.35,
                    color: incomeColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    shadow: Shadow(color: incomeColor.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 4)),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: incomeColor,
                          strokeWidth: 0,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          incomeColor.withValues(alpha: 0.35),
                          incomeColor.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: expenseSpots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    curveSmoothness: 0.35,
                    color: expenseColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    shadow: Shadow(color: expenseColor.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 4)),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: expenseColor,
                          strokeWidth: 0,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          expenseColor.withValues(alpha: 0.35),
                          expenseColor.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 800),
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
