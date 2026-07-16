import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/notifications_provider.dart';
import '../../../core/widgets/empty_state.dart';
import '../../dashboard/presentation/widgets/recent_notification_tile.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationsProvider = context.watch<NotificationsProvider>();
    final notifications = notificationsProvider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: notificationsProvider.unreadCount > 0
                ? notificationsProvider.markAllAsRead
                : null,
            child: const Text('Mark all as read'),
          ),
        ],
      ),
      body: SafeArea(
        child: notifications.isEmpty
            ? const EmptyState(
                icon: Icons.notifications_none_outlined,
                title: 'No notifications yet',
                message:
                    'Updates about your permit applications will appear here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.screenPaddingHorizontal,
                  vertical: 12,
                ),
                itemCount: notifications.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return RecentNotificationTile(
                    notification: notification,
                    onTap: () =>
                        notificationsProvider.markAsRead(notification.id),
                  );
                },
              ),
      ),
    );
  }
}
