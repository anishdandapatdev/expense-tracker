import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/features/auth/repositories/auth_repository.dart';
import 'package:expense_tracker/features/settings/controllers/currency_controller.dart';
import 'package:expense_tracker/features/friends_money/controllers/friend_money_controller.dart';
import 'package:expense_tracker/features/friends_money/views/add_friend_money_screen.dart';
import 'package:expense_tracker/features/friends_money/views/friend_money_list_screen.dart';

class MoneyFriendsSection extends ConsumerWidget {
  const MoneyFriendsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final currency = ref.watch(currencyProvider);
    final moneyFormat = NumberFormat('#,##0.00', 'en_US');

    // Fetch friend money stream safely
    final friendMoneyAsyncValue = ref.watch(
      friendMoneyStreamProvider(user?.uid ?? ''),
    );
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Dynamic Colors based on theme
    final viewDetailsColor = isDarkMode ? Colors.white60 : Colors.black54;
    final titleColor = isDarkMode ? Colors.white : const Color(0xFF2E3A59);
    final cardBgColor = isDarkMode ? Theme.of(context).cardColor : Colors.white;
    final borderColor = isDarkMode
        ? Colors.grey.shade800
        : Colors.grey.shade100;
    final shadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.grey.withValues(alpha: 0.05);
    final dividerColor = isDarkMode
        ? Colors.grey.shade800
        : const Color(0xFFF0F0F0);
    final separatorColor = isDarkMode
        ? Colors.grey.shade800
        : Colors.grey.shade200;
    final incomeColor = isDarkMode
        ? Colors.greenAccent
        : const Color(0xFF1E4E42);
    final expenseColor = isDarkMode
        ? Colors.redAccent
        : const Color(0xFFE22144);
    final iconIncomeColor = isDarkMode
        ? Colors.greenAccent
        : const Color(0xFF2A7865);
    final subTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Shared with Friends',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddFriendMoneyScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 16, color: Colors.blue),
              label: const Text(
                'Add',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: friendMoneyAsyncValue.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (records) {
              double totalLent = 0; // they owe you -> You will receive
              double totalBorrowed = 0; // you owe them -> You Owe
              for (var r in records) {
                if (!r.isSettled) {
                  if (r.type == 'lent') {
                    totalLent += r.amount;
                  } else {
                    totalBorrowed += r.amount;
                  }
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top part: Icon, Title, View details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('💰', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            'Money with Friends',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const FriendMoneyListScreen(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              'View Details',
                              style: TextStyle(
                                fontSize: 12,
                                color: viewDetailsColor,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: viewDetailsColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: dividerColor),
                  const SizedBox(height: 16),

                  // Middle part: Amounts
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.call_made,
                                  color: iconIncomeColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'You will receive',
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Text(
                                '${currency.symbol}${moneyFormat.format(totalLent)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: incomeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 40, color: separatorColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.call_received,
                                  color: expenseColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'You Owe',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: titleColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Text(
                                '${currency.symbol}${moneyFormat.format(totalBorrowed)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: expenseColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bottom part: Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AddFriendMoneyScreen(
                                      initialType: 'Lent',
                                    ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF059669),
                                  Color(0xFF059669),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF0CAF88).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.north_east_rounded,
                                      color: Color(0xFFB2F5E4),
                                      size: 15,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'I Lent',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 1),
                                Text(
                                  'Add Record',
                                  style: TextStyle(
                                    color: Color(0xFFD1FAF0),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AddFriendMoneyScreen(
                                      initialType: 'Borrowed',
                                    ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF6366F1),
                                  Color(0xFF6366F1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF6366F1).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.south_west_rounded,
                                      color: Color(0xFFC7D2FE),
                                      size: 15,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'I Borrowed',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 1),
                                Text(
                                  'Add Record',
                                  style: TextStyle(
                                    color: Color(0xFFE0E7FF),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
