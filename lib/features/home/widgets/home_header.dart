import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/settings/controllers/currency_controller.dart';
import 'package:expense_tracker/features/settings/views/currency_selection_screen.dart';
import 'package:expense_tracker/features/auth/repositories/auth_repository.dart';
import 'package:expense_tracker/features/notifications/controllers/notification_controller.dart';
import 'package:expense_tracker/features/notifications/views/notification_screen.dart';

class HeaderHomescreen extends ConsumerWidget {
  final String? email;

  const HeaderHomescreen({super.key, required this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final user = ref.watch(authStateProvider).value;
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    
    // Grab Google Display Name if available AND not empty
    String displayName = 'User';
    if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
      displayName = user.displayName!;
    } else if (email != null && email!.trim().isNotEmpty) {
      displayName = email!.split('@').first;
    }
    
    final photoUrl = user?.photoURL;
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Dynamic Colors based on theme
    final titleColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final chipBgColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50;
    final chipBorderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    final chipTextColor = isDarkMode ? Colors.white : Colors.black87;
    final notifBgColor = isDarkMode ? Colors.grey.shade800 : const Color(0xFFE2E8F0);
    final notifIconColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF0EA5E9), // Fallback blue
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null ? const Icon(Icons.person, color: Colors.white, size: 28) : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () {
                showCurrencyPickerSheet(context, ref);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: chipBorderColor),
                  borderRadius: BorderRadius.circular(8),
                  color: chipBgColor,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💰', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      currency.code,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: chipTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        // Notification Icon with unread badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor: notifBgColor,
              radius: 22,
              child: IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: notifIconColor,
                  size: 24,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  );
                },
              ),
            ),
            // Unread badge
            if (unreadCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}