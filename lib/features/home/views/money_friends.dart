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
    final viewDetailsColor = isDarkMode ? Colors.white60 : Colors.black54;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Budget Progress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E3A59),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddFriendMoneyScreen()),
                );
              },
              icon: const Icon(Icons.add, size: 16, color: Colors.blue),
              label: const Text(
                'Add',
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha:0.05),
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
                      const Row(
                        children: [
                          Text('💰', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text(
                            'Money with Friends',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E3A59),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FriendMoneyListScreen()),
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              'View Details',
                              style: TextStyle(fontSize: 12, color: viewDetailsColor),
                            ),
                            Icon(Icons.chevron_right, size: 16, color: viewDetailsColor),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 16),
                  
                  // Middle part: Amounts
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.call_made, color: Color(0xFF2A7865), size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'You will receive',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Text(
                                '${currency.symbol}${moneyFormat.format(totalLent)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E4E42),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.grey.shade200),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.call_received, color: Color(0xFFE22144), size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'You Owe',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E3A59),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Text(
                                '${currency.symbol}${moneyFormat.format(totalBorrowed)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE22144),
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
                               MaterialPageRoute(builder: (context) => const AddFriendMoneyScreen(initialType: 'Lent')),
                             );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A7865),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.call_made, color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text('I Lent', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                SizedBox(height: 2),
                                Text('Add Record', style: TextStyle(color: Colors.white70, fontSize: 11)),
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
                               MaterialPageRoute(builder: (context) => const AddFriendMoneyScreen(initialType: 'Borrowed')),
                             );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBE9EF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.call_received, color: Color(0xFFE22144), size: 16),
                                    SizedBox(width: 4),
                                    Text('I Borrowed', style: TextStyle(color: Color(0xFFE22144), fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                SizedBox(height: 2),
                                Text('Add Record', style: TextStyle(color: Color(0xFFE22144), fontSize: 11)),
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
