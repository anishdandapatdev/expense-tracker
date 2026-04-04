import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/features/auth/controllers/auth_controller.dart';
import 'package:expense_tracker/features/auth/repositories/auth_repository.dart';
import 'package:expense_tracker/features/settings/controllers/currency_controller.dart';
import 'package:expense_tracker/features/settings/controllers/theme_controller.dart';
import 'package:expense_tracker/features/settings/controllers/app_lock_controller.dart';
import 'package:expense_tracker/features/settings/services/local_auth_service.dart';
import 'package:expense_tracker/features/settings/services/data_export_service.dart';
import 'package:expense_tracker/features/transactions/controllers/transaction_controller.dart';
import 'package:expense_tracker/features/notifications/controllers/notification_controller.dart';
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {

  Future<void> _showEditNameDialog(
    BuildContext context,
    String currentName,
  ) async {
    final textController = TextEditingController(text: currentName);
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Name'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(hintText: 'Enter your name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newName = textController.text.trim();
                if (newName.isNotEmpty) {
                  try {
                    await FirebaseAuth.instance.currentUser?.updateDisplayName(
                      newName,
                    );
                    await FirebaseAuth.instance.currentUser?.reload();
                    // Invalidate the authStateProvider so the UI updates
                    ref.invalidate(authStateProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update name: $e')),
                      );
                    }
                  }
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleExport(BuildContext context) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Fetch all transactions (the stream provider gives us the current list)
      final transactionsAsync = ref.read(transactionsStreamProvider(user.uid));
      final transactions = transactionsAsync.valueOrNull ?? [];

      if (context.mounted) Navigator.pop(context); // Dismiss loading

      if (transactions.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No transactions to export.')),
          );
        }
        return;
      }

      // Export via share sheet
      final exportService = DataExportService();
      final success = await exportService.exportTransactions(transactions);

      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export failed. Please try again.')),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Dismiss loading on error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers
    final user = ref.watch(authStateProvider).value;
    final currency = ref.watch(currencyProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Determine if dark mode is active
    final isDarkMode =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    String displayName = 'User';
    if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
      displayName = user.displayName!;
    } else if (user?.email != null && user!.email!.trim().isNotEmpty) {
      displayName = user.email!.split('@').first;
    }

    final photoUrl = user?.photoURL;
    final cardBgColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // Profile Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDarkMode
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF0EA5E9),
                      backgroundImage: photoUrl != null
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 30,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'Unknown User',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_note, size: 28),
                      onPressed: () =>
                          _showEditNameDialog(context, displayName),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Notifications Section
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildNotificationsCard(cardBgColor, isDarkMode),
              const SizedBox(height: 24),

              // Preferences Section
              const Text(
                'Preferences',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDarkMode
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.currency_exchange, size: 22),
                      title: const Text(
                        'Currency',
                        style: TextStyle(fontSize: 15),
                      ),
                      subtitle: Text(
                        '${currency.name} (${currency.symbol})',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: () => context.push('/currency-setup'),
                    ),
                    const Divider(height: 1, indent: 50, endIndent: 20),
                    ListTile(
                      leading: const Icon(Icons.dark_mode_outlined, size: 22),
                      title: const Text(
                        'Dark Mode',
                        style: TextStyle(fontSize: 15),
                      ),
                      trailing: Switch(
                        value: isDarkMode,
                        activeThumbColor: const Color(0xFF0EA5E9),
                        onChanged: (value) {
                          ref
                              .read(themeModeProvider.notifier)
                              .toggleTheme(value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Security Section
              const Text(
                'Security',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDarkMode
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: ListTile(
                  leading: const Icon(Icons.lock_outline, size: 22),
                  title: const Text(
                    'App Lock',
                    style: TextStyle(fontSize: 15),
                  ),
                  trailing: Switch(
                    value: ref.watch(appLockProvider),
                    activeThumbColor: const Color(0xFF0EA5E9),
                    onChanged: (value) async {
                      final authService = ref.read(localAuthServiceProvider);
                      
                      // Require authentication before changing the setting
                      final authenticated = await authService.authenticate();
                      
                      if (authenticated) {
                         await ref.read(appLockProvider.notifier).toggleLock(value);
                      } else {
                         if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Authentication required to change App Lock setting.')),
                           );
                         }
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // More Options Section
              const Text(
                'More Options',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDarkMode
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.download_rounded,
                        color: Colors.green,
                        size: 22,
                      ),
                      title: const Text(
                        'Export Data',
                        style: TextStyle(fontSize: 15),
                      ),
                      subtitle: const Text(
                        'Download as CSV',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () => _handleExport(context),
                    ),
                    const Divider(height: 1, indent: 50, endIndent: 20),
                    ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: Colors.redAccent,
                        size: 22,
                      ),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.redAccent, fontSize: 15),
                      ),
                      onTap: () async {
                        await ref.read(authControllerProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 48,
              ), // Padding at the bottom for scrolling gracefully
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsCard(Color cardBgColor, bool isDarkMode) {
    final notifSettings = ref.watch(notificationSettingsProvider);
    final notifController = ref.read(notificationSettingsProvider.notifier);

    final isEnabled = notifSettings.notificationsEnabled;
    final timeLabel =
        '${notifSettings.reminderTime.hourOfPeriod == 0 ? 12 : notifSettings.reminderTime.hourOfPeriod}:${notifSettings.reminderTime.minute.toString().padLeft(2, '0')} ${notifSettings.reminderTime.period == DayPeriod.am ? 'AM' : 'PM'}';

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          // Master Toggle
          ListTile(
            leading: const Icon(Icons.notifications_none, size: 22),
            title: const Text(
              'Notifications',
              style: TextStyle(fontSize: 15),
            ),
            trailing: Switch(
              value: isEnabled,
              activeThumbColor: const Color(0xFF0EA5E9),
              onChanged: (value) {
                notifController.toggleNotifications(value);
              },
            ),
          ),

          // Sub-settings (only visible when master toggle is on)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState:
                isEnabled ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            secondChild: const SizedBox.shrink(),
            firstChild: Column(
              children: [
                const Divider(height: 1, indent: 50, endIndent: 20),
                // Daily Reminder toggle
                ListTile(
                  leading: const Icon(Icons.alarm, size: 22),
                  title: const Text(
                    'Daily Reminder',
                    style: TextStyle(fontSize: 15),
                  ),
                  subtitle: notifSettings.dailyReminderEnabled
                      ? GestureDetector(
                          onTap: () => _showTimePickerDialog(
                            notifSettings.reminderTime,
                            notifController,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                timeLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF0EA5E9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.edit,
                                size: 13,
                                color: Color(0xFF0EA5E9),
                              ),
                            ],
                          ),
                        )
                      : null,
                  trailing: Switch(
                    value: notifSettings.dailyReminderEnabled,
                    activeThumbColor: const Color(0xFF0EA5E9),
                    onChanged: (value) {
                      notifController.toggleDailyReminder(value);
                    },
                  ),
                ),
                const Divider(height: 1, indent: 50, endIndent: 20),
                // Budget Alerts toggle
                ListTile(
                  leading: const Icon(Icons.warning_amber_rounded, size: 22),
                  title: const Text(
                    'Budget Alerts',
                    style: TextStyle(fontSize: 15),
                  ),
                  subtitle: const Text(
                    'Alert at 80% of budget',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: Switch(
                    value: notifSettings.budgetAlertsEnabled,
                    activeThumbColor: const Color(0xFF0EA5E9),
                    onChanged: (value) {
                      notifController.toggleBudgetAlerts(value);
                    },
                  ),
                ),
                const Divider(height: 1, indent: 50, endIndent: 20),
                // Weekly Summary toggle
                ListTile(
                  leading: const Icon(Icons.bar_chart_rounded, size: 22),
                  title: const Text(
                    'Weekly Summary',
                    style: TextStyle(fontSize: 15),
                  ),
                  subtitle: const Text(
                    'Every Sunday at 7 PM',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: Switch(
                    value: notifSettings.weeklySummaryEnabled,
                    activeThumbColor: const Color(0xFF0EA5E9),
                    onChanged: (value) {
                      notifController.toggleWeeklySummary(value);
                    },
                  ),
                ),
                const Divider(height: 1, indent: 50, endIndent: 20),
                // Savings Goal Milestones toggle
                ListTile(
                  leading: const Icon(Icons.emoji_events_rounded, size: 22),
                  title: const Text(
                    'Savings Milestones',
                    style: TextStyle(fontSize: 15),
                  ),
                  subtitle: const Text(
                    'At 25%, 50%, 75%, 100%',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: Switch(
                    value: notifSettings.savingsGoalAlertsEnabled,
                    activeThumbColor: const Color(0xFF0EA5E9),
                    onChanged: (value) {
                      notifController.toggleSavingsGoalAlerts(value);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTimePickerDialog(
    TimeOfDay currentTime,
    NotificationController controller,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF0EA5E9),
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.setReminderTime(picked);
    }
  }
}
