import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Riverpod provider for the notification service singleton
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Notification IDs
  static const int _dailyReminderId = 1001;
  static const int _weeklySummaryId = 1002;
  static const int _budgetAlertBaseId = 2000;
  static const int _savingsGoalBaseId = 3000;

  /// Initialize the notification plugin and timezone data.
  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    // FIX: The required named parameter is 'settings'
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create the notification channel for Android 8+
    const channel = AndroidNotificationChannel(
      'spendwise_channel',
      'SpendWise Notifications',
      description: 'Expense tracker reminders and alerts',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Can be extended to navigate to specific screens based on payload
  }

  /// Request notification permission (Android 13+)
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  // ─── Daily Reminder ─────────────────────────────────────────────

  /// Schedule a repeating daily notification at the given [time].
  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await cancelDailyReminder();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If the time has already passed today, push to tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _dailyReminderId,
      title: '💰 Log Your Expenses',
      body: "Don't forget to record today's spending!",
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'spendwise_channel',
          'SpendWise Notifications',
          channelDescription: 'Expense tracker reminders and alerts',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );
  }

  /// Cancel the daily reminder.
  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(id: _dailyReminderId);
  }

  // ─── Weekly Summary ─────────────────────────────────────────────

  /// Schedule a weekly summary notification every Sunday at 7 PM.
  Future<void> scheduleWeeklySummary() async {
    await cancelWeeklySummary();

    final now = tz.TZDateTime.now(tz.local);

    // Find the next Sunday
    var nextSunday = now;
    while (nextSunday.weekday != DateTime.sunday) {
      nextSunday = nextSunday.add(const Duration(days: 1));
    }
    var scheduledDate = tz.TZDateTime(
      tz.local,
      nextSunday.year,
      nextSunday.month,
      nextSunday.day,
      19, // 7 PM
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    await _plugin.zonedSchedule(
      id: _weeklySummaryId,
      title: '📊 Weekly Spending Summary',
      body: "Tap to review your week's income & expenses.",
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'spendwise_channel',
          'SpendWise Notifications',
          channelDescription: 'Expense tracker reminders and alerts',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_summary',
    );
  }

  /// Cancel the weekly summary.
  Future<void> cancelWeeklySummary() async {
    await _plugin.cancel(id: _weeklySummaryId);
  }

  // ─── Budget Alert ───────────────────────────────────────────────

  /// Show an immediate notification for a budget threshold breach.
  Future<void> showBudgetAlert({
    required String category,
    required int percentUsed,
  }) async {
    final notificationId = _budgetAlertBaseId + category.hashCode.abs() % 999;
    
    await _plugin.show(
      id: notificationId,
      title: '⚠️ Budget Alert: $category',
      body: 'You\'ve used $percentUsed% of your $category budget. Slow down!',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'spendwise_channel',
          'SpendWise Notifications',
          channelDescription: 'Expense tracker reminders and alerts',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: 'budget_alert_$category',
    );
  }

  // ─── Savings Goal Milestone ─────────────────────────────────────

  /// Show an immediate notification for reaching a savings goal milestone.
  Future<void> showSavingsGoalMilestone({
    required String goalName,
    required int milestonePercent,
  }) async {
    final notificationId = _savingsGoalBaseId + goalName.hashCode.abs() % 999;

    String emoji;
    switch (milestonePercent) {
      case 25:
        emoji = '🌱';
        break;
      case 50:
        emoji = '🔥';
        break;
      case 75:
        emoji = '🚀';
        break;
      case 100:
        emoji = '🎉';
        break;
      default:
        emoji = '✨';
    }

    await _plugin.show(
      id: notificationId,
      title: '$emoji Savings Milestone!',
      body: 'You\'ve reached $milestonePercent% of your "$goalName" goal!',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'spendwise_channel',
          'SpendWise Notifications',
          channelDescription: 'Expense tracker reminders and alerts',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: 'savings_milestone_$goalName',
    );
  }

  // ─── General ────────────────────────────────────────────────────

  /// Show a general-purpose instant notification.
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'spendwise_channel',
          'SpendWise Notifications',
          channelDescription: 'Expense tracker reminders and alerts',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}