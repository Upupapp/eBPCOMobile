import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/application_summary_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/dashboard_provider.dart';
import '../../../core/providers/notifications_provider.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_chip.dart';
import 'widgets/active_application_card.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_stat_card.dart';
import 'widgets/quick_action_card.dart';
import 'widgets/recent_notification_tile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _applyForPermit(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Permit application setup will be available in the next module.',
        ),
      ),
    );
    context.go('/app/applications');
  }

  void _viewApplicationDetails(
    BuildContext context,
    ApplicationSummaryModel application,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadiusLarge),
        ),
      ),
      builder: (context) => _ApplicationDetailSheet(application: application),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final notificationsProvider = context.watch<NotificationsProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: dashboardProvider.refresh,
          color: AppColors.primaryNavy,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.screenPaddingHorizontal,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DashboardHeader(
                  firstName: user?.firstName ?? 'there',
                  initials: user?.initials ?? 'U',
                  unreadCount: notificationsProvider.unreadCount,
                  onNotificationsTap: () => context.go('/app/notifications'),
                  onProfileTap: () => context.go('/app/profile'),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Apply for Permit',
                  icon: Icons.add_circle_outline,
                  onPressed: () => _applyForPermit(context),
                ),
                const SizedBox(height: 20),
                ActiveApplicationCard(
                  application: dashboardProvider.activeApplication,
                  onViewDetails: () => _viewApplicationDetails(
                    context,
                    dashboardProvider.activeApplication,
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader(title: 'Application Summary'),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    DashboardStatCard(
                      label: 'Draft',
                      count: dashboardProvider.summaryCounts['Draft'] ?? 0,
                      icon: Icons.edit_note_outlined,
                      color: AppColors.textMuted,
                    ),
                    DashboardStatCard(
                      label: 'Submitted',
                      count: dashboardProvider.summaryCounts['Submitted'] ?? 0,
                      icon: Icons.send_outlined,
                      color: AppColors.statusInfo,
                    ),
                    DashboardStatCard(
                      label: 'Approved',
                      count: dashboardProvider.summaryCounts['Approved'] ?? 0,
                      icon: Icons.check_circle_outline,
                      color: AppColors.statusApproved,
                    ),
                    DashboardStatCard(
                      label: 'Released',
                      count: dashboardProvider.summaryCounts['Released'] ?? 0,
                      icon: Icons.local_shipping_outlined,
                      color: AppColors.statusApproved,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.7,
                  children: [
                    QuickActionCard(
                      label: 'Apply for Permit',
                      icon: Icons.add_circle_outline,
                      onTap: () => _applyForPermit(context),
                    ),
                    QuickActionCard(
                      label: 'View Applications',
                      icon: Icons.folder_outlined,
                      onTap: () => context.go('/app/applications'),
                    ),
                    QuickActionCard(
                      label: 'Check Payments',
                      icon: Icons.payments_outlined,
                      onTap: () => context.go('/app/payments'),
                    ),
                    QuickActionCard(
                      label: 'Track Status',
                      icon: Icons.timeline_outlined,
                      onTap: () => context.go('/app/applications'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SectionHeader(
                  title: 'Recent Notifications',
                  actionLabel: 'See All',
                  onActionTap: () => context.go('/app/notifications'),
                ),
                const SizedBox(height: 8),
                ...notificationsProvider.recent.map(
                  (notification) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: RecentNotificationTile(
                      notification: notification,
                      onTap: () => context.go('/app/notifications'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ApplicationDetailSheet extends StatelessWidget {
  final ApplicationSummaryModel application;

  const _ApplicationDetailSheet({required this.application});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Application Details',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                StatusChip(
                  label: application.status.label,
                  color: application.status.color,
                  backgroundColor: application.status.backgroundColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Application Number',
              value: application.applicationNumber,
            ),
            _DetailRow(label: 'Business Name', value: application.businessName),
            _DetailRow(
              label: 'Application Type',
              value: application.applicationType,
            ),
            _DetailRow(
              label: 'Progress',
              value: '${(application.progress * 100).round()}%',
            ),
            _DetailRow(label: 'Next Step', value: application.nextStep),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14.5,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
