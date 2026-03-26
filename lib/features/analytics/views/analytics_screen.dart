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

    // Fetch and compute analytics data
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

            // Handle Data Loading State
            Expanded(
              child: analyticsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (data) {
                  // Format large numbers (e.g., 3100 -> 3.1k)
                  String formatCompact(double val) => val >= 1000
                      ? '${(val / 1000).toStringAsFixed(1)}k'
                      : val.toStringAsFixed(0);
                  final net = data.totalIncome - data.totalExpense;

                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Summary Cards Row
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

                      // Donut Chart Card (Spending by Category)
                      _buildChartCard(
                        context,
                        title: 'Spending by Category',
                        child: _buildDonutChart(data.categorySpending),
                      ),
                      const SizedBox(height: 24),

                      // Line Chart Card (Monthly Trend)
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

  // Helper for Top Summary Cards
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

  // Helper for Chart Cards
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
          SizedBox(height: 200, child: child),
        ],
      ),
    );
  }

  // The Donut Chart Widget
  Widget _buildDonutChart(Map<String, double> categorySpending) {
    if (categorySpending.isEmpty) {
  return const Center(child: Text('No expense data yet.'));
}
    List<PieChartSectionData> sections = [];
    List<Widget> legendItems = [];

    categorySpending.forEach((category, amount) {
      final color = CategoryUtils.getColor(category);
      sections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title: '', // Hide text inside the chart for a cleaner look
          radius: 40, // Thickness of the donut
        ),
      );
      legendItems.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: color, size: 10),
            const SizedBox(width: 4),
            Text(
              category,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
              centerSpaceRadius: 60,
              sectionsSpace: 4, // Gap between sections
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

  // The Line Chart Widget
  Widget _buildLineChart(Map<String, Map<String, double>> monthlyTrend) {
   if (monthlyTrend.isEmpty) {
  return const Center(child: Text('Not enough data.'));
}
    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];

    // Sort months (simplified logic for demonstration)
    int i = 0;
    monthlyTrend.forEach((month, values) {
      incomeSpots.add(FlSpot(i.toDouble(), values['income'] ?? 0));
      expenseSpots.add(FlSpot(i.toDouble(), values['expense'] ?? 0));
      i++;
    });

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1),
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
                if (value.toInt() >= 0 &&
                    value.toInt() < monthlyTrend.keys.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      monthlyTrend.keys.elementAt(value.toInt()),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Income Line
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withValues(alpha: 0.1),
            ),
          ),
          // Expense Line
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 800),
    );
  }
}
