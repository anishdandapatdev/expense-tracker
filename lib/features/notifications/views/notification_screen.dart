import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/notifications/models/notification_model.dart';
import 'package:expense_tracker/features/notifications/controllers/notification_controller.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen>
    with SingleTickerProviderStateMixin {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadNotifications();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    final items = await NotificationStorage.getAllNotifications();
    if (mounted) {
      setState(() {
        _notifications = items;
        _isLoading = false;
      });
      _animController.forward();
      _updateUnreadCount();
    }
  }

  void _updateUnreadCount() {
    final unread = _notifications.where((n) => !n.isRead).length;
    ref.read(unreadNotificationCountProvider.notifier).state = unread;
  }

  Future<void> _markAllAsRead() async {
    await NotificationStorage.markAllAsRead();
    await _loadNotifications();
  }

  Future<void> _deleteNotification(String id) async {
    await NotificationStorage.deleteNotification(id);
    await _loadNotifications();
  }

  Future<void> _markAsRead(String id) async {
    await NotificationStorage.markAsRead(id);
    await _loadNotifications();
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'budget_alert':
        return Icons.warning_amber_rounded;
      case 'weekly_summary':
        return Icons.bar_chart_rounded;
      case 'savings_milestone':
        return Icons.emoji_events_rounded;
      case 'reminder':
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _colorForType(String type, bool isDark) {
    switch (type) {
      case 'budget_alert':
        return isDark ? const Color(0xFFFF6B6B) : const Color(0xFFE53E3E);
      case 'weekly_summary':
        return isDark ? const Color(0xFF63B3ED) : const Color(0xFF3182CE);
      case 'savings_milestone':
        return isDark ? const Color(0xFF68D391) : const Color(0xFF38A169);
      case 'reminder':
      default:
        return isDark ? const Color(0xFFFBD38D) : const Color(0xFFD69E2E);
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'budget_alert':
        return 'Budget';
      case 'weekly_summary':
        return 'Weekly';
      case 'savings_milestone':
        return 'Savings';
      case 'reminder':
      default:
        return 'Reminder';
    }
  }

  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  String _dateGroupTitle(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(itemDate).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return 'This Week';
    return 'Earlier';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final unreadAccent = isDark ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: unreadAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: textPrimary),
              onSelected: (value) {
                if (value == 'mark_read') _markAllAsRead();
                if (value == 'clear_all') {
                  NotificationStorage.clearAll().then((_) => _loadNotifications());
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 18),
                      SizedBox(width: 8),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 18, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text('Clear all', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState(textPrimary, textSecondary)
              : _buildNotificationList(cardBg, unreadAccent, textPrimary, textSecondary, isDark),
    );
  }

  Widget _buildEmptyState(Color textPrimary, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your reminders and alerts will\nappear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(
    Color cardBg,
    Color unreadAccent,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    // Group by date
    final grouped = <String, List<NotificationItem>>{};
    for (final item in _notifications) {
      final group = _dateGroupTitle(item.timestamp);
      grouped.putIfAbsent(group, () => []).add(item);
    }

    // Maintain order: Today → Yesterday → This Week → Earlier
    final orderedKeys = <String>[];
    for (final key in ['Today', 'Yesterday', 'This Week', 'Earlier']) {
      if (grouped.containsKey(key)) orderedKeys.add(key);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: orderedKeys.length,
      itemBuilder: (context, sectionIndex) {
        final groupTitle = orderedKeys[sectionIndex];
        final items = grouped[groupTitle]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sectionIndex > 0) const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                groupTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...items.asMap().entries.map((entry) {
              final item = entry.value;
              final typeColor = _colorForType(item.type, isDark);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Dismissible(
                  key: Key(item.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteNotification(item.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      if (!item.isRead) _markAsRead(item.id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: !item.isRead
                            ? Border(
                                left: BorderSide(
                                  color: unreadAccent,
                                  width: 3,
                                ),
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Type Icon
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _iconForType(item.type),
                              size: 22,
                              color: typeColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: item.isRead
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                          color: textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: typeColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _labelForType(item.type),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: typeColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.body,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _relativeTime(item.timestamp),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textSecondary.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Unread dot
                          if (!item.isRead)
                            Padding(
                              padding: const EdgeInsets.only(left: 8, top: 4),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: unreadAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
