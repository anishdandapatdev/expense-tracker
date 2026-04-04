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

// A helper class to hold all our crunched data for the UI
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
    int daysSinceSunday = now.weekday == 7 ? 0 : now.weekday;
    DateTime thisWeekSunday = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysSinceSunday));
    DateTime nextWeekSunday = thisWeekSunday.add(const Duration(days: 7));
    DateTime lastWeekSunday = thisWeekSunday.subtract(const Duration(days: 7));

    DateTime startDate;

    if (timeframe == 'Weekly') {
      startDate = now.subtract(const Duration(days: 6)); // Last 7 days including today
    } else if (timeframe == 'Monthly') {
      startDate = now.subtract(const Duration(days: 29)); // Last 30 days including today
    } else { 
      startDate = DateTime(now.year, now.month - 11, 1); // Last 12 months
    }
    
    // Create zero-filled map for the timeline
    Map<String, Map<String, double>> trend = {};
    
    if (timeframe == 'Weekly') {
      for (int i = 6; i >= 0; i--) {
        DateTime d = now.subtract(Duration(days: i));
        String key = DateFormat('EEE').format(d); // e.g. Mon, Tue
        trend[key] = {'income': 0.0, 'expense': 0.0};
      }
    } else if (timeframe == 'Monthly') {
      for (int i = 29; i >= 0; i--) {
        DateTime d = now.subtract(Duration(days: i));
        String key = DateFormat('MMM dd').format(d); // e.g. Apr 05
        trend[key] = {'income': 0.0, 'expense': 0.0};
      }
    } else {
      for (int i = 11; i >= 0; i--) {
        DateTime d = DateTime(now.year, now.month - i, 1);
        String key = DateFormat('MMM-yyyy').format(d); // e.g. Apr-2026
        trend[key] = {'income': 0.0, 'expense': 0.0};
      }
    }

    // Now process transactions
    for (var t in transactions) {
  // Comparison logic
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

  if (t.type == 'income') {
        income += t.amount;
      } else {
        expense += t.amount;
        catSpending[t.category] = (catSpending[t.category] ?? 0) + t.amount;
      }

      // Group into trend
      String key;
      if (timeframe == 'Weekly') {
        key = DateFormat('EEE').format(t.date);
      } else if (timeframe == 'Monthly') {
        key = DateFormat('MMM dd').format(t.date);
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