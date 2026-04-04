import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/features/notifications/services/notification_service.dart';
import 'package:expense_tracker/features/notifications/models/notification_model.dart';

// ─── Notification Settings State ──────────────────────────────────

class NotificationSettings {
  final bool notificationsEnabled;
  final bool dailyReminderEnabled;
  final TimeOfDay reminderTime;
  final bool budgetAlertsEnabled;
  final bool weeklySummaryEnabled;
  final bool savingsGoalAlertsEnabled;

  const NotificationSettings({
    this.notificationsEnabled = true,
    this.dailyReminderEnabled = true,
    this.reminderTime = const TimeOfDay(hour: 20, minute: 0),
    this.budgetAlertsEnabled = true,
    this.weeklySummaryEnabled = true,
    this.savingsGoalAlertsEnabled = true,
  });

  NotificationSettings copyWith({
    bool? notificationsEnabled,
    bool? dailyReminderEnabled,
    TimeOfDay? reminderTime,
    bool? budgetAlertsEnabled,
    bool? weeklySummaryEnabled,
    bool? savingsGoalAlertsEnabled,
  }) {
    return NotificationSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
      savingsGoalAlertsEnabled:
          savingsGoalAlertsEnabled ?? this.savingsGoalAlertsEnabled,
    );
  }
}

// ─── Riverpod Provider ────────────────────────────────────────────

final notificationSettingsProvider =
    StateNotifierProvider<NotificationController, NotificationSettings>((ref) {
  final service = ref.read(notificationServiceProvider);
  return NotificationController(service);
});

/// Provides the live unread notification count.
final unreadNotificationCountProvider = StateProvider<int>((ref) => 0);

// ─── Controller ───────────────────────────────────────────────────

class NotificationController extends StateNotifier<NotificationSettings> {
  final NotificationService _service;

  // SharedPreferences keys
  static const _keyEnabled = 'notif_enabled';
  static const _keyDailyReminder = 'notif_daily_reminder';
  static const _keyReminderHour = 'notif_reminder_hour';
  static const _keyReminderMinute = 'notif_reminder_minute';
  static const _keyBudgetAlerts = 'notif_budget_alerts';
  static const _keyWeeklySummary = 'notif_weekly_summary';
  static const _keySavingsGoal = 'notif_savings_goal';

  NotificationController(this._service)
      : super(const NotificationSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationSettings(
      notificationsEnabled: prefs.getBool(_keyEnabled) ?? true,
      dailyReminderEnabled: prefs.getBool(_keyDailyReminder) ?? true,
      reminderTime: TimeOfDay(
        hour: prefs.getInt(_keyReminderHour) ?? 20,
        minute: prefs.getInt(_keyReminderMinute) ?? 0,
      ),
      budgetAlertsEnabled: prefs.getBool(_keyBudgetAlerts) ?? true,
      weeklySummaryEnabled: prefs.getBool(_keyWeeklySummary) ?? true,
      savingsGoalAlertsEnabled: prefs.getBool(_keySavingsGoal) ?? true,
    );

    // Apply saved schedules if enabled
    if (state.notificationsEnabled) {
      if (state.dailyReminderEnabled) {
        await _service.scheduleDailyReminder(state.reminderTime);
      }
      if (state.weeklySummaryEnabled) {
        await _service.scheduleWeeklySummary();
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, state.notificationsEnabled);
    await prefs.setBool(_keyDailyReminder, state.dailyReminderEnabled);
    await prefs.setInt(_keyReminderHour, state.reminderTime.hour);
    await prefs.setInt(_keyReminderMinute, state.reminderTime.minute);
    await prefs.setBool(_keyBudgetAlerts, state.budgetAlertsEnabled);
    await prefs.setBool(_keyWeeklySummary, state.weeklySummaryEnabled);
    await prefs.setBool(_keySavingsGoal, state.savingsGoalAlertsEnabled);
  }

  /// Master toggle — enables/disables all notifications.
  Future<void> toggleNotifications(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _save();

    if (!enabled) {
      await _service.cancelAll();
    } else {
      // Re-schedule active notifications
      if (state.dailyReminderEnabled) {
        await _service.scheduleDailyReminder(state.reminderTime);
      }
      if (state.weeklySummaryEnabled) {
        await _service.scheduleWeeklySummary();
      }
    }
  }

  /// Toggle the daily reminder.
  Future<void> toggleDailyReminder(bool enabled) async {
    state = state.copyWith(dailyReminderEnabled: enabled);
    await _save();

    if (enabled && state.notificationsEnabled) {
      await _service.scheduleDailyReminder(state.reminderTime);
    } else {
      await _service.cancelDailyReminder();
    }
  }

  /// Update the daily reminder time.
  Future<void> setReminderTime(TimeOfDay time) async {
    state = state.copyWith(reminderTime: time);
    await _save();

    if (state.dailyReminderEnabled && state.notificationsEnabled) {
      await _service.scheduleDailyReminder(time);
    }
  }

  /// Toggle budget alerts.
  Future<void> toggleBudgetAlerts(bool enabled) async {
    state = state.copyWith(budgetAlertsEnabled: enabled);
    await _save();
  }

  /// Toggle weekly summary.
  Future<void> toggleWeeklySummary(bool enabled) async {
    state = state.copyWith(weeklySummaryEnabled: enabled);
    await _save();

    if (enabled && state.notificationsEnabled) {
      await _service.scheduleWeeklySummary();
    } else {
      await _service.cancelWeeklySummary();
    }
  }

  /// Toggle savings goal milestones.
  Future<void> toggleSavingsGoalAlerts(bool enabled) async {
    state = state.copyWith(savingsGoalAlertsEnabled: enabled);
    await _save();
  }

  // ─── Helpers for triggering event-based notifications ───────────

  /// Check budget usage and fire alert if needed.
  Future<void> checkBudgetAndNotify({
    required String category,
    required double spent,
    required double limit,
  }) async {
    if (!state.notificationsEnabled || !state.budgetAlertsEnabled) return;
    if (limit <= 0) return;

    final percent = ((spent / limit) * 100).round();
    if (percent >= 80) {
      await _service.showBudgetAlert(
        category: category,
        percentUsed: percent,
      );

      // Persist to in-app history
      await NotificationStorage.addNotification(
        NotificationItem(
          id: 'budget_${category}_${DateTime.now().millisecondsSinceEpoch}',
          title: '⚠️ Budget Alert: $category',
          body: 'You\'ve used $percent% of your $category budget.',
          type: 'budget_alert',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Check savings goal milestones and fire alert if threshold crossed.
  Future<void> checkSavingsGoalMilestone({
    required String goalName,
    required double savedAmount,
    required double targetAmount,
  }) async {
    if (!state.notificationsEnabled || !state.savingsGoalAlertsEnabled) return;
    if (targetAmount <= 0) return;

    final percent = ((savedAmount / targetAmount) * 100).round();

    // Fire for specific milestones
    for (final milestone in [25, 50, 75, 100]) {
      if (percent >= milestone) {
        // Check if we already fired for this milestone (SharedPreferences key)
        final key = 'milestone_${goalName}_$milestone';
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getBool(key) == true) continue;

        // Mark as fired
        await prefs.setBool(key, true);

        await _service.showSavingsGoalMilestone(
          goalName: goalName,
          milestonePercent: milestone,
        );

        // Persist to in-app history
        String emoji;
        switch (milestone) {
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

        await NotificationStorage.addNotification(
          NotificationItem(
            id: 'savings_${goalName}_${milestone}_${DateTime.now().millisecondsSinceEpoch}',
            title: '$emoji Savings Milestone!',
            body: 'You\'ve reached $milestone% of your "$goalName" goal!',
            type: 'savings_milestone',
            timestamp: DateTime.now(),
          ),
        );
      }
    }
  }
}
