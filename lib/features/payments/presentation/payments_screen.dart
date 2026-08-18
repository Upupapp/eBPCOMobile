import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/application_model.dart';
import '../../../core/models/money.dart';
import '../../../core/models/payment_assessment_model.dart';
import '../../../core/providers/applications_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/states/empty_state.dart';
import '../../../shared/widgets/states/loading_view.dart';

/// The Payments tab.
///
/// Organised by what the applicant has to do about each item rather than by
/// application: Due Now first, then what is with the Treasurer's Office, then
/// what is settled. Applications with no assessment yet are not listed at
/// all — there is no amount to show and inventing a placeholder figure would
/// be worse than silence.
class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicationsProvider>();

    if (provider.isLoading) {
      return Scaffold(
        appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          IconButton(
            tooltip: 'Payment history',
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/payments/history'),
          ),
        ],
      ),
        body: const LoadingView(),
      );
    }

    final assessed = provider.applications
        .where((a) => a.payment?.isAssessed ?? false)
        .toList();

    List<ApplicationModel> withStatus(Set<PaymentAssessmentStatus> statuses) =>
        assessed.where((a) => statuses.contains(a.payment!.status)).toList();

    // "Due Now" is a grouping, not a stored status. The admin's PaymentStatus
    // has only four values and none of them mean "assessed but unpaid" — that
    // state is the *lifecycle* status Assessed combined with no payment
    // transaction yet, which surfaces here as Not Yet Available on a record
    // that nonetheless carries an Order of Payment. Overdue joins the same
    // group because the applicant's obligation is identical, only later.
    final dueNow = withStatus({
      PaymentAssessmentStatus.notYetAvailable,
      PaymentAssessmentStatus.overdue,
    });
    final awaiting = withStatus({PaymentAssessmentStatus.pending});
    final paid = withStatus({PaymentAssessmentStatus.paid});

    final totalDue = sumPesos(
      dueNow.map((a) => a.payment!.amountDue ?? const PesoAmount.zero()),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          IconButton(
            tooltip: 'Payment history',
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/payments/history'),
          ),
        ],
      ),
      body: SafeArea(
        child: assessed.isEmpty
            ? const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Nothing to pay yet',
                message:
                    'Fees are assessed once your documents pass evaluation. '
                    'Your Order of Payment appears here as soon as the office '
                    'issues it.',
              )
            : RefreshIndicator(
                onRefresh: provider.refresh,
                color: AppColors.primary,
                child: ListView(
                  padding: const EdgeInsets.all(
                    AppConstants.screenPaddingHorizontal,
                  ),
                  children: [
                    if (!totalDue.isZero) _TotalDueBanner(total: totalDue),
                    if (dueNow.isNotEmpty)
                      _Group(
                        title: 'Due Now',
                        tone: AppColors.statusRejected,
                        applications: dueNow,
                      ),
                    if (awaiting.isNotEmpty)
                      _Group(
                        title: 'Awaiting Verification',
                        tone: AppColors.statusPending,
                        applications: awaiting,
                      ),
                    if (paid.isNotEmpty)
                      _Group(
                        title: 'Paid',
                        tone: AppColors.statusApproved,
                        applications: paid,
                      ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
      ),
    );
  }
}

class _TotalDueBanner extends StatelessWidget {
  final PesoAmount total;

  const _TotalDueBanner({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.statusRejectedBg,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.statusRejected),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total due', style: AppTypography.helper),
          const SizedBox(height: 2),
          Text(
            total.formatted,
            style: AppTypography.pageTitle.copyWith(
              color: AppColors.statusRejected,
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final Color tone;
  final List<ApplicationModel> applications;

  const _Group({
    required this.title,
    required this.tone,
    required this.applications,
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
                  '$title (${applications.length})',
                  style: AppTypography.sectionTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final application in applications)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _PaymentTile(application: application),
            ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final ApplicationModel application;

  const _PaymentTile({required this.application});

  @override
  Widget build(BuildContext context) {
    final payment = application.payment!;
    final due = payment.amountDue;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      child: InkWell(
        onTap: () => context.push('/applications/${application.id}/pay'),
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
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.permitTypeLabel ?? application.type.label,
                      style: AppTypography.cardTitle,
                    ),
                    Text(
                      application.applicationNumber,
                      style: AppTypography.helper,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      // Never a zero standing in for an unknown: an
                      // unassessed application is not listed at all, so a
                      // null here can only mean malformed data.
                      due?.formatted ?? 'Amount unavailable',
                      style: AppTypography.cardTitle.copyWith(
                        color: payment.status.color,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
