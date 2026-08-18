import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/applications_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/business_provider.dart';
import '../../../core/providers/notifications_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/layout/responsive_card_grid.dart';
import '../../../shared/widgets/layout/section_header.dart';
import '../../../shared/widgets/search/app_search_field.dart';
import 'widgets/action_required_card.dart';
import 'widgets/active_application_card.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_stat_card.dart';
import 'widgets/permit_summary_tile.dart';
import 'widgets/recent_notification_tile.dart';

/// Home — a triage surface.
///
/// Render order is deliberate and inverted relative to a conventional
/// dashboard: whatever the applicant owes comes first, what is moving comes
/// second, and what they could start comes last. An applicant with an
/// unresolved Letter of Instruction should not have to scroll past a greeting
/// and a statistics grid to find out their permit is blocked.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final applicationsProvider = context.watch<ApplicationsProvider>();
    final notificationsProvider = context.watch<NotificationsProvider>();
    final businessProvider = context.watch<BusinessProvider>();
    final user = authProvider.currentUser;

    final actionItems = applicationsProvider.actionItems;
    final activeApplication = applicationsProvider.activeApplication;
    final releasedPermits = applicationsProvider.releasedPermits;
    final counters = applicationsProvider.homeCounters;
    final hasBusiness = businessProvider.businesses.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: applicationsProvider.refresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardHeader(
                firstName: user?.firstName ?? 'there',
                initials: user?.initials ?? 'U',
                unreadCount: actionItems.length,
                onNotificationsTap: () => context.push('/app/notifications'),
                onProfileTap: () => context.go('/app/profile'),
                searchBar: AppSearchField(
                  floating: true,
                  hint: 'Search applications, businesses...',
                  onChanged: (_) {},
                  onTap: () => context.go('/app/applications'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.screenPaddingHorizontal,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---- 1. Action Required ------------------------------
                    // Absent entirely when there is nothing outstanding. An
                    // empty "nothing to do" placeholder would train the user
                    // to ignore this region, which is the one region that
                    // must never be ignored.
                    if (actionItems.isNotEmpty) ...[
                      Text(
                        actionItems.length == 1
                            ? 'Needs your action'
                            : 'Needs your action (${actionItems.length})',
                        style: AppTypography.sectionTitle.copyWith(
                          color: AppColors.statusRejected,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      for (final item in actionItems) ...[
                        ActionRequiredCard(
                          item: item,
                          onTap: () => context.push(item.route),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                    ],

                    // ---- 2. Start an application -------------------------
                    PrimaryButton(
                      label: 'Apply for Permit',
                      icon: Icons.add_circle_outline,
                      onPressed: () => context.push('/applications/new'),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ---- 3. Active applications --------------------------
                    if (activeApplication == null)
                      _GettingStartedCard(hasBusiness: hasBusiness)
                    else
                      ActiveApplicationCard(
                        application: activeApplication,
                        pledge: applicationsProvider.pledgeFor(
                          activeApplication,
                        ),
                        onViewDetails: () =>
                            context.push('/applications/${activeApplication.id}'),
                      ),
                    const SizedBox(height: AppSpacing.xl),

                    // ---- 4. Counters, each a live filter -----------------
                    const SectionHeader(title: 'Application Summary'),
                    const SizedBox(height: AppSpacing.md),
                    ResponsiveCardGrid(
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      children: [
                        DashboardStatCard(
                          label: 'In Progress',
                          count: counters['In Progress'] ?? 0,
                          icon: Icons.hourglass_bottom_outlined,
                          color: AppColors.statusInfo,
                          onTap: () => context.go('/app/applications'),
                        ),
                        DashboardStatCard(
                          label: 'Action Needed',
                          count: counters['Action Needed'] ?? 0,
                          icon: Icons.priority_high_rounded,
                          color: AppColors.statusRejected,
                          onTap: () => context.go('/app/applications'),
                        ),
                        DashboardStatCard(
                          label: 'Approved',
                          count: counters['Approved'] ?? 0,
                          icon: Icons.check_circle_outline,
                          color: AppColors.statusApproved,
                          onTap: () => context.go('/app/applications'),
                        ),
                        DashboardStatCard(
                          label: 'Released',
                          count: counters['Released'] ?? 0,
                          icon: Icons.local_shipping_outlined,
                          color: AppColors.statusApproved,
                          onTap: () => context.go('/app/applications'),
                        ),
                      ],
                    ),

                    // ---- 5. My permits -----------------------------------
                    if (releasedPermits.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      const SectionHeader(title: 'My Permits'),
                      const SizedBox(height: AppSpacing.md),
                      for (final permit in releasedPermits) ...[
                        PermitSummaryTile(
                          application: permit,
                          asOf: DateTime.now(),
                          onTap: () =>
                              context.push('/applications/${permit.id}'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],

                    // ---- 6. Recent activity ------------------------------
                    const SizedBox(height: AppSpacing.xl),
                    SectionHeader(
                      title: 'Recent Activity',
                      actionLabel: 'See All',
                      onActionTap: () => context.push('/app/notifications'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...notificationsProvider.recent.map(
                      (notification) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: RecentNotificationTile(
                          notification: notification,
                          onTap: () => context.push('/app/notifications'),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
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

/// Shown in place of the active-application card when there is nothing in
/// flight. Which guidance is right depends on how far along the applicant is,
/// so the two cases are distinguished rather than sharing one vague empty
/// state.
class _GettingStartedCard extends StatelessWidget {
  final bool hasBusiness;

  const _GettingStartedCard({required this.hasBusiness});

  @override
  Widget build(BuildContext context) {
    final steps = hasBusiness
        ? const [
            'Secure your locational or zoning clearance from the City or '
                'Municipal Planning and Development Office.',
            'Engage a licensed architect or engineer and have their PRC and '
                'PTR details ready.',
            'Gather proof of ownership, barangay clearance, and tax documents.',
          ]
        : const [
            'Register the business or property owner profile you will file '
                'under.',
            'Secure your locational or zoning clearance before applying.',
            'Engage a licensed architect or engineer for your plans.',
          ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasBusiness ? 'Before you apply' : 'Set up your profile',
            style: AppTypography.cardTitle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Applications move faster when these are in hand first.',
            style: AppTypography.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final step in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: AppColors.secondaryBlue,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(step, style: AppTypography.body)),
                ],
              ),
            ),
          if (!hasBusiness) ...[
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              label: 'Register a Business',
              icon: Icons.storefront_outlined,
              onPressed: () => context.push('/business/register'),
            ),
          ],
        ],
      ),
    );
  }
}
