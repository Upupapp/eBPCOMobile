import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Dashboard header greeting the user, with notification and profile
/// shortcuts.
class DashboardHeader extends StatelessWidget {
  final String firstName;
  final String initials;
  final int unreadCount;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  const DashboardHeader({
    super.key,
    required this.firstName,
    required this.initials,
    required this.unreadCount,
    required this.onNotificationsTap,
    required this.onProfileTap,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                firstName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Semantics(
          label: unreadCount > 0
              ? '$unreadCount unread notifications'
              : 'Notifications',
          button: true,
          child: IconButton(
            onPressed: onNotificationsTap,
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(
                Icons.notifications_outlined,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Semantics(
          label: 'Profile',
          button: true,
          child: InkWell(
            onTap: onProfileTap,
            customBorder: const CircleBorder(),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryNavy,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
