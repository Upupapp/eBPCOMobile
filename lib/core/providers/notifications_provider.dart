import 'package:flutter/material.dart';

import '../models/notification_model.dart';

/// Holds the mock notification list shared between the dashboard's
/// "recent notifications" preview and the full Notifications screen.
class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider() {
    _seedMockNotifications();
  }

  final List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  List<NotificationModel> get recent => _notifications.take(3).toList();

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _seedMockNotifications() {
    final now = DateTime.now();
    _notifications.addAll([
      NotificationModel(
        id: 'n1',
        title: 'Application submitted successfully',
        message:
            'Your New Business Permit application E-BPCO-2026-000145 has been received.',
        createdAt: now.subtract(const Duration(hours: 2)),
        icon: Icons.check_circle_outline,
        isRead: false,
      ),
      NotificationModel(
        id: 'n2',
        title: 'Your documents are under initial review',
        message: 'An evaluator is checking your submitted requirements.',
        createdAt: now.subtract(const Duration(hours: 5)),
        icon: Icons.fact_check_outlined,
        isRead: false,
      ),
      NotificationModel(
        id: 'n3',
        title: 'Payment assessment will appear after evaluation',
        message:
            'Once your documents pass evaluation, your assessment fee will be shown here.',
        createdAt: now.subtract(const Duration(days: 1)),
        icon: Icons.payments_outlined,
        isRead: true,
      ),
      NotificationModel(
        id: 'n4',
        title: 'Welcome to E-BPCO',
        message:
            'Thanks for creating an account. You can now apply for permits from your phone.',
        createdAt: now.subtract(const Duration(days: 2)),
        icon: Icons.celebration_outlined,
        isRead: true,
      ),
      NotificationModel(
        id: 'n5',
        title: 'Reminder: Keep your documents ready',
        message:
            'Prepare valid IDs and proof of business address for a faster evaluation.',
        createdAt: now.subtract(const Duration(days: 3)),
        icon: Icons.notifications_active_outlined,
        isRead: true,
      ),
    ]);
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1 || _notifications[index].isRead) return;
    _notifications[index].isRead = true;
    notifyListeners();
  }

  void markAllAsRead() {
    var changed = false;
    for (final notification in _notifications) {
      if (!notification.isRead) {
        notification.isRead = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }
}
