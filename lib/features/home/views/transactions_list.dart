import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/utils/category_utils.dart';
import 'package:expense_tracker/features/transactions/views/add_transaction_screen.dart';

class TransactionsList extends StatefulWidget {
  final List<dynamic> transactions;
  final String currencySymbol;

  const TransactionsList({
    super.key,
    required this.transactions,
    required this.currencySymbol,
  });

  @override
  State<TransactionsList> createState() => _TransactionsListState();
}

class _TransactionsListState extends State<TransactionsList> {
  String _searchQuery = '';
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper to filter transactions based on the search query
  List<dynamic> get _filteredTransactions {
    if (_searchQuery.isEmpty) return widget.transactions;
    
    return widget.transactions.where((t) {
      final categoryMatch = t.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final noteMatch = t.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      return categoryMatch || noteMatch;
    }).toList();
  }

  // Helper for subtitle date (e.g., "Today", "Yesterday")
  String _getRelativeDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) return 'Today';
    if (dateToCheck == yesterday) return 'Yesterday';
    return DateFormat('MMM dd').format(date);
  }

  // Helper for trailing time/date (e.g., "7.35 pm", "Yesterday")
  String _getTrailingTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return DateFormat('h.mm a').format(date).toLowerCase(); // e.g., 7.35 pm
    }
    if (dateToCheck == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return DateFormat('MMM dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final moneyFormat = NumberFormat('#,##0.00', 'en_US');
    final displayTransactions = _filteredTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3246), // Dark slate color from screenshot
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'See all',
                    style: TextStyle(color: Color(0xFF5A6BB0)), // Muted blue
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 224, 227, 236), // Light grey search background
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search transactions',
                  hintStyle: TextStyle(color: Colors.black54, fontSize: 15),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                ),
              ),
            ),
          ),

          // Transactions List Container
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: displayTransactions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text('No transactions found.'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 10, bottom: 20), // Added bottom padding
                    itemCount: displayTransactions.length,
                    itemBuilder: (context, index) {
                      final t = displayTransactions[index];
                      final isIncome = t.type == 'income';
                        final catColor = CategoryUtils.getColor(t.category);

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddTransactionScreen(existingTransaction: t),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                // Leading Icon
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    CategoryUtils.getIcon(t.category),
                                    color: catColor,
                                  ),
                                ),
                                const SizedBox(width: 13),
                                
                                // Title and Subtitle
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.category,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF2C3246),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        t.note ?? _getRelativeDay(t.date),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Trailing Amount and Time
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isIncome ? '+' : '-'}${widget.currencySymbol}${moneyFormat.format(t.amount)}',
                                      style: TextStyle(
                                        color: isIncome 
                                            ? Colors.green 
                                            : const Color(0xFFE55B60), // Reddish pink from screenshot
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getTrailingTime(t.date),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                    }
            ),
        )
        ]
      );
    
  }
}