import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expense_tracker/core/utils/category_utils.dart';
import 'package:expense_tracker/features/auth/repositories/auth_repository.dart';
import 'package:expense_tracker/features/settings/controllers/currency_controller.dart';
import 'package:expense_tracker/features/analytics/controllers/analytics_controller.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final currency = ref.watch(currencyProvider);
    final selectedTimeframe = ref.watch(timeframeProvider);

    final analyticsAsync = ref.watch(analyticsDataProvider(user?.uid ?? ''));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Analytics',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Your spending insights',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Timeframe Toggle
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: ['Weekly', 'Monthly', 'Yearly'].map((timeframe) {
                  final isSelected = selectedTimeframe == timeframe;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => ref.read(timeframeProvider.notifier).state =
                          timeframe,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            timeframe,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: analyticsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (data) {
                  String formatCompact(double val) => val >= 1000
                      ? '${(val / 1000).toStringAsFixed(1)}k'
                      : val.toStringAsFixed(0);
                  final net = data.totalIncome - data.totalExpense;

                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      Row(
                        children: [
                          _buildSummaryCard(
                            context,
                            'INCOME',
                            '${currency.symbol}${formatCompact(data.totalIncome)}',
                            Colors.green.shade50,
                            Colors.green,
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryCard(
                            context,
                            'EXPENSE',
                            '${currency.symbol}${formatCompact(data.totalExpense)}',
                            Colors.red.shade50,
                            Colors.red,
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryCard(
                            context,
                            'NET',
                            '${currency.symbol}${formatCompact(net)}',
                            Colors.blue.shade50,
                            Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _buildChartCard(
                        context,
                        title: 'Spending by Category',
                        child: _buildDonutChart(data.categorySpending),
                      ),
                      const SizedBox(height: 24),

                      _buildChartCard(
                        context,
                        title: 'Monthly Trend',
                        child: _buildLineChart(data.monthlyTrend),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String amount,
    Color bgColor,
    Color textColor,
  ) {
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
                color: textColor.withValues(alpha: 0.7),
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

  Widget _buildChartCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(height: 220, child: child),
        ],
      ),
    );
  }

  Widget _buildDonutChart(Map<String, double> categorySpending) {
    if (categorySpending.isEmpty) {
      return const Center(child: Text('No expense data yet.'));
    }

    List<PieChartSectionData> sections = [];
    List<Widget> legendItems = [];

    categorySpending.forEach((category, amount) {
      final color = CategoryUtils.getColor(category);
      sections.add(
        PieChartSectionData(color: color, value: amount, title: '', radius: 45),
      );
      legendItems.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              category,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    });

    return Column(
      children: [
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
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: legendItems,
        ),
      ],
    );
  }

  Widget _buildLineChart(Map<String, Map<String, double>> monthlyTrend) {
    if (monthlyTrend.isEmpty) {
      return const Center(child: Text('Not enough data.'));
    }

    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];
    List<String> months = monthlyTrend.keys.toList();

    // 1. Calculate the maximum value to dynamically scale the chart
    double maxY = 0;

    for (int i = 0; i < months.length; i++) {
      final income = monthlyTrend[months[i]]!['income'] ?? 0;
      final expense = monthlyTrend[months[i]]!['expense'] ?? 0;
      
      if (income > maxY) maxY = income;
      if (expense > maxY) maxY = expense;

      incomeSpots.add(FlSpot(i.toDouble(), income));
      expenseSpots.add(FlSpot(i.toDouble(), expense));
    }

    // Give the chart a default max if everything is 0
    if (maxY == 0) maxY = 1000;
    
    // 2. Calculate a dynamic interval (shows roughly 4-5 labels on the Y-axis)
    double interval = maxY / 4;
    if (interval < 100) interval = 100; // Minimum interval size

    // 3. Helper function to format large numbers (e.g., 1500 -> 1.5k, 10000 -> 10k)
    String formatYLabel(double value) {
      if (value == 0) return '0';
      if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
      if (value >= 1000) {
        // Removes the .0 if it's a clean thousand (e.g., 10.0k becomes 10k)
        return '${(value / 1000).toStringAsFixed(1)}k'.replaceAll('.0k', 'k');
      }
      return value.toInt().toString();
    }

    return Column(
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              // Add some padding to the top of the chart so lines don't hit the ceiling
              minY: 0,
              maxY: maxY * 1.2, 
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.15),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < months.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            months[value.toInt()],
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
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
                    reservedSize: 45, // Slightly increased to fit '10.5k' text
                    interval: interval, // Using our dynamic interval
                    getTitlesWidget: (value, meta) {
                      return Text(
                        formatYLabel(value), // Using our new formatting function
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: incomeSpots,
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: Colors.green,
                        strokeWidth: 0,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withValues(alpha: 0.08),
                  ),
                ),
                LineChartBarData(
                  spots: expenseSpots,
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: Colors.red,
                        strokeWidth: 0,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.red.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 800),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(width: 12, height: 3, color: Colors.green),
                const SizedBox(width: 6),
                const Text('Income', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(width: 24),
            Row(
              children: [
                Container(width: 12, height: 3, color: Colors.red),
                const SizedBox(width: 6),
                const Text('Expense', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
