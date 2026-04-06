import 'package:hive/hive.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type; 
  final DateTime timestamp;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Serialize to a Map for Hive storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  /// Deserialize from a Map.
  factory NotificationItem.fromMap(Map<dynamic, dynamic> map) {
    return NotificationItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'reminder',
      timestamp: DateTime.parse(map['timestamp']),
      isRead: map['isRead'] ?? false,
    );
  }
}

/// Manages Hive-based notification history storage.
class NotificationStorage {
  static const String _boxName = 'notifications_box';

  static Future<Box> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return await Hive.openBox(_boxName);
  }

  /// Add a new notification to history.
  static Future<void> addNotification(NotificationItem item) async {
    final box = await _openBox();
    await box.put(item.id, item.toMap());
  }

  /// Get all notifications, sorted by newest first.
  static Future<List<NotificationItem>> getAllNotifications() async {
    final box = await _openBox();
    final items = box.values
        .map((e) => NotificationItem.fromMap(e as Map<dynamic, dynamic>))
        .toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  /// Get the count of unread notifications.
  static Future<int> getUnreadCount() async {
    final items = await getAllNotifications();
    return items.where((n) => !n.isRead).length;
  }

  /// Mark a single notification as read.
  static Future<void> markAsRead(String id) async {
    final box = await _openBox();
    final raw = box.get(id);
    if (raw != null) {
      final item = NotificationItem.fromMap(raw as Map<dynamic, dynamic>);
      await box.put(id, item.copyWith(isRead: true).toMap());
    }
  }

  /// Mark all notifications as read.
  static Future<void> markAllAsRead() async {
    final box = await _openBox();
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw != null) {
        final item = NotificationItem.fromMap(raw as Map<dynamic, dynamic>);
        if (!item.isRead) {
          await box.put(key, item.copyWith(isRead: true).toMap());
        }
      }
    }
  }

  /// Delete a single notification by ID.
  static Future<void> deleteNotification(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  /// Delete all notifications.
  static Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
  }
}
