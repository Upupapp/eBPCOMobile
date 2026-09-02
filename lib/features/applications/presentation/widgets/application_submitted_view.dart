import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/avatars/app_avatar.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/buttons/secondary_button.dart';
import '../../../../shared/widgets/cards/app_card.dart';
import '../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../../../core/providers/applications_provider.dart';
import '../../../../core/models/filing_receipt.dart';
import 'filing_receipt_card.dart';

/// One row of the confirmation summary card.
typedef SubmittedFact = ({String label, String value});

/// The terminal confirmation page shown once a permit application is
/// submitted: a success mark, a headline, an explanation, an optional notice,
/// a card of facts, and the two closing actions.
///
/// Fifteen screens — one per permit type — were near-copies of this, differing
/// only in their strings and in which facts they list. Enough of a copy that
/// several had drifted: three headlines said "… Permit Submitted!" where the
/// rest said "… Application Submitted!", and the body copy alternated between
/// "Your Plumbing Permit application" and "Your demolition permit
/// application" with no rule behind which.
///
/// What is *not* centralised here is deliberate. The notice text stays with
/// each screen because the notices are not the same statement: most say the
/// permit cannot be issued until the related Building Permit is approved,
/// Architectural says "issued" because its own status enum has different
/// members, and Excavation says something else entirely — that the permit does
/// not guarantee the Building Permit will be granted. Folding those into one
/// string would have quietly changed what three screens tell an applicant.
///
/// Likewise the reference number and submission date are parameters rather
/// than facts, because every one of the fifteen put them first and last in the
/// card; [facts] is what goes between them.
class ApplicationSubmittedView extends StatelessWidget {
  final String headline;
  final String body;

  /// The amber banner above the summary card, or null for no banner.
  final String? notice;

  final String referenceNumber;
  final DateTime submissionDate;

  /// The rows between the reference number and the submission date.
  final List<SubmittedFact> facts;

  /// Anything a particular permit shows below the summary card and above the
  /// actions. Only Certificate of Occupancy uses it, for its status sequence —
  /// but consolidating the fifteen screens deleted that section once already,
  /// because nothing in the shared shape had a place to put it.
  final Widget? extra;

  /// Id of the application this submission created, when there is one.
  ///
  /// Without it "View Application" and "Return to Applications" sat side by
  /// side and both went to `/app/applications` — two buttons, different
  /// labels, identical behaviour. There was no id to route to because the
  /// wizards were not creating an application at all.
  final String? applicationId;

  final String primaryLabel;
  final String primaryRoute;
  final String secondaryLabel;
  final String secondaryRoute;

  const ApplicationSubmittedView({
    super.key,
    required this.headline,
    required this.body,
    this.notice,
    required this.referenceNumber,
    required this.submissionDate,
    required this.facts,
    this.applicationId,
    this.extra,
    required this.primaryLabel,
    required this.primaryRoute,
    this.secondaryLabel = 'View Application',
    this.secondaryRoute = '/app/applications',
  });

  @override
  Widget build(BuildContext context) {
    final rows = <SubmittedFact>[
      (label: 'Application Reference Number', value: referenceNumber),
      ...facts,
      (
        label: 'Submission Date',
        value: DateFormat('MMM d, yyyy').format(submissionDate),
      ),
    ];

    return PopScope(
      // The application is already filed; back would land the applicant in a
      // wizard whose draft no longer exists.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: FormScrollScaffold(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.screenPaddingHorizontal,
              vertical: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppAvatar(
                  size: 96,
                  icon: Icons.check_circle,
                  iconSize: 56,
                  backgroundColor: AppColors.statusApprovedBg,
                  foregroundColor: AppColors.statusApproved,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  headline,
                  style: AppTypography.pageTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMuted.copyWith(height: 1.5),
                ),
                if (notice != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    backgroundColor: AppColors.statusPendingBg,
                    showBorder: false,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.statusPending,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(notice!, style: AppTypography.body),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (index, fact) in rows.indexed) ...[
                        if (index > 0) const SizedBox(height: AppSpacing.sm),
                        _FactRow(label: fact.label, value: fact.value),
                      ],
                    ],
                  ),
                ),
                // The receipt, when this device is the one that filed it.
                // Absent rather than invented when it is not: a citizen who
                // reached this screen some other way is shown nothing here
                // instead of a reconstruction that would look identical and
                // mean nothing.
                if (applicationId != null) ...[
                  Builder(
                    builder: (context) {
                      // Looked up defensively, and `listen: false` on
                      // purpose. The receipt is written before this screen is
                      // pushed and never changes while it is visible, and a
                      // view rendered outside the app's provider scope — a
                      // widget test, a preview — has no receipt rather than an
                      // error. Absent and unavailable render identically here,
                      // which is correct: neither is evidence of a filing.
                      FilingReceipt? receipt;
                      try {
                        receipt = Provider.of<ApplicationsProvider>(
                          context,
                          listen: false,
                        ).receiptFor(applicationId!);
                      } on ProviderNotFoundException {
                        receipt = null;
                      }
                      if (receipt == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xl),
                        child: FilingReceiptCard(receipt: receipt),
                      );
                    },
                  ),
                ],
                if (extra != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  extra!,
                ],
                const SizedBox(height: AppSpacing.xxl),
                SecondaryButton(
                  label: secondaryLabel,
                  onPressed: () => context.go(
                    applicationId == null
                        ? secondaryRoute
                        : '/applications/$applicationId',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: primaryLabel,
                  onPressed: () => context.go(primaryRoute),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  final String label;
  final String value;

  const _FactRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.bodyStrong),
      ],
    );
  }
}
