import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:expense_tracker/features/transactions/models/transaction_model.dart';

class DataExportService {
  /// Converts a list of transactions into a CSV-formatted string.
  String generateCsv(List<TransactionModel> transactions) {
    // Header row
    final List<List<String>> rows = [
      ['Date', 'Type', 'Category', 'Amount', 'Account', 'Note', 'Hidden'],
    ];

    // Data rows — sorted by date (newest first)
    final sorted = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final dateFormat = DateFormat('dd-MM-yyyy hh:mm a');

    for (final t in sorted) {
      String formattedDate;
      try {
        formattedDate = dateFormat.format(t.date);
      } catch (_) {
        formattedDate = t.date.toString(); // Fallback to raw toString
      }

      rows.add([
        formattedDate,
        t.type,
        t.category,
        t.amount.toStringAsFixed(2),
        t.account,
        t.note ?? '',
        t.isHidden ? 'Yes' : 'No',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);

    // Debug: print the first 5 rows to console so we can verify
    debugPrint('=== CSV EXPORT DEBUG ===');
    debugPrint('Total transactions: ${transactions.length}');
    for (int i = 0; i < rows.length && i < 6; i++) {
      debugPrint('Row $i: ${rows[i]}');
    }
    debugPrint('=== END DEBUG ===');

    return csv;
  }

  /// Generates a CSV file from transactions and opens the native share sheet.
  /// Returns true if the export was shared successfully, false otherwise.
  Future<bool> exportTransactions(List<TransactionModel> transactions) async {
    try {
      if (transactions.isEmpty) {
        return false;
      }

      // 1. Generate CSV content
      final csvString = generateCsv(transactions);

      // 2. Write to a temp file
      final tempDir = await getTemporaryDirectory();
      final dateStamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = 'SpendWise_Export_$dateStamp.csv';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(csvString);

      // 3. Open native share sheet with the file
     await SharePlus.instance.share(
  ShareParams(
    files: [XFile(file.path)],
    subject: 'SpendWise Transactions Export',
    text: 'My SpendWise transactions exported on $dateStamp',
  ),
);

      return true;
    } catch (e) {
      return false;
    }
  }
}
