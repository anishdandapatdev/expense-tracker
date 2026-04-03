import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/core/utils/category_utils.dart';
import 'package:expense_tracker/features/transactions/views/add_transaction_screen.dart';
import 'package:expense_tracker/features/transactions/controllers/transaction_controller.dart';
import 'package:expense_tracker/features/transactions/views/full_transactions_screen.dart';

class TransactionsList extends ConsumerStatefulWidget {
  final List<dynamic> transactions;
  final String currencySymbol;
  final bool isPreview;

  const TransactionsList({
    super.key,
    required this.transactions,
    required this.currencySymbol,
    this.isPreview = false,
  });

  @override
  ConsumerState<TransactionsList> createState() => _TransactionsListState();
}

class _TransactionsListState extends ConsumerState<TransactionsList> {
  String _searchQuery = '';
  String? _selectedCategoryFilter;
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
    var filtered = widget.transactions;

    if (_selectedCategoryFilter != null) {
      filtered = filtered.where((t) => t.category == _selectedCategoryFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) {
        final categoryMatch = t.category.toLowerCase().contains(_searchQuery.toLowerCase());
        final noteMatch = t.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
        return categoryMatch || noteMatch;
      }).toList();
    }
    
    return filtered;
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
    var displayTransactions = _filteredTransactions;
    if (widget.isPreview && displayTransactions.length > 5) {
      displayTransactions = displayTransactions.sublist(0, 5);
    }
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Dynamic Colors based on theme
    final titleColor = isDarkMode ? Colors.white : const Color(0xFF2C3246);
    final seeAllColor = isDarkMode ? Colors.blueAccent : const Color(0xFF5A6BB0);
    final searchBgColor = isDarkMode ? Colors.grey.shade800 : const Color.fromARGB(255, 224, 227, 236);
    final searchHintColor = isDarkMode ? Colors.white54 : Colors.black54;
    final cardBgColor = isDarkMode ? Theme.of(context).cardColor : Colors.white;
    final incomeColor = isDarkMode ? Colors.greenAccent : Colors.green;
    final expenseColor = isDarkMode ? Colors.redAccent : const Color(0xFFE55B60);
    final subTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        if (widget.isPreview)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FullTransactionsScreen()),
                    );
                  },
                  child: Text(
                    'See all',
                    style: TextStyle(color: seeAllColor),
                  ),
                ),
              ],
            ),
          )
        else
          const SizedBox(height: 8),

        // Search Bar (Only when NOT in preview)
        if (!widget.isPreview)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: searchBgColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Search transactions',
                        hintStyle: TextStyle(color: searchHintColor, fontSize: 15),
                        prefixIcon: Icon(Icons.search, color: searchHintColor),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Filter Dropdown Button
                Container(
                  decoration: BoxDecoration(
                    color: _selectedCategoryFilter != null ? seeAllColor.withValues(alpha: 0.2) : searchBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: PopupMenuButton<String?>(
                    tooltip: 'Filter by Category',
                    icon: Icon(
                      Icons.filter_list,
                      color: _selectedCategoryFilter != null ? seeAllColor : (isDarkMode ? Colors.white70 : Colors.black87),
                    ),
                    onSelected: (value) {
                      setState(() {
                        _selectedCategoryFilter = (value == 'All') ? null : value;
                      });
                    },
                    itemBuilder: (context) {
                      final uniqueCategories = widget.transactions.map((t) => t.category as String).toSet().toList();
                      uniqueCategories.sort();

                      return [
                        const PopupMenuItem<String?>(
                          value: 'All',
                          child: Text('All Categories'),
                        ),
                        const PopupMenuDivider(),
                        ...uniqueCategories.map((c) => PopupMenuItem<String?>(
                              value: c,
                              child: Text(c),
                            )),
                      ];
                    },
                  ),
                ),
              ],
            ),
          ),

          // Transactions List Container
          Container(
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: displayTransactions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text('No transactions found.', style: TextStyle(color: subTextColor)),
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

                        return Dismissible(
                          key: Key(t.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.redAccent,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: cardBgColor,
                                  title: Text("Delete History", style: TextStyle(color: titleColor)),
                                  content: Text("Are you sure you want to remove this transaction from your history? Your total balance will not be affected.", style: TextStyle(color: subTextColor)),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text("OK", style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          onDismissed: (direction) {
                            ref.read(transactionControllerProvider).hideTransactionHistory(t);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Transaction removed from history')),
                            );
                          },
                          child: InkWell(
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
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: titleColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          t.note ?? _getRelativeDay(t.date),
                                          style: TextStyle(
                                            color: subTextColor,
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
                                          color: isIncome ? incomeColor : expenseColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getTrailingTime(t.date),
                                        style: TextStyle(
                                          color: subTextColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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