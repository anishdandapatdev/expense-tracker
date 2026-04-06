import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/transactions/controllers/transaction_controller.dart';
import 'package:intl/intl.dart';


class WeeklyComparison {
  final double thisWeekIncome;
  final double thisWeekExpense;
  final double lastWeekIncome;
  final double lastWeekExpense;

  WeeklyComparison({
    required this.thisWeekIncome,
    required this.thisWeekExpense,
    required this.lastWeekIncome,
    required this.lastWeekExpense,
  });
}

// hold all our crunched data for the UI
class AnalyticsData {
  final double totalIncome;
  final double totalExpense;
  final Map<String, double> categorySpending;
  final Map<String, Map<String, double>> monthlyTrend; 
  final WeeklyComparison weeklyComparison;

  AnalyticsData({
    required this.totalIncome,
    required this.totalExpense,
    required this.categorySpending,
    required this.monthlyTrend,
    required this.weeklyComparison,
  });
}

// State provider for the timeframe toggle (Weekly, Monthly, Yearly)
final timeframeProvider = StateProvider<String>((ref) => 'Monthly');

// The main provider that computes the data based on transactions
final analyticsDataProvider = Provider.family<AsyncValue<AnalyticsData>, String>((ref, userId) {
  final transactionsAsync = ref.watch(transactionsStreamProvider(userId));
  final timeframe = ref.watch(timeframeProvider); // 'Weekly', 'Monthly', 'Yearly'

  return transactionsAsync.whenData((transactions) {
    double income = 0;
    double expense = 0;
    Map<String, double> catSpending = {};
    
    // Strict weekly boundaries for the "This vs Last" comparison
    double thisWeekInc = 0;
    double thisWeekExp = 0;
    double lastWeekInc = 0;
    double lastWeekExp = 0;

    DateTime now = DateTime.now();

    // Week starts on Sunday
    int daysSinceSunday = now.weekday == 7 ? 0 : now.weekday;
    DateTime thisWeekSunday = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysSinceSunday));
    DateTime nextWeekSunday = thisWeekSunday.add(const Duration(days: 7));
    DateTime lastWeekSunday = thisWeekSunday.subtract(const Duration(days: 7));

    DateTime startDate;

    if (timeframe == 'Weekly') {
      // Week: Sunday to Saturday (7 days starting from this week's Sunday)
      startDate = thisWeekSunday;
    } else if (timeframe == 'Monthly') {
      // Month: 1st to last day of current month
      startDate = DateTime(now.year, now.month, 1);
    } else { 
      // Yearly: Jan 1 to Dec 31 of current year
      startDate = DateTime(now.year, 1, 1);
    }
    
    // zero-filled map for the timeline
    Map<String, Map<String, double>> trend = {};
    
    if (timeframe == 'Weekly') {
      // Sunday to Saturday (7 days)
      for (int i = 0; i < 7; i++) {
        DateTime d = thisWeekSunday.add(Duration(days: i));
        String key = DateFormat('MMM d').format(d); // e.g. "Mar 30", "Apr 1"
        trend[key] = {'income': 0.0, 'expense': 0.0};
      }
    } else if (timeframe == 'Monthly') {
      // Day 1 to last day of current month
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      for (int i = 1; i <= lastDay; i++) {
        DateTime d = DateTime(now.year, now.month, i);
        String key = DateFormat('MMM d').format(d); // e.g. "Apr 1", "Apr 2"
        trend[key] = {'income': 0.0, 'expense': 0.0};
      }
    } else {
      // Jan to Dec of current year
      for (int m = 1; m <= 12; m++) {
        DateTime d = DateTime(now.year, m, 1);
        String key = DateFormat('MMM-yyyy').format(d); // e.g. "Jan-2026"
        trend[key] = {'income': 0.0, 'expense': 0.0};
      }
    }

    // Now process transactions
    for (var t in transactions) {
      // Comparison logic (This Week vs Last Week)
      if (t.date.compareTo(lastWeekSunday) >= 0 &&
          t.date.compareTo(thisWeekSunday) < 0) {
        if (t.type == 'income') {
          lastWeekInc += t.amount;
        } else {
          lastWeekExp += t.amount;
        }
      } else if (t.date.compareTo(thisWeekSunday) >= 0 &&
          t.date.compareTo(nextWeekSunday) < 0) {
        if (t.type == 'income') {
          thisWeekInc += t.amount;
        } else {
          thisWeekExp += t.amount;
        }
      }

      if (t.date.isBefore(startDate)) {
        continue;
      }

      // For yearly, also skip if past this year
      if (timeframe == 'Yearly' && t.date.year != now.year) {
        continue;
      }
      // For monthly, skip if not current month
      if (timeframe == 'Monthly' && (t.date.month != now.month || t.date.year != now.year)) {
        continue;
      }
      // For weekly, skip if past this Saturday
      if (timeframe == 'Weekly' && t.date.isAfter(thisWeekSunday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59)))) {
        continue;
      }

      if (t.type == 'income') {
        income += t.amount;
      } else {
        expense += t.amount;
        catSpending[t.category] = (catSpending[t.category] ?? 0) + t.amount;
      }

      // Group into trend
      String key;
      if (timeframe == 'Weekly') {
        key = DateFormat('MMM d').format(t.date);
      } else if (timeframe == 'Monthly') {
        key = DateFormat('MMM d').format(t.date);
      } else {
        key = DateFormat('MMM-yyyy').format(t.date);
      }
      
      if (trend.containsKey(key)) {
        if (t.type == 'income') {
          trend[key]!['income'] = trend[key]!['income']! + t.amount;
        } else {
          trend[key]!['expense'] = trend[key]!['expense']! + t.amount;
        }
      }
    }

    return AnalyticsData(
      totalIncome: income,
      totalExpense: expense,
      categorySpending: catSpending,
      monthlyTrend: trend,
      weeklyComparison: WeeklyComparison(
        thisWeekIncome: thisWeekInc,
        thisWeekExpense: thisWeekExp,
        lastWeekIncome: lastWeekInc,
        lastWeekExpense: lastWeekExp,
      ),
    );
  });
});