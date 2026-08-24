import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/application_model.dart';
import '../../../core/models/draft_summary.dart';
import '../../../core/providers/applications_provider.dart';
import '../../../core/providers/draft_registry.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/badges/status_badge.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/search/app_search_field.dart';
import '../../../shared/widgets/states/empty_state.dart';
import '../../../shared/widgets/states/load_failure_state.dart';
import '../../../shared/widgets/states/loading_view.dart';
import 'widgets/application_list_tile.dart';

/// Which slice of the applicant's applications is on screen.
enum ApplicationSegment { drafts, inProgress, needsAction, completed }

extension ApplicationSegmentX on ApplicationSegment {
  String get label {
    switch (this) {
      case ApplicationSegment.drafts:
        return 'Drafts';
      case ApplicationSegment.inProgress:
        return 'In Progress';
      case ApplicationSegment.needsAction:
        return 'Needs Action';
      case ApplicationSegment.completed:
        return 'Completed';
    }
  }

  bool matches(ApplicationModel application) {
    switch (this) {
      case ApplicationSegment.drafts:
        return application.applicantStatus == ApplicationStatus.draft;
      case ApplicationSegment.needsAction:
        return application.requiresApplicantAction;
      case ApplicationSegment.inProgress:
        // Deliberately excludes anything needing action — an application the
        // applicant is holding up does not belong under a heading that reads
        // as "the office is working on it".
        return !application.requiresApplicantAction &&
            const {
              ApplicationStatus.submitted,
              ApplicationStatus.underReview,
              ApplicationStatus.paymentVerification,
              ApplicationStatus.approved,
            }.contains(application.applicantStatus);
      case ApplicationSegment.completed:
        return const {
          ApplicationStatus.released,
          ApplicationStatus.rejected,
        }.contains(application.applicantStatus);
    }
  }
}

/// Everything the applicant has filed or started.
///
/// This is the Applications tab root. Before it, the tab opened straight onto
/// the permit catalog, which meant the app had no surface at all for the
/// applications a user already had — filing was visible and tracking was not.
class ApplicationListScreen extends StatefulWidget {
  const ApplicationListScreen({super.key});

  @override
  State<ApplicationListScreen> createState() => _ApplicationListScreenState();
}

class _ApplicationListScreenState extends State<ApplicationListScreen> {
  ApplicationSegment _segment = ApplicationSegment.inProgress;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicationsProvider>();
    final all = provider.applications;

    // Drafts come from the wizards, not from ApplicationsProvider. Nothing in
    // the app ever creates an application with `ApplicationStatus.draft`, so
    // the Drafts segment filtered for a status that never occurs and read
    // "Drafts (0)" no matter how many half-finished applications the applicant
    // had. Their drafts were known — MainShell already nudges about idle ones
    // — just never shown anywhere.
    final drafts = DraftRegistry.summaries(context).where((draft) {
      if (_query.isEmpty) return true;
      return draft.permitTypeLabel.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    final matching = all.where((application) {
      if (!_segment.matches(application)) return false;
      if (_query.isEmpty) return true;
      final needle = _query.toLowerCase();
      return application.applicationNumber.toLowerCase().contains(needle) ||
          application.businessName.toLowerCase().contains(needle) ||
          (application.permitTypeLabel ?? application.type.label)
              .toLowerCase()
              .contains(needle);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'File a new application',
            onPressed: () => context.push('/applications/new'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.screenPaddingHorizontal,
                AppSpacing.md,
                AppConstants.screenPaddingHorizontal,
                AppSpacing.sm,
              ),
              child: AppSearchField(
                hint: 'Search by reference, business, or permit',
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.screenPaddingHorizontal,
                ),
                children: [
                  for (final segment in ApplicationSegment.values)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: _SegmentChip(
                        label: segment.label,
                        count: segment == ApplicationSegment.drafts
                            ? DraftRegistry.summaries(context).length
                            : all.where(segment.matches).length,
                        selected: segment == _segment,
                        // Needs Action always reads as urgent, even when the
                        // applicant is looking at another segment.
                        urgent: segment == ApplicationSegment.needsAction,
                        onTap: () => setState(() => _segment = segment),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _segment == ApplicationSegment.drafts
                  ? (drafts.isEmpty
                        ? _EmptyFor(
                            segment: _segment,
                            hasQuery: _query.isNotEmpty,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(
                              AppConstants.screenPaddingHorizontal,
                            ),
                            itemCount: drafts.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) => _DraftTile(
                              draft: drafts[index],
                              onTap: () => context.push(drafts[index].route),
                            ),
                          ))
                  : provider.isLoading
                  ? const LoadingView()
                  // Failure before emptiness: "you have nothing here" is a
                  // claim about the applicant's own filings, and a timed-out
                  // request is not grounds for making it.
                  : provider.hasLoadError && provider.applications.isEmpty
                  ? LoadFailureState(
                      what: 'your applications',
                      onRetry: provider.refresh,
                    )
                  : matching.isEmpty
                  ? _EmptyFor(segment: _segment, hasQuery: _query.isNotEmpty)
                  : RefreshIndicator(
                      onRefresh: provider.refresh,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(
                          AppConstants.screenPaddingHorizontal,
                        ),
                        itemCount: matching.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final application = matching[index];
                          return ApplicationListTile(
                            application: application,
                            pledge: provider.pledgeFor(application),
                            onTap: () => context.push(
                              '/applications/${application.id}',
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final bool urgent;
  final VoidCallback onTap;

  const _SegmentChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.urgent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = urgent && count > 0;
    final foreground = selected
        ? AppColors.textOnPrimary
        : highlight
        ? AppColors.statusRejected
        : AppColors.textSecondary;
    final background = selected
        ? (highlight ? AppColors.statusRejected : AppColors.primary)
        : (highlight ? AppColors.statusRejectedBg : AppColors.surfaceMuted);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusPill),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          alignment: Alignment.center,
          child: Text(
            '$label ($count)',
            style: AppTypography.helper.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyFor extends StatelessWidget {
  final ApplicationSegment segment;
  final bool hasQuery;

  const _EmptyFor({required this.segment, required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    if (hasQuery) {
      return const EmptyState(
        icon: Icons.search_off_outlined,
        title: 'No matches',
        message: 'Try a different reference, business, or permit type.',
      );
    }

    switch (segment) {
      case ApplicationSegment.needsAction:
        return const EmptyState(
          icon: Icons.check_circle_outline,
          title: 'Nothing needs you right now',
          message:
              'When the office asks for a correction or issues an Order of '
              'Payment, it will appear here.',
        );
      case ApplicationSegment.drafts:
        return const EmptyState(
          icon: Icons.edit_note_outlined,
          title: 'No drafts',
          message:
              'Applications you start but do not finish are saved here so you '
              'can pick them up later.',
        );
      case ApplicationSegment.inProgress:
        return const EmptyState(
          icon: Icons.folder_open_outlined,
          title: 'Nothing in progress',
          message: 'File an application and you can track it here.',
        );
      case ApplicationSegment.completed:
        return const EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Nothing completed yet',
          message: 'Released and closed applications are kept here.',
        );
    }
  }
}

/// One unfinished application, as the Drafts segment shows it.
///
/// Deliberately not [ApplicationListTile]: a draft has no reference number, no
/// status and no service pledge — the things that tile is built to show. What
/// it has is how far along it is and when it was last touched, which is what
/// decides whether the applicant picks it back up.
class _DraftTile extends StatelessWidget {
  final DraftSummary draft;
  final VoidCallback onTap;

  const _DraftTile({required this.draft, required this.onTap});

  String _lastTouched() {
    final saved = draft.lastSavedAt;
    if (saved == null) return 'Not saved yet';
    final days = draft.daysSinceSaved(DateTime.now());
    if (days == null || days == 0) return 'Last saved today';
    if (days == 1) return 'Last saved yesterday';
    return 'Last saved $days days ago';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  draft.permitTypeLabel,
                  style: AppTypography.cardTitle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: StatusBadge(
                  label: 'Draft',
                  color: AppColors.textSecondary,
                  backgroundColor: AppColors.surfaceMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(_lastTouched(), style: AppTypography.helper),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label:
                '${draft.percentComplete}% complete, step '
                '${draft.completedSteps} of ${draft.totalSteps}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusXs),
              child: LinearProgressIndicator(
                value: draft.totalSteps == 0
                    ? 0
                    : draft.completedSteps / draft.totalSteps,
                minHeight: 6,
                backgroundColor: AppColors.surfaceMuted,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${draft.percentComplete}% complete · Tap to continue',
            style: AppTypography.bodyMuted,
          ),
        ],
      ),
    );
  }
}
