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
    List<String> labels = monthlyTrend.keys.toList();

    double maxY = 0;

    for (int i = 0; i < labels.length; i++) {
      final income = monthlyTrend[labels[i]]!['income'] ?? 0.0;
      final expense = monthlyTrend[labels[i]]!['expense'] ?? 0.0;
      
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

    // Calculate chart width for horizontal scroll
    final double groupWidth = labels.length <= 7 ? 80.0 : 55.0;
    final double screenWidth = MediaQuery.of(context).size.width - 80;
    final double chartWidth = (labels.length * groupWidth).clamp(screenWidth, double.infinity);
    final bool needsScroll = chartWidth > screenWidth;

    Widget buildLineChart({bool showLeftTitles = false, bool showBottomTitles = true}) {
      return LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY * 1.2,
          minX: 0,
          maxX: (labels.length - 1).toDouble(),
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
            bottomTitles: showBottomTitles
                ? AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (value != idx.toDouble()) return const SizedBox.shrink();
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
                  )
                : const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: showLeftTitles
                ? AxisTitles(
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
                  )
                : const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: isDarkMode ? Colors.white70 : Colors.black54, width: 1.5),
              left: showLeftTitles
                  ? BorderSide(color: isDarkMode ? Colors.white70 : Colors.black54, width: 1.5)
                  : BorderSide.none,
            ),
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
      );
    }

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
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Income - Expense Trend',
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
                // Fixed Y-axis
                SizedBox(
                  width: 50,
                  height: 280,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY * 1.2,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [],
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
                      child: buildLineChart(showLeftTitles: false, showBottomTitles: true),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          CustomLegend(
            items: {
              'Income': incomeColor,
              'Expense': expenseColor,
            },
          ),
        ],
      ),
    );
  }
}
