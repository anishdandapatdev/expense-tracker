import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/transactions/controllers/transaction_controller.dart';
import 'package:intl/intl.dart';


// A helper class to hold all our crunched data for the UI
class AnalyticsData {
  final double totalIncome;
  final double totalExpense;
  final Map<String, double> categorySpending;
  final Map<String, Map<String, double>> monthlyTrend; // {'Jan': {'income': 100, 'expense': 50}}

  AnalyticsData({
    required this.totalIncome,
    required this.totalExpense,
    required this.categorySpending,
    required this.monthlyTrend,
  });
}

// State provider for the timeframe toggle (Weekly, Monthly, Yearly)
final timeframeProvider = StateProvider<String>((ref) => 'Monthly');

// The main provider that computes the data based on transactions
final analyticsDataProvider = Provider.family<AsyncValue<AnalyticsData>, String>((ref, userId) {
  final transactionsAsync = ref.watch(transactionsStreamProvider(userId));

  return transactionsAsync.whenData((transactions) {
    double income = 0;
    double expense = 0;
    Map<String, double> catSpending = {};
    Map<String, Map<String, double>> trend = {};

    for (var t in transactions) {
      if (t.type == 'income') {
        income += t.amount;
      } else {
        expense += t.amount;
        // Group by category for the donut chart (expenses only)
        catSpending[t.category] = (catSpending[t.category] ?? 0) + t.amount;
      }

      // Group by month for the line chart (e.g., 'Oct', 'Nov')
      String month = DateFormat('MMM').format(t.date);
      trend.putIfAbsent(month, () => {'income': 0.0, 'expense': 0.0});
      
      if (t.type == 'income') {
        trend[month]!['income'] = trend[month]!['income']! + t.amount;
      } else {
        trend[month]!['expense'] = trend[month]!['expense']! + t.amount;
      }
    }

    return AnalyticsData(
      totalIncome: income,
      totalExpense: expense,
      categorySpending: catSpending,
      monthlyTrend: trend,
    );
  });
});