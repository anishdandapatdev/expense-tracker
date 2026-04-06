import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/auth/repositories/auth_repository.dart';
import 'package:expense_tracker/features/settings/controllers/currency_controller.dart';
import 'package:expense_tracker/features/transactions/controllers/transaction_controller.dart';
import 'package:intl/intl.dart';

class WeeklyExpenseChart extends ConsumerWidget {
  const WeeklyExpenseChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final currency = ref.watch(currencyProvider);
    final transactionsAsync = ref.watch(
      transactionsStreamProvider(user?.uid ?? ''),
    );

    return transactionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (transactions) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final now = DateTime.now();

        // Week: Sunday → Saturday
        final daysSinceSunday = now.weekday == 7 ? 0 : now.weekday;
        final sunday = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: daysSinceSunday));

        // Build 7-day structure
        final List<String> dayLabels = [];
        final List<double> dailyExpense = [];
        double weekTotal = 0;

        for (int i = 0; i < 7; i++) {
          final day = sunday.add(Duration(days: i));
          dayLabels.add(DateFormat('EEE').format(day)); // Sun, Mon, Tue...
          dailyExpense.add(0);
        }

        // Aggregate expenses for this week
        for (var t in transactions) {
          if (t.type != 'expense') continue;
          final txDay = DateTime(t.date.year, t.date.month, t.date.day);
          if (txDay.isBefore(sunday) ||
              txDay.isAfter(sunday.add(const Duration(days: 6)))) {
            continue;
          }

          final dayIndex = txDay.difference(sunday).inDays;
          if (dayIndex >= 0 && dayIndex < 7) {
            dailyExpense[dayIndex] += t.amount;
            weekTotal += t.amount;
          }
        }

        final double maxY =
            dailyExpense.reduce((a, b) => a > b ? a : b).clamp(100, double.infinity);

        // Colors
        final barColor = isDark
            ? const Color(0xFF60A5FA)
            : const Color(0xFF3B82F6);
        final barHighlight = isDark
            ? const Color(0xFFF97316)
            : const Color(0xFFEA580C);
        final todayIndex = daysSinceSunday;

        // Card colors
        final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
        final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

        String formatAmount(double value) {
          if (value >= 100000) {
            return '${(value / 1000).toStringAsFixed(0)}K';
          }
          if (value >= 1000) {
            return '${(value / 1000).toStringAsFixed(1)}K'
                .replaceAll('.0K', 'K');
          }
          return value.toStringAsFixed(0);
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ───
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: barColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.trending_down_rounded,
                      color: barColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Spending',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          '${DateFormat('MMM d').format(sunday)} – ${DateFormat('MMM d').format(sunday.add(const Duration(days: 6)))}',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${currency.symbol}${formatAmount(weekTotal)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: barHighlight,
                        ),
                      ),
                      Text(
                        'this week',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Bar chart ───────
              SizedBox(
                height: 150,
                child: BarChart(
                  BarChartData(
                    maxY: maxY * 1.3,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 3,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: isDark
                            ? Colors.grey.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.1),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= dayLabels.length) {
                              return const SizedBox.shrink();
                            }
                            final isToday = idx == todayIndex;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                dayLabels[idx],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isToday
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isToday
                                      ? barHighlight
                                      : textSecondary,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(7, (i) {
                      final isToday = i == todayIndex;
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: dailyExpense[i] == 0 ? 0 : dailyExpense[i],
                            width: 28,
                            color: isToday ? barHighlight : barColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxY * 1.3,
                              color: isDark
                                  ? Colors.grey.withValues(alpha: 0.08)
                                  : Colors.grey.withValues(alpha: 0.06),
                            ),
                          ),
                        ],
                      );
                    }),
                    alignment: BarChartAlignment.spaceAround,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${currency.symbol}${formatAmount(rod.toY)}',
                            TextStyle(
                              color: rod.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // ── Daily average ─────
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Daily avg: ${currency.symbol}${formatAmount(weekTotal / 7)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
