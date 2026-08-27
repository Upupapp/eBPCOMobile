import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/contract/admin_vocabulary.dart';
import '../../../../core/models/application_detail.dart';
import '../../../../core/models/application_model.dart';
import '../../../../core/models/document_model.dart';
import '../../../../core/models/lifecycle_status.dart';
import '../../../../core/models/payment_assessment_model.dart';
import '../../../../core/models/permit_classification.dart';
import '../../../../core/providers/applications_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/status_badge.dart';
import '../../../../shared/widgets/states/empty_state.dart';
import 'widgets/detail_action_banner.dart';
import 'widgets/evaluation_section.dart';
import 'widgets/inspection_section.dart';
import 'widgets/lifecycle_timeline.dart';

/// The full record of one application.
///
/// Everything after submission lives here — evaluation stages, letters of
/// instruction, the inspection, the permit, and the release. Before this
/// screen an application effectively ended at submission, which left the
/// applicant with no way to learn anything about their own file.
class ApplicationDetailScreen extends StatelessWidget {
  final String applicationId;

  const ApplicationDetailScreen({super.key, required this.applicationId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicationsProvider>();
    final application = provider.byId(applicationId);

    if (application == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Application')),
        body: const EmptyState(
          icon: Icons.search_off_outlined,
          title: 'Application not found',
          message: 'This application could not be found on this device.',
        ),
      );
    }

    final pledge = provider.pledgeFor(application);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(application.applicationNumber)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
          children: [
            _Header(application: application, pledge: pledge),
            const SizedBox(height: AppSpacing.lg),

            // Whatever the applicant owes comes before the record of what has
            // already happened.
            DetailActionBanner(application: application),

            _Section(
              title: 'Timeline',
              child: LifecycleTimeline(
                entries: _timelineFor(application),
                currentStatus:
                    application.lifecycleStatus ??
                    ApplicationLifecycleStatus.submitted,
              ),
            ),

            if (application.evaluations.isNotEmpty)
              _Section(
                title: 'Evaluations',
                child: EvaluationSection(evaluations: application.evaluations),
              ),

            if (application.inspection != null)
              _Section(
                title: 'Inspection',
                child: InspectionSection(inspection: application.inspection!),
              ),

            _Section(
              title: 'Documents',
              child: _DocumentList(application: application),
            ),

            _Section(
              title: 'Payment',
              child: _PaymentSummary(application: application),
            ),

            if (application.permit != null)
              _Section(
                title: 'Permit',
                child: _PermitSummary(
                  application: application,
                  onOpen: () =>
                      context.push('/applications/$applicationId/permit'),
                ),
              ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  /// Prefers the rich timeline, falling back to the older coarse status
  /// history for records created before lifecycle tracking existed.
  List<TimelineEntry> _timelineFor(ApplicationModel application) {
    if (application.timeline.isNotEmpty) return application.timeline;
    return [
      for (final entry in application.statusHistory)
        TimelineEntry(
          status: _coarseToLifecycle(entry.status),
          occurredAt: entry.timestamp,
        ),
    ];
  }

  ApplicationLifecycleStatus _coarseToLifecycle(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.draft:
        return ApplicationLifecycleStatus.draft;
      case ApplicationStatus.submitted:
        return ApplicationLifecycleStatus.submitted;
      case ApplicationStatus.underReview:
        return ApplicationLifecycleStatus.underEvaluation;
      case ApplicationStatus.paymentVerification:
        return ApplicationLifecycleStatus.paymentUnderVerification;
      case ApplicationStatus.approved:
        return ApplicationLifecycleStatus.approved;
      case ApplicationStatus.released:
        return ApplicationLifecycleStatus.released;
      case ApplicationStatus.rejected:
        return ApplicationLifecycleStatus.rejected;
    }
  }
}

class _Header extends StatelessWidget {
  final ApplicationModel application;
  final dynamic pledge;

  const _Header({required this.application, required this.pledge});

  @override
  Widget build(BuildContext context) {
    final status = application.applicantStatus;
    final format = DateFormat('MMM d, yyyy');

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  application.permitTypeLabel ?? application.type.label,
                  style: AppTypography.sectionTitle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: StatusBadge(
                  label: status.label,
                  color: status.color,
                  backgroundColor: status.backgroundColor,
                ),
              ),
            ],
          ),
          if (application.statusSubLine != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(application.statusSubLine!, style: AppTypography.bodyMuted),
          ],
          const SizedBox(height: AppSpacing.md),
          _Fact(label: 'Business', value: application.businessName),
          _Fact(
            label: 'Filed',
            value: format.format(application.submittedDate),
          ),
          if (application.classification != null)
            _Fact(
              label: 'Classification',
              value: application.classification!.pledgeDescription,
            ),
          if (pledge != null)
            _Fact(
              label: 'Target release',
              value: format.format(pledge.pledgedCompletionDate),
            ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;

  const _Fact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 108, child: Text(label, style: AppTypography.helper)),
          Expanded(child: Text(value, style: AppTypography.body)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _DocumentList extends StatelessWidget {
  final ApplicationModel application;

  const _DocumentList({required this.application});

  @override
  Widget build(BuildContext context) {
    if (application.documents.isEmpty) {
      return Text('No documents attached.', style: AppTypography.bodyMuted);
    }

    // Anything the applicant has to act on goes first. A document turned back
    // for revision, sitting eleventh in submission order, is a document the
    // applicant does not know about.
    final documents = [...application.documents]
      ..sort((a, b) {
        if (a.needsApplicantAction == b.needsApplicantAction) return 0;
        return a.needsApplicantAction ? -1 : 1;
      });

    return Column(
      children: [
        for (final document in documents)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _DocumentRow(document: document),
          ),
      ],
    );
  }
}

/// One submitted document, and whatever the office has said about it.
class _DocumentRow extends StatelessWidget {
  final DocumentModel document;

  const _DocumentRow({required this.document});

  ({Color colour, Color background, String label}) get _statusStyle {
    if (document.isExpired) {
      return (
        colour: AppColors.statusRejected,
        background: AppColors.statusRejectedBg,
        label: 'Expired',
      );
    }
    return switch (document.status) {
      DocumentStatus.accepted => (
        colour: AppColors.statusApproved,
        background: AppColors.statusApprovedBg,
        label: 'Accepted',
      ),
      DocumentStatus.rejected => (
        colour: AppColors.statusRejected,
        background: AppColors.statusRejectedBg,
        label: 'Rejected',
      ),
      DocumentStatus.revisionRequired => (
        colour: AppColors.statusPending,
        background: AppColors.statusPendingBg,
        label: 'Revision required',
      ),
      DocumentStatus.underReview => (
        colour: AppColors.statusInfo,
        background: AppColors.surfaceMuted,
        label: 'Under review',
      ),
      DocumentStatus.submitted => (
        colour: AppColors.textSecondary,
        background: AppColors.surfaceMuted,
        label: 'Submitted',
      ),
      DocumentStatus.uploaded => (
        colour: AppColors.textSecondary,
        background: AppColors.surfaceMuted,
        label: 'Uploaded',
      ),
      DocumentStatus.missing => (
        colour: AppColors.statusPending,
        background: AppColors.statusPendingBg,
        label: 'Missing',
      ),
      DocumentStatus.expired || null => (
        colour: AppColors.textSecondary,
        background: AppColors.surfaceMuted,
        label: 'Not yet reviewed',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              document.needsApplicantAction
                  ? Icons.error_outline
                  : Icons.description_outlined,
              size: 20,
              color: document.needsApplicantAction
                  ? AppColors.statusRejected
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(document.label, style: AppTypography.body),
                  Text(document.fileName, style: AppTypography.helper),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: StatusBadge(
                label: style.label,
                color: style.colour,
                backgroundColor: style.background,
              ),
            ),
          ],
        ),
        // The evaluator's own words, in full. A status without the reason
        // tells the applicant to guess at what to change.
        if (document.remarks != null && document.remarks!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 36, top: AppSpacing.xs),
            child: Text(document.remarks!, style: AppTypography.bodyMuted),
          ),
        if (document.issuingOffice != null)
          Padding(
            padding: const EdgeInsets.only(left: 36, top: 2),
            child: Text(
              'Issued by ${document.issuingOffice}',
              style: AppTypography.helper,
            ),
          ),
        if (document.history.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 36, top: 2),
            child: Text(
              document.history.length == 1
                  ? '1 earlier submission'
                  : '${document.history.length} earlier submissions',
              style: AppTypography.helper,
            ),
          ),
      ],
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  final ApplicationModel application;

  const _PaymentSummary({required this.application});

  @override
  Widget build(BuildContext context) {
    final payment = application.payment;
    if (payment == null) {
      return Text(
        'Not yet available. Fees are assessed once your documents pass '
        'evaluation, and your Order of Payment appears here.',
        style: AppTypography.bodyMuted,
      );
    }
    final due = payment.amountDue;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            due?.formatted ?? 'Not yet assessed',
            style: AppTypography.cardTitle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: StatusBadge(
            label: payment.status.label,
            color: payment.status.color,
            backgroundColor: payment.status.backgroundColor,
          ),
        ),
      ],
    );
  }
}

class _PermitSummary extends StatelessWidget {
  final ApplicationModel application;
  final VoidCallback onOpen;

  const _PermitSummary({required this.application, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final permit = application.permit!;
    final format = DateFormat('MMM d, yyyy');

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      child: InkWell(
        onTap: onOpen,
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
                    Text(permit.permitNumber, style: AppTypography.cardTitle),
                    Text(
                      'Issued ${format.format(permit.issuedDate)}',
                      style: AppTypography.helper,
                    ),
                    Text(
                      'Work must start by '
                      '${format.format(permit.commenceByDate)}',
                      style: AppTypography.helper,
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
