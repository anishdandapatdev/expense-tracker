import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/auth/repositories/auth_repository.dart';
import 'package:expense_tracker/features/settings/controllers/currency_controller.dart';
import 'package:expense_tracker/features/analytics/controllers/analytics_controller.dart';
import 'package:expense_tracker/features/analytics/widgets/summary_cards_row.dart';
import 'package:expense_tracker/features/analytics/widgets/spending_bar_chart.dart';
import 'package:expense_tracker/features/analytics/widgets/spending_donut_chart.dart';
import 'package:expense_tracker/features/analytics/widgets/trend_line_chart.dart';
import 'package:expense_tracker/features/analytics/widgets/weekly_comparison_chart.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final currency = ref.watch(currencyProvider);
    final selectedTimeframe = ref.watch(timeframeProvider);
    final analyticsAsync = ref.watch(analyticsDataProvider(user?.uid ?? ''));
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
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
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: ['Weekly', 'Monthly', 'Yearly'].map((timeframe) {
                        final isSelected = selectedTimeframe == timeframe;
                        return GestureDetector(
                          onTap: () => ref.read(timeframeProvider.notifier).state = timeframe,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                            decoration: BoxDecoration(
                              border: isSelected 
                                  ? Border.all(color: isDarkMode ? Colors.white : Theme.of(context).primaryColor, width: 2) 
                                  : Border.all(color: Colors.transparent, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              timeframe,
                              style: TextStyle(
                                color: isSelected 
                                    ? (isDarkMode ? Colors.white : Theme.of(context).primaryColor)
                                    : Colors.grey,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Main scrollable content — charts use full width (no horizontal padding)
          Expanded(
            child: analyticsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (data) {
                final net = data.totalIncome - data.totalExpense;

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    // Summary Cards (with padding)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SummaryCardsRow(
                        income: data.totalIncome,
                        expense: data.totalExpense,
                        net: net,
                        currencySymbol: currency.symbol,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bar Chart — full width, no side margins
                    SpendingBarChart(monthlyTrend: data.monthlyTrend),
                    const SizedBox(height: 24),

                    // Donut Chart (with padding)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SpendingDonutChart(categorySpending: data.categorySpending),
                    ),
                    const SizedBox(height: 24),

                    // Line Chart — full width, no side margins
                    TrendLineChart(monthlyTrend: data.monthlyTrend),
                    const SizedBox(height: 24),

                    // Weekly Comparison — full width
                    WeeklyComparisonChart(data: data.weeklyComparison),
                    const SizedBox(height: 48),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
