import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/notification_event.dart';
import '../../../core/providers/notifications_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/states/empty_state.dart';
import '../../../shared/widgets/states/loading_view.dart';

/// Notifications as a work queue.
///
/// Ordered by resolution, not by time: what still needs the applicant sits
/// above what is merely news, however old. Reading an item never removes it
/// from the top section — only dealing with the underlying condition does.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _unreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationsProvider>();

    if (provider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const LoadingView(),
      );
    }

    List<NotificationEvent> filter(List<NotificationEvent> source) =>
        _unreadOnly ? source.where((e) => !e.isRead).toList() : source;

    final needsAction = filter(provider.needsAction);
    final updates = filter(provider.updates);
    final earlier = filter(provider.earlier);
    final isEmpty =
        needsAction.isEmpty && updates.isEmpty && earlier.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: _unreadOnly ? 'Show all' : 'Unread only',
            icon: Icon(
              _unreadOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
            onPressed: () => setState(() => _unreadOnly = !_unreadOnly),
          ),
          // An icon rather than a text button: at 200% text scale
          // "Mark all read" alone is wider than the title bar of a 360dp
          // phone, and an AppBar cannot scroll to accommodate it.
          IconButton(
            tooltip: 'Mark all read',
            icon: const Icon(Icons.done_all),
            onPressed: provider.unreadCount == 0
                ? null
                : provider.markAllAsRead,
          ),
        ],
      ),
      body: SafeArea(
        child: isEmpty
            ? const EmptyState(
                icon: Icons.notifications_none_outlined,
                title: 'Nothing here',
                message:
                    'Updates on your applications appear here as the office '
                    'works on them.',
              )
            : RefreshIndicator(
                onRefresh: provider.refresh,
                color: AppColors.primary,
                child: ListView(
                  padding: const EdgeInsets.all(
                    AppConstants.screenPaddingHorizontal,
                  ),
                  children: [
                    if (needsAction.isNotEmpty)
                      _Section(
                        title: 'Needs your action',
                        tone: AppColors.statusRejected,
                        events: needsAction,
                      ),
                    if (updates.isNotEmpty)
                      _Section(
                        title: 'Updates',
                        tone: AppColors.statusInfo,
                        events: updates,
                        groupByDay: true,
                      ),
                    if (earlier.isNotEmpty)
                      _Section(
                        title: 'Earlier',
                        tone: AppColors.textMuted,
                        events: earlier,
                      ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Color tone;
  final List<NotificationEvent> events;
  final bool groupByDay;

  const _Section({
    required this.title,
    required this.tone,
    required this.events,
    this.groupByDay = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, color: tone),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '$title (${events.length})',
                  style: AppTypography.sectionTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < events.length; i++) ...[
            if (groupByDay && _needsDayHeader(events, i))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  _dayLabel(events[i].createdAt),
                  style: AppTypography.helper.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _NotificationCard(event: events[i]),
            ),
          ],
        ],
      ),
    );
  }

  bool _needsDayHeader(List<NotificationEvent> events, int index) {
    if (index == 0) return true;
    final previous = events[index - 1].createdAt;
    final current = events[index].createdAt;
    return previous.day != current.day || previous.month != current.month;
  }

  static String _dayLabel(DateTime at) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    final difference = today.difference(day).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return DateFormat('MMM d, yyyy').format(at);
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationEvent event;

  const _NotificationCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NotificationsProvider>();
    final outstanding = event.isOutstandingAction;
    final tone = outstanding
        ? AppColors.statusRejected
        : event.priority == NotificationPriority.progress
        ? AppColors.statusInfo
        : AppColors.textMuted;

    return Material(
      color: event.isRead ? AppColors.background : AppColors.surface,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      child: InkWell(
        onTap: () {
          // Reading is not resolving: this marks the item seen and takes the
          // applicant to where the thing can actually be dealt with, but the
          // item stays outstanding until the condition clears.
          provider.markAsRead(event.id);
          context.push(event.deepLink);
        },
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppConstants.minTouchTarget,
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              AppConstants.borderRadiusMedium,
            ),
            border: Border.all(
              color: outstanding ? AppColors.statusRejected : AppColors.border,
              width: outstanding ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(event.type.icon, size: 20, color: tone),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: AppTypography.cardTitle.copyWith(
                              color: outstanding ? tone : null,
                            ),
                          ),
                        ),
                        if (!event.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.secondaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(event.body, style: AppTypography.bodyMuted),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      DateFormat('MMM d, h:mm a').format(event.createdAt),
                      style: AppTypography.helper,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
